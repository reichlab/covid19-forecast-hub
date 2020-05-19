from zoltpy.covid19 import validate_quantile_csv_file
import glob
from pprint import pprint
import sys
import os
import pandas as pd
import numpy as np
from datetime import datetime
import yaml
import dateutil
from dateutil.parser import parse
from itertools import chain


def is_date(string):
    """
    Return whether the string can be interpreted as a date.
    :param string: str, string to check for date
    """
    try:
        dateutil.parser.parse(string)
        return True
    except ValueError:
        return False


def validate_metadata_contents(metadata, filepath):
    # Initialize output
    is_metadata_error = False
    metadata_error_output = []

    # Check for Required Fields
    required_fields = ['team_name', 'team_abbr', 'model_name', 'model_abbr', 'methods']
    for field in required_fields:
        if field not in metadata.keys():
            is_metadata_error = True
            metadata_error_output += ["METADATA ERROR: %s missing '%s'" % (filepath, field)]

    # Check methods character length
    if 'methods' in metadata.keys():
        methods_char_lenth = len(metadata['methods'])
        if methods_char_lenth > 200:
            is_metadata_error = True
            metadata_error_output += [
                "METADATA ERROR: %s methods is too many characters (%i should be less than 200)" %
                (filepath, methods_char_lenth)]

    # Check if forecast_startdate is date
    if 'forecast_startdate' in metadata.keys():
        forecast_startdate = str(metadata['forecast_startdate'])
        if not is_date(forecast_startdate):
            is_metadata_error = True
            metadata_error_output += [
                "METADATA ERROR: %s forecast_startdate %s must be a date and should be in YYYY-MM-DD format" %
                (filepath, forecast_startdate)]

    # Check if this_model_is_an_ensemble and this_model_is_unconditional are boolean
    boolean_fields = ['this_model_is_an_ensemble', 'this_model_is_unconditional']
    possible_booleans = ['true', 'false', True, False]
    for field in boolean_fields:
        if field in metadata.keys():
            if str(metadata[field]).lower() not in possible_booleans:
                is_metadata_error = True
                metadata_error_output += [
                    "METADATA ERROR: %s '%s' field must be boolean (True, False) not '%s'" %
                    (filepath, field, metadata[field])]

    return is_metadata_error, metadata_error_output


def check_metadata_file(filepath):
    with open(filepath, 'r') as stream:
        try:
            metadata = yaml.safe_load(stream)
            is_metadata_error, metadata_error_output = validate_metadata_contents(metadata, filepath)
            if is_metadata_error:
                return True, metadata_error_output
            else:
                return False, "no errors"
        except yaml.YAMLError as exc:
            return True, [
                "METADATA ERROR: Metadata YAML Fromat Error for %s file. \
                    \nCommon fixes (if parse error message is unclear):\
                    \n* Try converting all tabs to spaces \
                    \n* Try copying the example metadata file and follow formatting closely \
                    \n Parse Error Message:\n%s \n"
                % (filepath, exc)]


# Check for metadata file
def check_for_metadata(filepath):
    team_model = os.path.basename(os.path.dirname(filepath))
    metadata_filename = "metadata-" + team_model + ".txt"
    txt_files = []
    for metadata_file in glob.iglob(filepath + "*.txt", recursive=False):
        txt_files += [os.path.basename(metadata_file)]
    if metadata_filename in txt_files:
        metadata_filepath = filepath + metadata_filename
        is_metadata_error, metadata_error_output = check_metadata_file(metadata_filepath)
        return is_metadata_error, metadata_error_output
    else:
        return True, ["METADATA ERROR: Missing Metadata: ", metadata_filename]


def filename_match_forecast_date(filepath):
    df = pd.read_csv(filepath)
    file_forecast_date = os.path.basename(os.path.basename(filepath))[:10]
    forecast_date_column = set(list(df['forecast_date']))
    if len(forecast_date_column) > 1:
        return True, ["FORECAST DATE ERROR: %s has multiple forecast dates: %s. Forecast date must be unique" % (
            filepath, forecast_date_column)]
    else:
        forecast_date_column = forecast_date_column.pop()
        if (file_forecast_date != forecast_date_column):
            return True, ["FORECAST DATE  ERROR %s forecast filename date %s does match forecast_date column %s" % (
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


def compile_output_errors(filepath,
                          is_metadata_error, metadata_error_output,
                          is_error, forecast_error_output,
                          is_date_error, forecast_date_output):
    # Initialize output errors
    output_error_text = []
    output_errors = {}

    # Check for metadata file errors
    if is_metadata_error:
        output_error_text += [metadata_error_output]

    # Check for forecast file errors
    if is_error:
        output_error_text += [forecast_error_output]

    # Check for forecast date errors
    if is_date_error:
        output_error_text += [forecast_date_output]

    # Output errors if present as dict
    output_error_text = list(chain.from_iterable(output_error_text))
    return output_error_text


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
            print("\n* ERROR IN '", filename)
            for error in errors:
                print(error)
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
        is_metadata_error, metadata_error_output = check_for_metadata(path)

        for filepath in glob.iglob(path + "*.csv", recursive=False):
            files_in_repository += [filepath]

            # Check if file has been edited since last checked
            if filepath not in previous_checked:
                # Validate forecast file formatting
                is_error, forecast_error_output = validate_forecast_file(filepath)

                # Validate forecast file date = forecast_date column
                is_date_error, forecast_date_output = filename_match_forecast_date(filepath)

                # add to previously checked files
                output_error_text = compile_output_errors(filepath,
                                                          is_metadata_error, metadata_error_output,
                                                          is_error, forecast_error_output,
                                                          is_date_error, forecast_date_output)
                if output_error_text != []:
                    output_errors[filepath] = output_error_text

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
