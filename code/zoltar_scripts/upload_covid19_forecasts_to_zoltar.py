from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, covid19_row_validator, validate_quantile_csv_file, COVID_ADDL_REQ_COLS
import os
import sys
import yaml
import hashlib
import pickle
import logging
import json

import pprint

logger = logging.getLogger(__name__)

#TODO: Make these as environment variables
STAGING = False

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
project_timezeros = []

# Is staging is set to True, use the staging server
if STAGING:
    conn = ZoltarConnection(host='https://rl-zoltar-staging.herokuapp.com')
else:
    conn = ZoltarConnection()
conn.authenticate(os.environ.get("Z_USERNAME"), os.environ.get("Z_PASSWORD"))


url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'

# mapping of variables in the metadata to the parameters in Zoltar
metadata_field_to_zoltar = {
    'team_name': 'team_name',
    'model_name': 'name',
    'model_abbr': 'abbreviation',
    'model_contributors': 'contributors',
    'website_url': 'home_url',
    'license': 'license',
    'team_model_designation': 'notes',
    'methods': 'description',
    'repo_url': 'aux_data_url',
    'citation': 'citation',
    'methods_long': 'methods'
}

MISSING_METADATA_VALUE = "Missing"
db = {}
with open('./code/zoltar_scripts/validated_file_db.json', 'r') as f:
    db = json.load(f)

# Get all existing timezeros and models in the project
project_obj = [project for project in conn.projects if project.name == project_name][0]
project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
models = [model for model in project_obj.models]
model_abbrs = [model.abbreviation for model in models]


# Function to read metadata file to get model name
def metadata_dict_for_file(metadata_file):
    with open(metadata_file, encoding="utf8") as metadata_fp:
        metadata_dict = yaml.safe_load(metadata_fp)
    return metadata_dict


'''
    Get Zoltar model_config object from the metadata file using the zoltar_mapping dict.
'''
def zoltar_config_from_metadata(metadata):
    # default conf values
    conf = {}
    for metadata_field, zoltar_field in metadata_field_to_zoltar.items():
        # if key present in metadata, assign the value of the 
        # key in metadata to a mapping key-value in model_config
        conf[zoltar_field] = metadata[metadata_field] if metadata_field in metadata else MISSING_METADATA_VALUE
    return conf


def has_changed(metadata, model):
    for metadata_field, zoltar_field in metadata_field_to_zoltar.items():
        if metadata.get(metadata_field, MISSING_METADATA_VALUE) != getattr(model, zoltar_field):
            logging.debug(f"{metadata_field} has changed in {metadata['model_abbr']}")
            return True
    return False


# Function to upload all forecasts in a specific directory
def upload_covid_all_forecasts(path_to_processed_model_forecasts, dir_name):
    global models
    global model_abbrs

    # Get all forecasts in the directory of this model
    forecasts = os.listdir(path_to_processed_model_forecasts)

    # Get model name or create a new model if it's not in the current Zoltar project
    try:
        metadata = metadata_dict_for_file(
            path_to_processed_model_forecasts + 'metadata-' + dir_name + '.txt')
    except Exception as ex:
        return ex
    model_abbreviation = metadata['model_abbr']

    # get the corresponding model_config for the metadata file
    model_config = zoltar_config_from_metadata(metadata)

    if model_abbreviation not in model_abbrs:
        pprint.pprint('%s not in models' % model_abbreviation)
        if 'home_url' not in model_config:
            model_config['home_url'] = url + dir_name
        
        try:
            logger.info(f"Creating model {model_config}")
            models.append(project_obj.create_model(model_config))
            model_abbrs = [model.abbreviation for model in models]
        except Exception as ex:
            return ex

    # fetch model based on model_abbr
    model = [model for model in models if model.abbreviation == model_abbreviation][0]

    if has_changed(metadata, model):
        # model metadata has changed, call the edit function in zoltpy to update metadata
        print(f"{metadata['model_abbr']!r} model has changed metadata contents. Updating on Zoltar...")
        model.edit(model_config)
    
    # Get names of existing forecasts to avoid re-upload
    existing_time_zeros = [forecast.timezero.timezero_date for forecast in model.forecasts]

    # Batch upload
    json_io_dict_batch = []
    forecast_filename_batch = []
    timezero_date_batch = []

    for forecast in forecasts:

        # Skip metadata text file
        if not forecast.endswith('.csv'):
            continue

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
                print(forecast, db.get(forecast, None))
                if time_zero_date in existing_time_zeros:
                    over_write = True
            else:
                continue



        with open(path_to_processed_model_forecasts + forecast) as fp:
            # Create timezero on zoltar if not existed
            if time_zero_date not in project_timezeros:
                try:
                    project_obj.create_timezero(time_zero_date)
                    project_timezeros.append(time_zero_date)
                except Exception as ex:
                    print(ex)
                    return ex

            # Validate covid19 file
            print(f"Validating {forecast}")
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
                        logger.debug('Upload forecast for model: %s \t|\t File: %s\n' % (metadata['model_abbr'],forecast))
                        util.upload_forecast(conn, quantile_json, forecast,
                                             project_name, metadata['model_abbr'], time_zero_date,
                                             overwrite=over_write)
                        db[forecast] = checksum
                    except Exception as ex:
                        logger.error(ex)
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


# Example Run: python3 ./code/zoltar_scripts/upload_covid19_forecasts_to_zoltar.py
if __name__ == '__main__':
    list_of_model_directories = os.listdir('./data-processed/')
    output_errors = {}
    for directory in list_of_model_directories:
        if "." in directory:
            continue
        output = upload_covid_all_forecasts('./data-processed/' + directory + '/', directory)
        if output != "Pass":
            output_errors[directory] = output

    with open('./code/zoltar_scripts/validated_file_db.json', 'w') as fw:
        json.dump(db, fw, indent=4)

    # List all files that did not get upload and its error
    if len(output_errors) > 0:
        for directory, errors in output_errors.items():
            print("\n* ERROR IN '", directory, "'")
            print(errors)
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")
