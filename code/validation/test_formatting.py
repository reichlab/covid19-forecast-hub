from zoltpy.covid19 import validate_quantile_csv_file
import glob
from pprint import pprint
import sys
import os
import pandas as pd
import numpy as np
from datetime import datetime
import yaml
from itertools import chain
import collections
from github import Github


from validation_functions.metadata import check_for_metadata, get_metadata_model, output_duplicate_models
from validation_functions.forecast_filename import validate_forecast_file_name
from validation_functions.forecast_date import filename_match_forecast_date

metadata_version = 4

def validate_forecast_file(filepath, silent=False):
    """
    purpose: Validates the forecast file with zoltpy 
    link: https://github.com/reichlab/zoltpy/blob/master/zoltpy/covid19.py

    params:
    * filepath: Full filepath of the forecast
    """
    file_error = validate_quantile_csv_file(filepath, silent=silent)

    if file_error != "no errors":
        return True, file_error
    else:
        return False, file_error


def compile_output_errors(filepath, is_filename_error, filename_error_output, is_error, forecast_error_output,
                          is_date_error, forecast_date_output):
    """
    purpose: update locally_validated_files.csv and remove deleted files

    params:
    * filepath: Full filepath of the forecast
    * is_filename_error: Filename != file path (True/False)
    * filename_error_output: Text output error filename != file path
    * is_error: Forecast file has error (True/False)
    * forecast_error_output: Text output forecast file error
    * is_date_error: forecast_date error (True/False)
    * forecast_date_output: Text output forecast_date error
    """
    # Initialize output errors as list
    output_error_text = []

    # Iterate through params
    error_bool = [is_filename_error, is_error, is_date_error]
    error_text = [filename_error_output, forecast_error_output, forecast_date_output]

    # Loop through all possible errors and add to final output
    for i in range(len(error_bool)):
        if error_bool[i]:  # Error == True
            output_error_text += error_text[i]

    # Output errors if present as dict
    # Output_error_text = list(chain.from_iterable(output_error_text))
    return output_error_text


def update_checked_files(df, previous_checked, files_in_repository):
    """
    purpose: update locally_validated_files.csv and remove deleted files

    params:
    * df: Pandas dataframe containing currently checked files
    * previous_checked: Previously checked files as list
    * files_in_repository: Current files in repo as list
    """
    # Remove files that have been deleted from repo
    # Files that are in verify checks but NOT in repository
    deleted_files = np.setdiff1d(previous_checked, files_in_repository)
    df = df[~df['file_path'].isin(deleted_files)]

    # update previously checked files
    df.to_csv('code/validation/locally_validated_files.csv', index=False)


def print_output_errors(output_errors, prefix=""):
    """
    purpose: Print the final errors

    params:
    * output_errors: Dict with filepath as key and list of errors error as value
    """
    # Output list of Errors
    if len(output_errors) > 0:
        for filename, errors in output_errors.items():
            print("\n* ERROR IN ", filename)
            for error in errors:
                print(error)
        print("\n✗ %s error found in %d file%s. Error details are above." % (prefix, len(output_errors) ,("s" if len(output_errors)>1 else "")))
    else:
        print("\n✓ no %s errors"% (prefix))


