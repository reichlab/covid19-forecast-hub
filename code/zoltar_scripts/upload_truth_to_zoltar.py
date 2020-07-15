from zoltpy import util
from zoltpy.connection import ZoltarConnection
import os
import sys

# PATH TO ZOLTAR TRUTH FILE. CHANGE THIS IF NEEDED
path_to_zoltar_truth = './data-truth/zoltar-truth.csv'

# meta info
project_name = 'COVID-19 Forecasts'
project_obj = None
conn = util.authenticate()
url = 'https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/'


# Get the project
project_obj = [project for project in conn.projects if project.name == project_name][0]


# Example Run: python3 ./code/zoltar_scripts/upload_truth_to_zoltar.py
if __name__ == '__main__':
    with open(path_to_zoltar_truth) as fr:
        upload_file_job = project_obj.upload_truth_data(fr)
    util.busy_poll_job(upload_file_job)
    print(f"- upload truth done")
    