from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.cdc_io import YYYY_MM_DD_DATE_FORMAT
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, covid19_row_validator, validate_quantile_csv_file, COVID_ADDL_REQ_COLS

STAGING = False

if STAGING:
    conn = ZoltarConnection(host='https://rl-zoltar-staging.herokuapp.com')
else:
    conn = ZoltarConnection()

# For each forcast migrate source field to new version uysing has from validated_files_db.json

# check if the source fields have changed as expected