# Check forecast formatting
def check_formatting(my_path):
    """
    purpose: Iterate through every forecast file and metadatadata 
             file and perform validation checks if haven't already.
    link: https://github.com/reichlab/covid19-forecast-hub/wiki/Validation-Checks#current-validation-checks

    params:
    * my_path: string path to folder where forecasts are
    """
    df = pd.read_csv('code/validation/validated_files.csv')
    previous_checked = list(df['file_path'])
    files_in_repository = []
    output_errors = {}
    meta_output_errors = {}
    existing_metadata_name = collections.defaultdict(list)
    existing_metadata_abbr = collections.defaultdict(list)
    errors_exist = False  # Keep track of errors
    metadata_validation_cache = {}
    # Iterate through processed csvs
    for path in glob.iglob(my_path + "**/**/", recursive=False):

        # Check metadata file
        is_metadata_error, metadata_error_output = check_for_metadata(
            path, cache=metadata_validation_cache)

        # Check metadata names and abbreviations for duplicates
        model_name, model_abbr = get_metadata_model(path)

        # Add checked model_name and model_abbr to list to keep track of duplicates
        if model_name is not None:
            existing_metadata_name[model_name].append(path)
        if model_abbr is not None:
            existing_metadata_abbr[model_abbr].append(path)

        # Output metadata errors
        if is_metadata_error:
            meta_output_errors[path] = metadata_error_output

        # Get filepath
        forecast_file_path = os.path.basename(os.path.dirname(path))

        # Iterate through forecast files to validate format
        for filepath in glob.iglob(path + "*.csv", recursive=False):
            files_in_repository += [filepath]

            # Check if file has been edited since last checked
            if filepath not in previous_checked:

                # Validate forecast file name = forecast file path
                is_filename_error, filename_error_output = validate_forecast_file_name(filepath, forecast_file_path)

                # Validate forecast file formatting
                is_error, forecast_error_output = validate_forecast_file(filepath)

                # Validate forecast file date = forecast_date column
                is_date_error, forecast_date_output = filename_match_forecast_date(filepath)

                # Add to previously checked files
                output_error_text = compile_output_errors(filepath,
                                                          is_filename_error, filename_error_output,
                                                          is_error, forecast_error_output,
                                                          is_date_error, forecast_date_output)
                if output_error_text != []:
                    output_errors[filepath] = output_error_text

                # Add validated file to locally_validated_files.csv
                if len(output_errors) == 0:
                    current_time = datetime.now()
                    df = df.append({'file_path': filepath,
                                    'validation_date': current_time}, ignore_index=True)

    # Output duplicate model name or abbreviation metadata errors
    output_errors = output_duplicate_models(existing_metadata_abbr, output_errors)
    output_errors = output_duplicate_models(existing_metadata_name, output_errors)

    # Update the locally_validated_files.csv
    update_checked_files(df, previous_checked, files_in_repository)

    # Error if necessary and print to console
    print_output_errors(meta_output_errors, prefix='metadata')
    print_output_errors(output_errors, prefix='data')
    print('Using validation code v%g.' % metadata_version)
    if len(meta_output_errors) + len(output_errors) > 0:
        sys.exit("\n ERRORS FOUND EXITING BUILD...")

# remove all entries of type files_changed from validated_files.csv
def remove_all_entries_from_validated_files(files_changed):
    val_path = './code/validation/validated_files.csv'
    validated_files = pd.read_csv(val_path)
    if len(files_changed)>0:
        for f in files_changed:
            validated_files = validated_files[validated_files.file_path != f]
        validated_files.to_csv(val_path, index=False)

def main():
    my_path = "./data-processed"
    forecasts_changed = []

    g = Github()
    repo = g.get_repo('reichlab/covid19-forecast-hub')    
    
    if os.environ.get('GITHUB_ACTIONS')=='true':
        print(f"Github event name: {os.environ.get('GITHUB_EVENT_NAME')}")
        if os.environ.get('GITHUB_EVENT_NAME') == 'pull_request':
            # GIHUB_REF for PR is in the format: refs/pull/:prNumber/merge, extracting that here:
            pr_num = int(os.environ.get('GITHUB_REF').split('/')[-2])
            pr = repo.get_pull(pr_num)
            files_changed = [f for f in pr.get_files()]
        elif os.environ.get('GITHUB_EVENT_NAME') == 'push':
            commit = repo.get_commit(sha = os.environ.get('GITHUB_SHA'))
            files_changed = commit.files
        if files_changed is not None:
            forecasts_changed.extend([f"./{file.filename}" for file in files_changed if file.filename.startswith('data-processed') and file.filename.endswith('.csv')])
    elif os.environ.get('TRAVIS')=='true':
        if os.environ.get('TRAVIS_EVENT_TYPE')=='pull_request':
            pr_num = int(os.environ.get('TRAVIS_PULL_REQUEST'))
            pr = repo.get_pull(pr_num)
            files_changed = [f for f in pr.get_files()]
            forecasts_changed.extend([f"./{file.filename}" for file in files_changed if file.filename.startswith('data-processed') and file.filename.endswith('.csv')])
    remove_all_entries_from_validated_files(forecasts_changed)
    print(f"files changed: {forecasts_changed}")
    check_formatting(my_path)


if __name__ == "__main__":
    main()
