from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.cdc_io import YYYY_MM_DD_DATE_FORMAT
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, covid19_row_validator, validate_quantile_csv_file, COVID_ADDL_REQ_COLS
import json
import os
import sys
import logging
import itertools
from pprint import pprint

STAGING = True
logging.basicConfig(level=logging.DEBUG)

if STAGING:
    conn = ZoltarConnection(host='https://rl-zoltar-staging.herokuapp.com')
else:
    conn = ZoltarConnection()
conn.authenticate(os.environ.get("Z_USERNAME"), os.environ.get("Z_PASSWORD"))

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None

# Get all existing models and forecasts in the project
project_obj = [project for project in conn.projects if project.name == project_name][0]
models = [model for model in project_obj.models]
forecasts = list(itertools.chain.from_iterable([model.forecasts for model in models]))
forecast_dict = {forecast.id : forecast for forecast in forecasts}

# get all uploaded to zoltar files
uploaded_to_zoltar_list = project_obj.latest_forecasts
forecast_csv_to_id_dict = {id_source[1] : id_source[0] for id_source in uploaded_to_zoltar_list[1:]}

# For each forcast migrate source field to new version using has from validated_files_db.json
db = {}
with open("validated_file_db.json", "r") as db_file:
    db = json.load(db_file)

csv_not_in_zoltar = []
id_invalid = []
for filename in db:
    hash = db[filename]
    try:
        forecast_id = int(forecast_csv_to_id_dict[filename])
    except KeyError:
        csv_not_in_zoltar.append(filename)
        continue

    try:
        forecast = forecast_dict[forecast_id]

        # set source to new format
        forecast.source = f"{filename}|{hash}"
    except KeyError:
        id_invalid.append(forecast_id)

# check if the source fields have changed as expected
# make sure all files have source hashes
uploaded_to_zoltar_list = project_obj.latest_forecasts
sources_nohash = [pair[1] for pair in uploaded_to_zoltar_list[1:] if not "|" in pair[1]]
pprint(sources_nohash)
