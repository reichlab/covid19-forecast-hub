from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID19_TARGET_NAMES, covid19_row_validator, validate_quantile_csv_file
import os
import sys
import yaml

# Function to read metadata file to get model name
def metadata_dict_for_file(metadata_file):
    with open(metadata_file, encoding="utf8") as metadata_fp:
        metadata_dict = yaml.safe_load(metadata_fp)
    return metadata_dict

# Function to upload all forecasts in a specific directory
def upload_covid_all_forecasts(path_to_processed_model_forecasts):
    # meta info
    project_name = 'COVID-19 Forecasts'
    project_obj = None
    project_timezeros = []
    forecasts = os.listdir(path_to_processed_model_forecasts)
    conn = util.authenticate()

    # Get all existing timezeros in the project 
    for project in conn.projects:
        if project.name == project_name:
            project_obj = project
            for timezero in project.timezeros:
                project_timezeros.append(timezero.timezero_date)
            break
    
    # Get model name
    separator = '-'
    dir_name = separator.join(forecasts[0].split(separator)[3:]).split('.csv')[0]
    metadata = metadata_dict_for_file(path_to_processed_model_forecasts+'metadata-'+dir_name+'.txt')
    model_name = metadata['model_name']
    model = [model for model in project_obj.models if model.name == model_name][0]

    # Get names of existing forecasts to avoid re-upload
    existing_forecasts = [forecast.source for forecast in model.forecasts]

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
                except Exception as ex:
                    print(ex)

            # Validate covid19 file
            errors_from_validation = validate_quantile_csv_file(path_to_processed_model_forecasts+forecast)

            # Upload forecast
            if "no errors" == errors_from_validation:
                quantile_json, error_from_transformation = json_io_dict_from_quantile_csv_file(fp, COVID19_TARGET_NAMES, covid19_row_validator)
                if len(error_from_transformation) >0 :
                    print(error_from_transformation)
                else:
                    try:
                        util.upload_forecast(conn, quantile_json, forecast, 
                                                project_name, model_name , time_zero_date, overwrite=False)
                    except Exception as ex:
                        print(ex)
            else:
                print(errors_from_validation)
            fp.close()

# Example Run: python3 ./code/zoltar-scripts/upload_covid19_forecasts.py ./data-processed/CU-60contact/
if __name__ == '__main__':
    path_to_processed_model_forecasts = sys.argv[1]
    upload_covid_all_forecasts(path_to_processed_model_forecasts)