from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, COVID_ADDL_REQ_COLS, covid19_row_validator, validate_quantile_csv_file
import os
import sys

# mapping
f_map = {
    '2020-05-04-MIT_CovidAnalytics-DELPHI.csv':'2020-05-04-CovidAnalytics-DELPHI.csv',
'2020-06-22-MIT_CovidAnalytics-DELPHI.csv':'2020-06-22-CovidAnalytics-DELPHI.csv',
'2020-05-25-MIT_CovidAnalytics-DELPHI.csv':'2020-05-25-CovidAnalytics-DELPHI.csv',
'2020-06-01-MIT_CovidAnalytics-DELPHI.csv':'2020-06-01-CovidAnalytics-DELPHI.csv',
'2020-07-06-MIT_CovidAnalytics-DELPHI.csv':'2020-07-06-CovidAnalytics-DELPHI.csv',
'2020-04-27-MIT_CovidAnalytics-DELPHI.csv':'2020-04-27-CovidAnalytics-DELPHI.csv',
'2020-06-29-MIT_CovidAnalytics-DELPHI.csv':'2020-06-29-CovidAnalytics-DELPHI.csv',
'2020-07-13-MIT_CovidAnalytics-DELPHI.csv':'2020-07-13-CovidAnalytics-DELPHI.csv',
'2020-06-08-MIT_CovidAnalytics-DELPHI.csv':'2020-06-08-CovidAnalytics-DELPHI.csv',
'2020-06-15-MIT_CovidAnalytics-DELPHI.csv':'2020-06-15-CovidAnalytics-DELPHI.csv',
'2020-04-30-MIT_CovidAnalytics-DELPHI.csv':'2020-04-30-CovidAnalytics-DELPHI.csv',
'2020-05-18-MIT_CovidAnalytics-DELPHI.csv':'2020-05-18-CovidAnalytics-DELPHI.csv',
'2020-05-10-MIT_CovidAnalytics-DELPHI.csv':'2020-05-10-CovidAnalytics-DELPHI.csv',
'2020-07-12-LockNQuay-ens1.csv':'2020-07-12-LNQ-ens1.csv',
'2020-05-18-UChicago-CovidIL_30_increase.csv':'2020-05-18-UChicago-CovidIL_30_+.csv',
'2020-07-12-MIT_CovAlliance-SIR.csv':'2020-07-12-MITCovAlliance-SIR.csv',
'2020-06-18-MIT_CovAlliance-SIR.csv':'2020-06-18-MITCovAlliance-SIR.csv',
'2020-07-05-MIT_CovAlliance-SIR.csv':'2020-07-05-MITCovAlliance-SIR.csv',
'2020-06-28-MIT_CovAlliance-SIR.csv':'2020-06-28-MITCovAlliance-SIR.csv',
}

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

count = 0
for model in models:
    for forecast in model.forecasts:
        if forecast.source in f_map:
            print(f"Setting source {forecast.source} to {f_map[forecast.source]}")
            forecast.source = f_map[forecast.source]
            count+=1
print(f"Renamed {count} number of forecasts' source")