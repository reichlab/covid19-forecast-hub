import pandas as pd
from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.cdc_io import YYYY_MM_DD_DATE_FORMAT
from zoltpy.connection import ZoltarConnection
import os

project_name = 'COVID-19 Forecasts'
conn = ZoltarConnection()
conn.authenticate(os.environ.get("Z_USERNAME"), os.environ.get("Z_PASSWORD"))
project_obj = [project for project in conn.projects if project.name == project_name][0]
models = [model for model in project_obj.models]
forecasts = []
for model in models:
    forecasts.extend(list(model.forecasts))

forecast_sources = [forecast.source for forecast in forecasts]

deleted_forecasts = pd.read_csv("deleted_forecasts.csv")

for forecast in deleted_forecasts['file_name']:
    if forecast in forecast_sources:
        print(forecast)