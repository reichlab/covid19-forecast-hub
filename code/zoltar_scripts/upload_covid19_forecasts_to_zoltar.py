from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection, Model
from zoltpy.covid19 import VALID_TARGET_NAMES, covid19_row_validator, validate_quantile_csv_file
import os
import sys
import yaml
import hashlib
import pickle
import logging

logger = logging.getLogger(__name__)

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
project_timezeros = []
conn = util.authenticate()
url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'

# mapping of variables in the metadata to the parameters in Zoltar
zoltar_mapping = {
    'team_name': 'team_name',
    'model_name': 'name',
    'model_abbr': 'abbreviation',
    'model_contributors': 'contributors',
    'website_url': 'home_url',
    'team_model_designation': 'notes',
    'methods': 'description',
    'repo_url': 'aux_data_url',
    'citation': 'citation',
    'methods_long': 'methods'
}
try:
    with open('./code/zoltar_scripts/validated_file_db.p', 'rb') as f:
        l = pickle.load(f)
        f.close()
except Exception as ex:
    l = []
db = dict(l)

# Get all existing timezeros and models in the project
project_obj = [project for project in conn.projects if project.name == project_name][0]
project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
models = [model for model in project_obj.models]
model_abbrs = [model.abbreviation for model in models]


# Function to upload all forecasts in a specific directory
def upload_covid_all_forecasts(path_to_processed_model_forecasts, dir_name):
    global models
    global model_abbrs

    # Get all forecasts in the directory of this model
    forecasts = os.listdir(path_to_processed_model_forecasts)

    # Get model name or create a new model if it's not in the current Zoltar project
    metadata = metadata_dict_for_file(
        path_to_processed_model_forecasts + 'metadata-' + dir_name + '.txt')
    model_abbreviation = metadata['model_abbr']

    # get the corresponding model_config for the metadata file
    model_config = zoltar_config_from_metadata(metadata)
    if model_abbreviation not in model_abbrs:
        print('%s not in models' % model_abbreviation)
        if 'website_url' not in model_config:
            model_config['website_url'] = url + dir_name

        models.append(project_obj.create_model(model_config))
        model_abbrs = [model.abbreviation for model in models]

    # fetch model based on model_abbr
    model = [model for model in models if model.abbreviation == model_abbreviation][0]

    if has_changed(metadata, model):
        # model metadata has changed, call teh edit function in zoltpy to update metadata
        logger.info('%s model has changed metadata contents. Updating on Zoltar...' % (
            metadata['model_name']))
        model.edit(model_config)

    # Get names of existing forecasts to avoid re-upload
    existing_time_zeros = [forecast.timezero.timezero_date for forecast in model.forecasts]

    # Batch upload
    json_io_dict_batch = []
    forecast_filename_batch = []
    timezero_date_batch = []

    # iterate over forecasts
    val_errors = upload_forecasts(dir_name, existing_time_zeros, forecast_filename_batch, forecasts,
                     json_io_dict_batch, metadata, path_to_processed_model_forecasts,
                     timezero_date_batch)

    # if there was an error while uploading forecast, return list of errors, else "Pass"
    return val_errors or "Pass"

    # # Batch upload for better performance
    # if len(json_io_dict_batch) > 0:
    #     try:
    #         util.upload_forecast_batch(conn, json_io_dict_batch, forecast_filename_batch, project_name, model_name, timezero_date_batch, overwrite = over_write)
    #     except Exception as ex:
    #         return ex


def upload_forecasts(dir_name, existing_time_zeros, forecast_filename_batch, forecasts,
                     json_io_dict_batch, metadata, path_to_processed_model_forecasts,
                     timezero_date_batch):
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
                project_obj.create_timezero(time_zero_date)
                project_timezeros.append(time_zero_date)

            # Validate covid19 file
            errors_from_validation = validate_quantile_csv_file(
                path_to_processed_model_forecasts + forecast)

            # Upload forecast
            if "no errors" == errors_from_validation:
                quantile_json, error_from_transformation = json_io_dict_from_quantile_csv_file(fp,
                                                                                               VALID_TARGET_NAMES,
                                                                                               covid19_row_validator)
                if len(error_from_transformation) > 0:
                    return error_from_transformation
                else:
                    util.upload_forecast(conn, quantile_json, forecast,
                                         project_name, metadata['model_name'], time_zero_date,
                                         overwrite=over_write)
                    db[forecast] = checksum
                    json_io_dict_batch.append(quantile_json)
                    timezero_date_batch.append(time_zero_date)
                    forecast_filename_batch.append(forecast)
            else:
                return errors_from_validation


# Function to read metadata file to get model name
def metadata_dict_for_file(metadata_file):
    with open(metadata_file, encoding="utf8") as metadata_fp:
        metadata_dict = yaml.safe_load(metadata_fp)
    return metadata_dict


def zoltar_config_from_metadata(metadata):
    conf = {}
    for key, mapping in zoltar_mapping.items():
        # if key present in metadata, assign the value of the 
        # key in metadata to a mapping key-value in model_config
        if key in metadata:
            conf[mapping] = metadata[key]
    return conf


def has_changed(metadata, model):
    """
        Check if any contents of the metadata has changed from the contents in Zoltar.
    """
    try:
        conditions = [
            model.team_name != metadata['team_name'],
            model.name != metadata['model_name'],
            model.abbreviation != metadata['model_abbr'],
            model.contributors != metadata.get('model_contributors'),
            model.home_url != metadata.get('website_url'),
            model.license != metadata['license'],
            model.notes != metadata['team_model_designation'],
            model.description != metadata['methods'],
            model.aux_data_url != metadata.get('aux_data_url'),
            model.citation != metadata.get('citation')
        ]
        return any(conditions)
    except KeyError:
        # if any key does not exist, return true to update the zoltar with latest data
        return True


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

    with open('./code/zoltar_scripts/validated_file_db.p', 'wb') as fw:
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
