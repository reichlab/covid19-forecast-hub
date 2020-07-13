from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, COVID_ADDL_REQ_COLS, covid19_row_validator, validate_quantile_csv_file
import os
import sys

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
project_timezeros = []
conn = util.authenticate()
url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'

project_obj = [project for project in conn.projects if project.name == project_name][0]
project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
models = [model for model in project_obj.models]
model_names = [model.name for model in models]
zoltar_forecasts = []
repo_forecasts = []
for model in models:
    existing_forecasts = [forecast.source for forecast in model.forecasts]
    zoltar_forecasts.extend(existing_forecasts)
for directory in [model for model in os.listdir('./data-processed/') if "." not in model]:
    forecasts = [forecast for forecast in os.listdir('./data-processed/'+directory+"/") if ".csv" in forecast and "2020" in forecast]
    repo_forecasts.extend(forecasts)
print("number of forecasts in zoltar: " + str(len(zoltar_forecasts)))
print("number of forecasts in repo: " + str(len(repo_forecasts)))
for forecast in zoltar_forecasts:
    if forecast not in repo_forecasts:
        print("This forecast in zoltar but not in repo "+forecast)
print()
print('----------------------------------------------------------')
print()
for forecast in repo_forecasts:
    if forecast not in zoltar_forecasts:
        print("This forecast in repo but not in zoltar "+forecast)