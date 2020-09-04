from zoltpy import util
from zoltpy.connection import ZoltarConnection
import zoltpy.connection
import os
import sys
import logging

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
conn.authenticate(os.environ.get("Z_USERNAME"), os.environ.get("Z_PASSWORD"))\

# Get all existing timezeros and models in the project
project_obj = [project for project in conn.projects if project.name == project_name][0]
project_timezeros = [timezero.timezero_date for timezero in project_obj.timezeros]
models = [model for model in project_obj.models]

# Get all forecasts on zoltar
zoltar_forecasts = []
for model in models:
    existing_forecasts = [forecast.source for forecast in model.forecasts]
    zoltar_forecasts.extend(existing_forecasts)

# Get all forecasts on GitHub Repo
repo_forecasts = []
for directory in [model for model in os.listdir('./data-processed/') if "." not in model]:
    forecasts = [forecast for forecast in os.listdir('./data-processed/'+directory+"/") if ".csv" in forecast and "2020" in forecast]
    repo_forecasts.extend(forecasts)

# Compare the two list of forecasts and remove forecast on zoltar that are not in GitHub repo
for forecast in zoltar_forecasts:
    if forecast not in repo_forecasts:
        try:
            logger.info(f"This forecast {forecast} will be removed since it's no longer exist in covid19 GitHub Repo")
            forecast.delete()
            logger.info(f"delete_forecast(): delete done")
        except Exception as ex:
            logger.error(ex)
            return ex
