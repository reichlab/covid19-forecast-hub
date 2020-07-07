import hashlib
import os
import pickle
import sys

import yaml
from zoltpy import util
from zoltpy.covid19 import COVID_TARGETS, COVID_ADDL_REQ_COLS, covid19_row_validator, \
    validate_quantile_csv_file
from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from datetime import datetime

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
project_timezeros = []
conn = util.authenticate()
url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'
try:
    with open('./code/zoltar-scripts/validated_file_db.p', 'rb') as f:
        l = pickle.load(f)
        f.close()
except Exception as ex:
    l = []
db = dict(l)

# Get all existing timezeros and models in the project
project_obj = [project for project in conn.projects if project.name == project_name][0]
project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
models = [model for model in project_obj.models]
model_names = [model.name for model in models]


# Function to read metadata file to get model name
def metadata_dict_for_file(metadata_file):
    with open(metadata_file, encoding="utf8") as metadata_fp:
        metadata_dict = yaml.safe_load(metadata_fp)
    return metadata_dict


# Function to upload all forecasts in a specific directory
def upload_covid_all_forecasts(path_to_processed_model_forecasts, dir_name):
    global models
    global model_names

    # Get all forecasts in the directory of this model
    forecasts = os.listdir(path_to_processed_model_forecasts)
    conn.re_authenticate_if_necessary()
    # Get model name or create a new model if it's not in the current Zoltar project
    try:
        metadata = metadata_dict_for_file(
            path_to_processed_model_forecasts + 'metadata-' + dir_name + '.txt')
    except Exception as ex:
        return ex
    model_name = metadata['model_name']
    if model_name not in model_names:
        model_config = {}
        model_config['name'], model_config['abbreviation'], model_config['team_name'], \
        model_config['description'], model_config['home_url'], model_config['aux_data_url'] \
            = metadata['model_name'], metadata['team_abbr'] + '-' + metadata['model_abbr'], \
              metadata['team_name'], metadata['methods'], metadata['website_url'] if metadata.get(
            'website_url') != None else url + dir_name, 'NA'
        try:
            print('Create model %s' % model_name)
            project_obj.create_model(model_config)
            models = project_obj.models
            model_names = [model.name for model in models]
        except Exception as ex:
            return ex
    print('Time: %s \t Model: %s' % (datetime.now(), model_name))
    model = [model for model in models if model.name == model_name][0]

    # Get names of existing forecasts to avoid re-upload
    existing_time_zeros = [forecast.timezero.timezero_date for forecast in model.forecasts]

    # Batch upload
    json_io_dict_batch = []
    forecast_filename_batch = []
    timezero_date_batch = []

    for forecast in forecasts:

        # Default config
        over_write = False
        checksum = 0
        time_zero_date = forecast.split(dir_name)[0][:-1]

        # Check if forecast is already on zoltar
        with open(path_to_processed_model_forecasts + forecast, "rb") as f:
            # Get the current hash of a processed file
            checksum = hashlib.md5(f.read()).hexdigest()
            f.close()

            # Check this hash against the previous version of hash
            if db.get(forecast, None) != checksum:
                print(forecast)
                if time_zero_date in existing_time_zeros:
                    over_write = True
            else:
                continue

        # Skip metadata text file
        if '.txt' in forecast:
            continue

        with open(path_to_processed_model_forecasts + forecast) as fp:
            # Create timezero on zoltar if not existed
            if time_zero_date not in project_timezeros:
                try:
                    project_obj.create_timezero(time_zero_date)
                    project_timezeros.append(time_zero_date)
                except Exception as ex:
                    return ex

            # Validate covid19 file
            errors_from_validation = validate_quantile_csv_file(
                path_to_processed_model_forecasts + forecast)

            # Upload forecast
            if "no errors" == errors_from_validation:
                quantile_json, error_from_transformation = json_io_dict_from_quantile_csv_file(fp,
                                                                                               COVID_TARGETS,
                                                                                               covid19_row_validator,
                                                                                               COVID_ADDL_REQ_COLS)
                if len(error_from_transformation) > 0:
                    return error_from_transformation
                else:
                    try:
                        print('Upload forecast for model: %s \t|\t File: %s' % (model_name,forecast))
                        print()
                        util.upload_forecast(conn, quantile_json, forecast, 
                                                project_name, model_name , time_zero_date, overwrite=over_write)
                        db[forecast] = checksum
                    except Exception as ex:
                        print(ex)
                        return ex
                    json_io_dict_batch.append(quantile_json)
                    timezero_date_batch.append(time_zero_date)
                    forecast_filename_batch.append(forecast)
            else:
                return errors_from_validation
            fp.close()

    # # Batch upload for better performance
    # if len(json_io_dict_batch) > 0:
    #     try:
    #         util.upload_forecast_batch(conn, json_io_dict_batch, forecast_filename_batch, project_name, model_name, timezero_date_batch, overwrite = over_write)
    #     except Exception as ex:
    #         return ex
    return "Pass"


# Example Run: python3 ./code/zoltar-scripts/upload_covid19_forecasts_to_zoltar.py
if __name__ == '__main__':
    list_of_model_directories = os.listdir('./data-processed/')
    output_errors = {}
    for directory in list_of_model_directories:
        if "." in directory:
            continue
        output = upload_covid_all_forecasts('./data-processed/' + directory + '/', directory)
        if output != "Pass":
            output_errors[directory] = output

    with open('./code/zoltar-scripts/validated_file_db.p', 'wb') as fw:
        pickle.dump(db, fw)
        fw.close()

    # List all files that did not get upload and its error
    if len(output_errors) > 0:
        for directory, errors in output_errors.items():
            print("\n* ERROR IN '", directory, "'")
            print(errors)
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")
