from upload_zoltar import *
import sys
import os
from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, COVID_ADDL_REQ_COLS, covid19_row_validator, validate_quantile_csv_file


import glob
forecast_name = sys.argv[1].strip()
upload_forecast(forecast_name)