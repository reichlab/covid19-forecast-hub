import hashlib
import os
import pickle
from zoltpy.quantile_io import json_io_dict_from_quantile_csv_file
from zoltpy import util
from zoltpy.connection import ZoltarConnection
from zoltpy.covid19 import VALID_TARGET_NAMES, covid19_row_validator, validate_quantile_csv_file

# Create a db that holds the hash of every processed forecast
l = []
db = dict(l)

list_of_model_directories = os.listdir('./data-processed/')
for directory in list_of_model_directories:
    if "." in directory:
        continue
    # Get all forecasts in the directory of this model
    path = './data-processed/'+directory+'/'
    forecasts = os.listdir(path)
    for forecast in forecasts:
        # Skip metadata text file
        if '.txt' in forecast:
            continue
            
        # Validate covid19 file
        errors_from_validation = validate_quantile_csv_file(path+forecast)

        # Upload forecast
        if "no errors" == errors_from_validation:
            with open(path+forecast, "rb") as f:

                # Get the current hash of a processed file
                checksum = hashlib.md5(f.read()).hexdigest()

                # Check this hash against the previous version of hash
                if db.get(forecast, None) != checksum:
                    print(forecast)
                    db[forecast] = checksum
                with open('./code/zoltar-scripts/validated_file_db.p', 'wb') as fw:
                    pickle.dump(db, fw)
                f.close()
        else:
            print(errors_from_validation)