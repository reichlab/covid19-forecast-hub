from zoltpy.quantile import validate_quantile_csv_file
import glob

# loop through model directories
my_path = "./data-processed"
ignore_files = ['./data-processed/Imperial-ensemble2/Imperial-forecast-dates.csv',
                './data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv',
                './data-processed/Imperial-ensemble1/Imperial-forecast-dates.csv']
for filepath in glob.iglob(my_path + "**/**/*.csv", recursive=False):
    if filepath not in ignore_files:
        validate_quantile_csv_file(filepath)
        print('\n')
