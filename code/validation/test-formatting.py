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
import collections
import re


def validate_metadata_contents(metadata, filepath):
    # Initialize output
    is_metadata_error = False
    metadata_error_output = []

    # Check for Required Fields
    required_fields = ['team_name', 'team_abbr', 'model_name', 'model_abbr', 'methods']
    # required_fields = ['team_name', 'team_abbr', 'model_name', 'model_abbr',\
    #                        'methods', 'team_url', 'license', 'include_in_ensemble_and_visualization']
    for field in required_fields:
        if field not in metadata.keys():
            is_metadata_error = True
            metadata_error_output += ["METADATA ERROR: %s missing '%s'" % (filepath, field)]

    # Check methods character length (warning not error)
    if 'methods' in metadata.keys():
        methods_char_lenth = len(metadata['methods'])
        if methods_char_lenth > 200:
            metadata_error_output += [
                "METADATA WARNING: %s methods is too many characters (%i should be less than 200)" %
                (filepath, methods_char_lenth)]

    # Check if forecast_startdate is date
    if 'forecast_startdate' in metadata.keys():
        forecast_startdate = str(metadata['forecast_startdate'])
        try:
            dateutil.parser.parse(forecast_startdate)
            is_date = True
        except ValueError:
            is_date = False
        if not is_date:
            is_metadata_error = True
            metadata_error_output += [
                "METADATA ERROR: %s forecast_startdate %s must be a date and should be in YYYY-MM-DD format" %
                (filepath, forecast_startdate)]

    # Check if this_model_is_an_ensemble and this_model_is_unconditional are boolean
    boolean_fields = ['this_model_is_an_ensemble', 'this_model_is_unconditional',
                      'include_in_ensemble_and_visualization']
    possible_booleans = ['true', 'false']
    for field in boolean_fields:
        if field in metadata.keys():
            if metadata[field] not in possible_booleans:
                is_metadata_error = True
                metadata_error_output += [
                    "METADATA ERROR: %s '%s' field must be lowercase boolean (true, false) not '%s'" %
                    (filepath, field, metadata[field])]

    # Validate team URLS
    regex = re.compile(
        r'^(?:http|ftp)s?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)

    if 'team_url' in metadata.keys():
        if re.match(regex, str(metadata['team_url'])) is None:
            is_metadata_error = True
            metadata_error_output += [
                "METADATA ERROR: %s 'team_url' field must be a full URL (https://www.example.com) '%s'" %
                (filepath, metadata[field])]

    # Validate licenses
    license_df = pd.read_csv('./code/validation/accepted-licenses.csv')
    accepted_licenses = list(license_df['license'])
    if 'license' in metadata.keys():
        if metadata['license'] not in accepted_licenses:
            is_metadata_error = True
            metadata_error_output += [
                "METADATA ERROR: %s 'license' field must be in `./code/validations/accepted-licenses.csv` 'license' column '%s'" %
                (filepath, metadata[field])]
    return is_metadata_error, metadata_error_output


def check_metadata_file(filepath):
    with open(filepath, 'r') as stream:
        try:
            Loader = yaml.BaseLoader  # Define Loader to avoid true/false auto conversion
            metadata = yaml.load(stream, Loader=yaml.BaseLoader)
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
            return True, ["FORECAST DATE ERROR %s forecast filename date %s does match forecast_date column %s" % (
                filepath, file_forecast_date, forecast_date_column)]
        else:
            return False, "no errors"


def validate_forecast_file(filepath):
    # validate forecast file
    file_error = validate_quantile_csv_file(filepath)

    if file_error != "no errors":
        return True, file_error
    else:
        return False, file_error


def validate_forecast_file_name(filepath, forecast_file_path):
    # validate forecast file name == forecast file path
    forecast_file_name = os.path.basename(filepath)[11:(len(filepath)-4)]

    if forecast_file_name == forecast_file_path:
        return False, "no errors"
    else:
        return True, ["FORECAST FILENAME ERROR: Please rename %s to proper format" % filepath]


def get_metadata_model(filepath):
    team_model = os.path.basename(os.path.dirname(filepath))
    metadata_filename = "metadata-" + team_model + ".txt"
    metdata_dir = filepath + metadata_filename
    model_name = None
    model_abbr = None
    with open(metdata_dir, 'r') as stream:
        try:
            metadata = yaml.safe_load(stream)
            # Output model name and model abbr if exists
            if 'model_name' in metadata.keys():
                model_name = metadata['model_name']
            if 'model_abbr' in metadata.keys():
                model_abbr = metadata['model_abbr']

            return model_name, model_abbr
        except yaml.YAMLError as exc:
            return None, None


def compile_output_errors(filepath,
                          is_filename_error, filename_error_output,
                          is_error, forecast_error_output,
                          is_date_error, forecast_date_output):
    # Initialize output errors
    output_error_text = []
    output_errors = {}

    error_bool = [is_filename_error, is_error, is_date_error]
    error_text = [filename_error_output, forecast_error_output, forecast_date_output]

    # Loop through all possible errors and add to final output
    for i in range(len(error_bool)):
        if error_bool[i]:  # Error == True
            output_error_text += error_text[i]

    # Output errors if present as dict
    # output_error_text = list(chain.from_iterable(output_error_text))
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
    if len(output_errors) > 0:
        for filename, errors in output_errors.items():
            print("\n* ERROR IN ", filename)
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
    existing_metadata_name = collections.defaultdict(list)
    existing_metadata_abbr = collections.defaultdict(list)
    errors_exist = False  # Keep track of errors

    # Iterate through processed csvs
    for path in glob.iglob(my_path + "**/**/", recursive=False):

        # check metadata file
        is_metadata_error, metadata_error_output = check_for_metadata(path)

        # check metadata names and abbreviations for duplicates
        model_name, model_abbr = get_metadata_model(path)

        # Add checked model_name and model_abbr to list to keep track of duplicates
        if model_name is not None:
            existing_metadata_name[model_name].append(path)
        if model_abbr is not None:
            existing_metadata_abbr[model_abbr].append(path)

        # Output metadata errors
        if is_metadata_error:
            output_errors[path] = metadata_error_output

        # Get filepath
        forecast_file_path = os.path.basename(os.path.dirname(path))

        # Iterate through forecast files to validate format
        for filepath in glob.iglob(path + "*.csv", recursive=False):
            files_in_repository += [filepath]

            # Check if file has been edited since last checked
            if filepath not in previous_checked:

                # Validate forecast file name = forecast file path
                # Get forecast file teamname-modelname
                is_filename_error, filename_error_output = validate_forecast_file_name(filepath, forecast_file_path)

                # Validate forecast file formatting
                is_error, forecast_error_output = validate_forecast_file(filepath)

                # Validate forecast file date = forecast_date column
                is_date_error, forecast_date_output = filename_match_forecast_date(filepath)

                # add to previously checked files
                output_error_text = compile_output_errors(filepath,
                                                          is_filename_error, filename_error_output,
                                                          is_error, forecast_error_output,
                                                          is_date_error, forecast_date_output)
                if output_error_text != []:
                    output_errors[filepath] = output_error_text

                # add validated file to locally_validated_files.csv
                if len(output_errors) == 0:
                    current_time = datetime.now()
                    df = df.append({'file_path': filepath,
                                    'validation_date': current_time}, ignore_index=True)

    # Output duplicate model name or abbreviation metadata errors
    for abbr, filedir in existing_metadata_abbr.items():
        if len(filedir) > 1:
            error_string = ["METADATA ERROR: Found duplicate model abbreviation %s - in %s metadata" %
                            (abbr, filedir)]
            output_errors[abbr + "METADATA model_abbr"] = error_string
    for mname, mfiledir in existing_metadata_name.items():
        if len(mfiledir) > 1:
            error_string = ["METADATA ERROR: Found duplicate model abbreviation %s - in %s metadata" %
                            (mname, mfiledir)]
            output_errors[mname + "METADATA model_name"] = error_string

    # Update the locally_validated_files.csv
    update_checked_files(df, previous_checked, files_in_repository)

    # Error if necessary and print to console
    print_output_errors(output_errors)


def main():
    my_path = "./data-processed"
    check_formatting(my_path)


if __name__ == "__main__":
    main()
