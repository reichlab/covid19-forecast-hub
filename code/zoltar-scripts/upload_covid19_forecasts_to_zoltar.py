from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import VALID_TARGET_NAMES, covid19_row_validator, validate_quantile_csv_file
import os
import sys
import yaml

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
project_timezeros = []
conn = util.authenticate()
url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'

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

    # Get model name or create a new model if it's not in the current Zoltar project
    metadata = metadata_dict_for_file(path_to_processed_model_forecasts+'metadata-'+dir_name+'.txt')
    model_name = metadata['model_name']
    if model_name not in model_names:
        model_config = {}
        model_config['name'], model_config['abbreviation'], model_config['team_name'], model_config['description'], model_config['home_url'], model_config['aux_data_url'] \
            = metadata['model_name'], metadata['model_abbr'], metadata['team_name'], metadata['methods'], url + dir_name, 'NA'
        try:
            project_obj.create_model(model_config)
            models = project_obj.models
            model_names = [model.name for model in models]
        except Exception as ex:
            return ex  
    model = [model for model in models if model.name == model_name][0]

    # Get names of existing forecasts to avoid re-upload
    existing_forecasts = [forecast.source for forecast in model.forecasts]

    # Batch upload
    json_io_dict_batch = []
    forecast_filename_batch = []
    timezero_date_batch = []

    for forecast in forecasts:

        # Skip if forecast is already on zoltar
        if forecast in existing_forecasts:
            continue

        # Skip metadata text file
        if '.txt' in forecast:
            continue

        with open(path_to_processed_model_forecasts+forecast) as fp:

            # Get timezero and create timezero on zoltar if not existed
            time_zero_date = forecast.split(dir_name)[0][:-1]
            if time_zero_date not in project_timezeros:
                try:
                    project_obj.create_timezero(time_zero_date)
                    project_timezeros.append(time_zero_date)
                except Exception as ex:
                    return ex

            # Validate covid19 file
            errors_from_validation = validate_quantile_csv_file(path_to_processed_model_forecasts+forecast)

            # Upload forecast
            if "no errors" == errors_from_validation:
                quantile_json, error_from_transformation = json_io_dict_from_quantile_csv_file(fp, VALID_TARGET_NAMES, covid19_row_validator)
                if len(error_from_transformation) >0 :
                    return error_from_transformation
                else:
                    # try:
                    #     util.upload_forecast(conn, quantile_json, forecast, 
                    #                             project_name, model_name , time_zero_date, overwrite=False)
                    # except Exception as ex:
                    #     print(ex)
                    json_io_dict_batch.append(quantile_json)
                    timezero_date_batch.append(time_zero_date)
                    forecast_filename_batch.append(forecast)
            else:
                return errors_from_validation
            fp.close()
    
    # Batch upload for better performance
    if len(json_io_dict_batch) > 0:
        try:
            util.upload_forecast_batch(conn, json_io_dict_batch, forecast_filename_batch, project_name, model_name, timezero_date_batch)
        except Exception as ex:
            return ex
    return "Pass"


# Example Run: python3 ./code/zoltar-scripts/upload_covid19_forecasts_to+zoltar.py
if __name__ == '__main__':
    list_of_model_directories = os.listdir('./data-processed/')
    output_errors = {}
    for directory in list_of_model_directories:
        if "." in directory:
            continue
        output = upload_covid_all_forecasts('./data-processed/'+directory+'/',directory)
        if output != "Pass":
            output_errors[directory] = output
    
    # List all files that did not get upload and its error
    if len(output_errors) > 0:
        for directory, errors in output_errors.items():
            print("\n* ERROR IN '", directory, "'")
            for error in errors:
                print(error)
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")
    