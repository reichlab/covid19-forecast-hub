from zoltpy.covid19 import validate_quantile_csv_file
import glob
from pprint import pprint
import sys
import os
import pandas as pd
import numpy as np
from datetime import datetime
import yaml


def check_metadata_file(filepath):
    with open(filepath, 'r') as stream:
        print(yaml.load(filepath))
        try:
            # print(yaml.safe_load(stream))
            errors = "no_errors"
        except yaml.YAMLError as exc:
            print("METADATA ERROR",  exc)


# Check for metadata file
def check_for_metadata(filepath):
    team_model = os.path.basename(os.path.dirname(filepath))
    metadata_filename = "metadata-" + team_model + ".txt"
    txt_files = []
    for metadata_file in glob.iglob(filepath + "*.txt", recursive=False):
        txt_files += [os.path.basename(metadata_file)]
    if metadata_filename in txt_files:
        metadata_filepath = filepath + metadata_filename
        check_metadata_file(metadata_filepath)
    else:
        print("MISSING ", metadata_filename)


def filename_match_forecast_date(filepath):
    df = pd.read_csv(filepath)
    file_forecast_date = os.path.basename(os.path.basename(filepath))[:10]
    forecast_date_column = set(list(df['forecast_date']))
    if len(forecast_date_column) > 1:
        return True, ["ERROR: %s has multiple forecast dates: %s. Forecast date must be unique" % (
            filepath, forecast_date_column)]
    else:
        forecast_date_column = forecast_date_column.pop()
        if (file_forecast_date != forecast_date_column):
            return True, ["ERROR %s forecast filename date %s does match forecast_date column %s" % (
                filepath, file_forecast_date, forecast_date_column)]
        else:
            return False, "no errors"


def validate_forecast_file(filepath):
    # validate forecast file
    file_error = validate_quantile_csv_file(filepath)
    if file_error != 'no errors':
        return True, file_error
    else:
        return False, file_error


def compile_output_errors(filepath, is_error, forecast_error_output,
                          is_date_error, forecast_date_output):
    # Initialize output errors
    output_error_text = []
    output_errors = {}

    # Check for forecast file errors
    if is_error:
        output_error_text += [forecast_error_output]

    # Check for forecast date errors
    if is_date_error:
        output_error_text += [forecast_date_output]

    # Output errors if present as dict
    if output_error_text != []:
        output_errors[filepath] = output_error_text
        return output_errors
    else:
        return None


def update_checked_files(df, previous_checked, files_in_repository):
    # Remove files that have been deleted from repo
    # files that are in verify checks but NOT in repository
    deleted_files = np.setdiff1d(previous_checked, files_in_repository)
    df = df[~df['file_path'].isin(deleted_files)]

    # update previously checked files
    df.to_csv('code/validation/locally_validated_files.csv', index=False)


def print_output_errors(output_errors):
    # Output list of Errors
    if output_errors is not None:
        for filename, errors in output_errors.items():
            print("\n* ERROR IN '", filename, "'\n")
            for error in errors:
                for err in error:
                    print(error[0])
        sys.exit("\n ERRORS FOUND EXITING BUILD...")
    else:
        print("✓ no errors")

# Check forecast formatting


def check_formatting(my_path):
    df = pd.read_csv('code/validation/validated_files.csv')
    previous_checked = list(df['file_path'])
    files_in_repository = []
    output_errors = {}
    errors_exist = False  # Keep track of errors

    # Iterate through processed csvs
    for path in glob.iglob(my_path + "**/**/", recursive=False):

        # check metadata file
        check_for_metadata(path)

        for filepath in glob.iglob(path + "*.csv", recursive=False):
            files_in_repository += [filepath]

            # Check if file has been edited since last checked
            if filepath not in previous_checked:
                # Validate forecast file formatting
                is_error, forecast_error_output = validate_forecast_file(filepath)

                # Validate forecast file date = forecast_date column
                is_date_error, forecast_date_output = filename_match_forecast_date(filepath)

                # add to previously checked files
                output_errors = compile_output_errors(filepath, is_error, forecast_error_output,
                                                      is_date_error, forecast_date_output)

                # add validated file to locally_validated_files.csv
                if output_errors is None:
                    current_time = datetime.now()
                    df = df.append({'file_path': filepath,
                                    'validation_date': current_time}, ignore_index=True)

    # Update the locally_validated_files.csv
    update_checked_files(df, previous_checked, files_in_repository)

    # Error if necessary and print to console
    print_output_errors(output_errors)


def main():
    my_path = "./data-processed"
    check_formatting(my_path)


if __name__ == "__main__":
    main()
