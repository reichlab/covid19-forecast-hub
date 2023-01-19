import hashlib
import json
import logging
import os
import pprint
import sys
from datetime import date

import yaml
from dateutil.parser import parse
from zoltpy import util
from zoltpy.cdc_io import YYYY_MM_DD_DATE_FORMAT
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, covid19_row_validator, COVID_ADDL_REQ_COLS


logger = logging.getLogger(__name__)

#
# variables. TODO: Make these environment variables
#

DATA_PROCESSED_DIR = './data-processed/'
GITHUB_DATA_PROCESSED_URL = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'
PROJECT_NAME = 'COVID-19 Forecasts'
VALIDATED_FILE_DB = './code/zoltar_scripts/validated_file_db.json'

#
# metadata functions
#

METADATA_FIELD_TO_ZOLTAR = {  # mapping of variables in the metadata to the parameters in Zoltar
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


def metadata_dict_for_file(metadata_file):
    """
    Function to read metadata file to get model name
    """
    with open(metadata_file, encoding="utf8") as metadata_fp:
        metadata_dict = yaml.safe_load(metadata_fp)
    return metadata_dict


def zoltar_config_from_metadata(metadata):
    """
    Get Zoltar model_config object from the metadata file using the zoltar_mapping dict.
    """
    # default conf values
    conf = {}
    for metadata_field, zoltar_field in METADATA_FIELD_TO_ZOLTAR.items():
        # if key present in metadata, assign the value of the
        # key in metadata to a mapping key-value in model_config
        conf[zoltar_field] = metadata[metadata_field] if metadata_field in metadata else MISSING_METADATA_VALUE
    return conf


def has_changed(metadata, model):
    for metadata_field, zoltar_field in METADATA_FIELD_TO_ZOLTAR.items():
        if metadata.get(metadata_field, MISSING_METADATA_VALUE) != getattr(model, zoltar_field):
            logging.debug(f"{metadata_field} has changed in {metadata['model_abbr']}")
            return True
    return False


#
# upload_covid_all_forecasts() and friends
#

def upload_covid_forecast_by_model(conn, json_io_dict, forecast_filename, project_name, model, model_abbr,
                                   timezero_date, notes='', overwrite=False):
    """
    Upload a covid forecast with a reference to the model itself. This is based off zoltpy's util.upload_forecast()
    but remove any codes that require polling of model information from zoltar.

    :return: the zoltpy Job if the upload was successful, or None otherwise
    """
    job = None  # return value. set below if upload successful
    conn.re_authenticate_if_necessary()
    if overwrite:
        print(f"Existing forecast({forecast_filename}) present. Deleting it on Zoltar to upload latest one")
        del_job = util.delete_forecast(conn, project_name, model_abbr, timezero_date)
        util.busy_poll_job(del_job)

    # check json formatting before upload
    if isinstance(json_io_dict, str):  # accepts either string or dictionary
        try:
            with open(json_io_dict) as jsonfile:
                json_io_dict = json.load(jsonfile)
        except:
            print("""\nERROR - cannot read JSON Format. 
            Uploading a CSV? Consider converting to quantile csv style with:
            quantile_json, error_from_transformation = quantile_io.json_io_dict_from_quantile_csv_file(...)""")
            sys.exit(1)

    for _ in range(2):  # try uploading twice
        try:
            job = model.upload_forecast(json_io_dict, forecast_filename, timezero_date, notes=notes)
            util.busy_poll_job(job)
            break
        except RuntimeError as err:
            print(f"RuntimeError occurred while uploading forecast. Error: {err}")
            if err.args is not None and len(err.args) > 1 and err.args[1].status_code == 400 and not overwrite:
                # status code is 400 and we need to rewrite this model.
                response = err.args[1]
                if str(json.loads(response.text)["error"]).startswith("A forecast already exists"):
                    # now we are sure it is the existing forecast error, delete the one on zoltar and then try again.
                    print(f"This forecast({model_abbr}) with timezero ({timezero_date}) is already present, deleting "
                          f"forecast on Zoltar and then retrying...")
                    del_job = util.delete_forecast(conn, project_name, model_abbr, timezero_date)
                    util.busy_poll_job(del_job)
                    print("Deleted on Zoltar. Retrying now.")

    return job


def upload_covid_all_forecasts(path_to_processed_model_forecasts, dir_name, project_obj, project_timezeros, conn,
                               models, db):
    """
    Function to upload all forecasts in a specific directory. Returns list of errors, or [] if none.
    """
    # imported here so that tests can patch via mock:
    from zoltpy.covid19 import validate_quantile_csv_file
    from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file


    # Get all forecasts in the directory of this model
    forecasts = os.listdir(path_to_processed_model_forecasts)

    # Get model name or create a new model if it's not in the current Zoltar project
    metadata = metadata_dict_for_file(path_to_processed_model_forecasts + 'metadata-' + dir_name + '.txt')  # raises

    # get the corresponding model_config for the metadata file
    model_abbreviation = metadata['model_abbr']
    model_config = zoltar_config_from_metadata(metadata)
    if model_abbreviation not in [model.abbreviation for model in models]:
        pprint.pprint('%s not in models' % model_abbreviation)
        if 'home_url' not in model_config:
            model_config['home_url'] = GITHUB_DATA_PROCESSED_URL + dir_name

        try:
            logger.info(f"Creating model {model_config}")
            new_model = project_obj.create_model(model_config)
            models.append(new_model)
        except Exception as ex:
            return ex

    # fetch model based on model_abbr
    model = [model for model in models if model.abbreviation == model_abbreviation][0]
    if has_changed(metadata, model):
        # model metadata has changed, call the edit function in zoltpy to update metadata
        print(f"{metadata['model_abbr']!r} model has changed metadata contents. Updating on Zoltar...")
        model.edit(model_config)

    # Get names of existing forecasts to avoid re-upload and then convert them from Date type to str type
    existing_time_zeros = [forecast.timezero.timezero_date for forecast in model.forecasts]
    existing_time_zeros = [existing_time_zero.strftime(YYYY_MM_DD_DATE_FORMAT) for existing_time_zero in
                           existing_time_zeros]

    # these lists support future batch upload:
    json_io_dict_batch = []
    forecast_filename_batch = []
    timezero_date_batch = []

    for forecast in forecasts:
        if not forecast.endswith('.csv'):
            continue  # Skip metadata text file

        # Default config
        over_write = False
        time_zero_date = forecast.split(dir_name)[0][:-1]

        # Check if forecast is already on zoltar
        with open(path_to_processed_model_forecasts + forecast, "rb") as f:
            checksum = hashlib.md5(f.read()).hexdigest()  # current hash of a processed file

            # Check this hash against the previous version of hash
            if db.get(forecast, None) != checksum:
                print(forecast, db.get(forecast, None))
                if time_zero_date in existing_time_zeros:
                    # Check if the already existing forecast has the same issue date
                    local_issue_date = date.today().strftime("%Y-%m-%d")
                    uploaded_forecast = [forecast for forecast in model.forecasts if
                                         forecast.timezero.timezero_date.strftime(
                                             YYYY_MM_DD_DATE_FORMAT) == time_zero_date][0]
                    uploaded_issue_date = parse(uploaded_forecast.issued_at).date()
                    if local_issue_date == uploaded_issue_date:
                        # Overwrite the existing forecast if has the same issue date
                        over_write = True
                        logger.info(f"Overwrite existing forecast={forecast} with newer version because the new "
                                    f"issue_date={local_issue_date} is the same as the uploaded file "
                                    f"issue_date={uploaded_issue_date}")
                    else:
                        logger.info(f"Add newer version to forecast={forecast} because the new "
                                    f"issue_date={local_issue_date} is different from uploaded file "
                                    f"issue_date={uploaded_issue_date}")
            else:
                continue

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
        errors_from_validation = validate_quantile_csv_file(path_to_processed_model_forecasts + forecast)

        # Upload forecast
        if "no errors" == errors_from_validation:
            with open(path_to_processed_model_forecasts + forecast) as fp:
                quantile_json, error_from_transformation = \
                    json_io_dict_from_quantile_csv_file(fp, COVID_TARGETS, covid19_row_validator, COVID_ADDL_REQ_COLS)
                if len(error_from_transformation) > 0:
                    return error_from_transformation

                try:
                    logger.debug('Upload forecast for model: %s \t|\t File: %s\n' % (metadata['model_abbr'], forecast))
                    job = upload_covid_forecast_by_model(conn, quantile_json, forecast, PROJECT_NAME, model,
                                                         metadata['model_abbr'], time_zero_date, overwrite=over_write)
                    if job and job.status_as_str == 'SUCCESS':
                        db[forecast] = checksum
                    else:
                        return f"upload job failed. job={job}"
                except Exception as ex:
                    logger.error(ex)
                    return ex
                json_io_dict_batch.append(quantile_json)
                timezero_date_batch.append(time_zero_date)
                forecast_filename_batch.append(forecast)
        else:
            return errors_from_validation

    # # todo Batch upload for better performance
    # if len(json_io_dict_batch) > 0:
    #     try:
    #         util.upload_forecast_batch(conn, json_io_dict_batch, forecast_filename_batch, project_name, model_name, timezero_date_batch, overwrite = over_write)
    #     except Exception as ex:
    #         return ex

    return []


#
# main()
#

def main():
    with open(VALIDATED_FILE_DB, 'r') as f:
        db = json.load(f)

    # optionally use a non-production Zoltar server
    zoltar_host = os.environ.get('Z_HOST')
    if zoltar_host:
        conn = ZoltarConnection(host=zoltar_host)
    else:
        conn = ZoltarConnection()
    conn.authenticate(os.environ.get("Z_USERNAME"), os.environ.get("Z_PASSWORD"))

    # Get all existing timezeros and models in the project
    project_obj = [project for project in conn.projects if project.name == PROJECT_NAME][0]
    project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
    models = [model for model in project_obj.models]

    # Convert all timezeros from Date type to str type
    project_timezeros = [project_timezero.strftime(YYYY_MM_DD_DATE_FORMAT) for project_timezero in project_timezeros]
    list_of_model_directories = os.listdir(DATA_PROCESSED_DIR)
    output_errors = {}
    for model_dir in list_of_model_directories:
        if "." in model_dir:
            continue

        output = upload_covid_all_forecasts(DATA_PROCESSED_DIR + model_dir + '/', model_dir, project_obj,
                                            project_timezeros, conn, models, db)
        if output:
            output_errors[model_dir] = output

    with open(VALIDATED_FILE_DB, 'w') as fw:
        json.dump(db, fw, indent=4)

    # List all files that did not get upload and its error
    if len(output_errors) > 0:
        for model_dir, errors in output_errors.items():
            print("\n* ERROR IN '", model_dir, "'")
            print(errors)
        os.sync()  # make sure we flush before exiting
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")


if __name__ == '__main__':
    main()
