from zoltpy.covid19 import validate_quantile_csv_file
import glob
from pprint import pprint
import sys
import os
import pandas as pd
import numpy as np
from datetime import datetime


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


def filename_match_forecast_date(filename):
    df = pd.read_csv(filename)
    file_forecast_date = os.path.basename(os.path.basename(filename))[:10]
    forecast_date_column = set(list(df['forecast_date']))
    if len(forecast_date_column) > 1:
        return "ERROR: %s has multiple forecast dates: %s. Forecast date must be unique" % (
            filename, forecast_date_column)
    else:
        forecast_date_column = forecast_date_column.pop()
        if (file_forecast_date != forecast_date_column):
            return "ERROR %s forecast filename date %s does match forecast_date column %s" % (
                filename, file_forecast_date, forecast_date_column)
        else:
            return None


# Check forecast formatting


def check_formatting(my_path):
    output_errors = {}
    df = pd.read_csv('code/validation/validated_files.csv')
    previous_checked = list(df['file_path'])
    files_in_repository = []
    # Iterate through processed csvs
    for path in glob.iglob(my_path + "**/**/", recursive=False):
        for filepath in glob.iglob(path + "*.csv", recursive=False):
            files_in_repository += [filepath]

            # check if file has been edited since last checked
            if filepath not in previous_checked:
                # delete validated file if currrently present
                df = df[df['file_path'] != filepath]

                # validate file
                file_error = validate_quantile_csv_file(filepath)

                # Check forecast file date = forecast_date column
                forecast_date_error = filename_match_forecast_date(filepath)
                if forecast_date_error is not None:
                    if file_error == 'no errors':
                        file_error = [forecast_date_error]
                    else:
                        file_error += [forecast_date_error]

                if file_error != 'no errors':
                    output_errors[filepath] = file_error
                else:
                    # add to previously checked files
                    current_time = datetime.now()
                    df = df.append({'file_path': filepath,
                                    'validation_date': current_time}, ignore_index=True)

    # Remove files that have been deleted from repo
    # files that are in verify checks but NOT in repository
    deleted_files = np.setdiff1d(previous_checked, files_in_repository)
    df = df[~df['file_path'].isin(deleted_files)]

    # update previously checked files
    df.to_csv('code/validation/locally_validated_files.csv', index=False)

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
