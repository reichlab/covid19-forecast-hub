import hashlib
import os
import pickle

# Create a db that holds the hash of every processed forecast
try:
    with open('./code/zoltar-scripts/validated_file_db.p', 'rb') as f:
        l = pickle.load(f)
        f.close()
except Exception as ex:
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