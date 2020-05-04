from zoltpy.covid19 import validate_quantile_csv_file
import glob
from pprint import pprint
import sys
import os
import pandas as pd
import datetime


# Check for metadata file
def check_for_metadata(my_path):
    for path in glob.iglob(my_path + "**/**/", recursive=False):
        team_model = os.path.basename(os.path.dirname(path))
        metadata_filename = "metadata-" + team_model + ".txt"
        txt_files = []
        for metadata_file in glob.iglob(path + "*.txt", recursive=False):
            txt_files += [os.path.basename(metadata_file)]
        if metadata_filename not in txt_files:
            print("MISSING ", metadata_filename)


# Check forecast formatting
def check_formatting(my_path):
    output_errors = {}
    df = pd.read_csv('code/validation/validated_files.csv')
    previous_checked = list(df['file_path'])
    # Iterate through processed csvs
    for path in glob.iglob(my_path + "**/**/", recursive=False):
        for filepath in glob.iglob(path + "*.csv", recursive=False):
            if filepath not in previous_checked:
                file_error = validate_quantile_csv_file(filepath)
                if file_error != 'no errors':
                    output_errors[filepath] = file_error
                else:
                    # add to previously checked files
                    current_time = datetime.datetime.now()
                    df = df.append({'file_path': filepath,
                                    'validation_date': current_time}, ignore_index=True)
    # update previously checked files
    df.to_csv('code/validation/validated_files.csv', index=False)

    # Output list of Errors
    if len(output_errors) > 0:
        for filename, errors in output_errors.items():
            print("\n* ERROR IN '", filename, "'")
            for error in errors:
                print(error)
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")


def main():
    my_path = "./data-processed"
    check_for_metadata(my_path)
    check_formatting(my_path)


if __name__ == "__main__":
    main()
