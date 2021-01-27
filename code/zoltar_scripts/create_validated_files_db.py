import hashlib
import os
import pickle
from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import COVID_TARGETS, covid19_row_validator, validate_quantile_csv_file
import glob
import json
import sys

UPDATE = False
if len(sys.argv) >1:
    if sys.argv[1].lower() == 'update':
        print('Only updating')
        UPDATE = True

# util function to get filename from the path
def get_filename_from_path(path):
    print(path, path.split(os.path.sep)[-1])
    return path.split(os.path.sep)[-1]

g_db = None

def get_db():
    global g_db
    if g_db is None:
        g_db = json.load(open('code/zoltar_scripts/validated_file_db.json'))
    return g_db

def dump_db():
    global g_db
    with open('code/zoltar_scripts/validated_file_db.json', 'w') as fw:
        json.dump(g_db, fw, indent=4)

list_of_model_directories = os.listdir('./data-processed/')
for directory in list_of_model_directories:
    if "." in directory:
        continue
    # Get all forecasts in the directory of this model
    path = './data-processed/'+directory+'/'
    forecasts = glob.glob(path + "*.csv")
    for forecast in forecasts:

        with open(forecast, "rb") as f:
            # Get the current hash of a processed file
            checksum = hashlib.md5(f.read()).hexdigest()

        db = get_db()
        # Validate covid19 file
        if UPDATE and db.get(get_filename_from_path(forecast), None) == checksum:
                continue
        errors_from_validation = validate_quantile_csv_file(forecast)

        # Upload forecast
        if "no errors" == errors_from_validation:
            # Check this hash against the previous version of hash
            if db.get(get_filename_from_path(forecast), None) != checksum:
                db[get_filename_from_path(forecast)] = checksum
        else:
            print(errors_from_validation)
print('Dumping db')
dump_db()