from zoltpy.quantile import validate_quantile_csv_file
import glob
from pprint import pprint

# loop through model directories
my_path = "./data-processed"
ignore_files = ['./data-processed/Imperial-ensemble2/Imperial-forecast-dates.csv',
                './data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv',
                './data-processed/Imperial-ensemble1/Imperial-forecast-dates.csv']
output_errors = {}

# Iterate through processed csvs
for filepath in glob.iglob(my_path + "**/**/*.csv", recursive=False):
    if filepath not in ignore_files:
        file_error = validate_quantile_csv_file(filepath)
        if file_error != 'no errors':
            output_errors[filepath] = file_error
print(len(output_errors))

# Output list of Errors
if len(output_errors) > 0:
    for filename, errors in output_errors.items():
        print("\n* ERROR IN '", filename, "'")
        for error in errors:
            print(error)
else:
    print("✓ no errors")
