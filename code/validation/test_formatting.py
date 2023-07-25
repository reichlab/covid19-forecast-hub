import calendar
import time

from zoltpy.covid19 import validate_quantile_csv_file
import glob
import sys
import os
import pandas as pd
import numpy as np
from datetime import datetime
import collections
from github import Github
from pathlib import Path

from validation_functions.metadata import check_for_metadata, get_metadata_model, output_duplicate_models
from validation_functions.forecast_filename import validate_forecast_file_name
from validation_functions.forecast_date import filename_match_forecast_date

metadata_version = 5

# this is the root of the repository. 
root = (Path(__file__) / '..'/'..'/'..').resolve()
pop_df = pd.read_csv(open(root/'data-locations'/'locations.csv')).astype({'location':str})


'''
    Get the numer of invalid predictions in a forecast file.
    
    What counts as an `invalid` prediction? 
    - A prediction who's `value` is greater than the population of that region. 

    Method:
    1. convert the location column to an integer (so that we can do an efficient `join` with the forecast DataFrame)
    2. Do a left join of the forecast DataFrame with population dataframe on the `location` column.
    3. Find number of rows that have the value in `value` column >= the value of the `Population` column.

    Population data: 
    Retrieved from the JHU timeseries data used for generating the truth data file. (See /data-locations/populations.csv)
    County population aggregated to state and state thereafter aggregated to national. 
'''
def get_num_invalid_predictions(forecast_filename):
    model_df = pd.read_csv(open(forecast_filename, 'r'))
    # preprocess model dataframe
#     model_df['location'].replace('US', -1, inplace=True)
    model_df = model_df.astype({'location':str})
    merged = model_df.merge(pop_df[['location', 'population']], on='location', how='left')
    num_invalid_preds = np.sum(merged['value'] >= merged['population'])
    return num_invalid_preds, merged[merged['value'] >= merged['population']]
    

def validate_forecast_values(filepath):
    num_invalid, preds = get_num_invalid_predictions(filepath)
    if  num_invalid> 0:
        return True, [f"PREDICTION ERROR: You have {num_invalid} invalid predictions in your file. Invalid Predictions:\n {preds}"]
    return  False, "no errors"

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

                # valdate predictions
                if not is_error:
                    is_error, forecast_error_output = validate_forecast_values(filepath)


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
                    new_row = pd.Series({'file_path': filepath,
                                         'validation_date': current_time})
                    pd.concat([df, new_row.to_frame().T], ignore_index=True)

    # Output duplicate model name or abbreviation metadata errors
    output_errors = output_duplicate_models(existing_metadata_abbr, output_errors)
    #output_errors = output_duplicate_models(existing_metadata_name, output_errors)

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


# `Github.get_repo()` wrapper that handles rate limiting by sleeping for 60 seconds if necessary. copied from
# https://github.com/reichlab/covid19-forecast-evals/blob/main/code/get_file_version_version_full.py
def get_repo():
    g = Github()

    # sleep if hitting rate limit. https://github.com/PyGithub/PyGithub/issues/1319
    rate_limit = g.get_rate_limit()
    core_rate_limit = rate_limit.core
    remaining = core_rate_limit.remaining
    if remaining < 20:  # NB: 20 is arbitrary threshold for calls remaining
        # add seconds to be sure the rate limit has been reset:
        reset_timestamp = calendar.timegm(core_rate_limit.reset.timetuple())
        sleep_time = reset_timestamp - calendar.timegm(time.gmtime()) + 60  # seconds. NB: 60 is arbitrary
        print(f"limit low. rate_limit={rate_limit}, reset_timestamp={reset_timestamp}, sleep_time={sleep_time}")

        # good night
        if sleep_time > 0:  # NB: sometimes it's negative. don't know why
            time.sleep(sleep_time)
        else:
            time.sleep(60)  # NB: arbitrary

        rate_limit = g.get_rate_limit()
        print(f"awake. rate_limit={rate_limit}")
    else:
        print(f"limit ok. rate_limit={rate_limit}")

    # continue
    return g.get_repo('reichlab/covid19-forecast-hub')


def main():
    my_path = "./data-processed"
    forecasts_changed = []
    repo = get_repo()
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        print(f"Github event name: {os.environ.get('GITHUB_EVENT_NAME')}")
        if os.environ.get('GITHUB_EVENT_NAME') == 'pull_request':
            # GIHUB_REF for PR is in the format: refs/pull/:prNumber/merge, extracting that here:
            pr_num = int(os.environ.get('GITHUB_REF').split('/')[-2])
            pr = repo.get_pull(pr_num)
            files_changed = [f for f in pr.get_files()]
        elif os.environ.get('GITHUB_EVENT_NAME') == 'push':
            commit = repo.get_commit(sha=os.environ.get('GITHUB_SHA'))
            files_changed = commit.files

        if 'files_changed' in locals() and files_changed is not None:
            forecasts_changed.extend([f"./{file.filename}" for file in files_changed if
                                      file.filename.startswith('data-processed') and file.filename.endswith('.csv')])
    elif os.environ.get('TRAVIS') == 'true':
        if os.environ.get('TRAVIS_EVENT_TYPE') == 'pull_request':
            pr_num = int(os.environ.get('TRAVIS_PULL_REQUEST'))
            pr = repo.get_pull(pr_num)
            files_changed = [f for f in pr.get_files()]
            forecasts_changed.extend([f"./{file.filename}" for file in files_changed if
                                      file.filename.startswith('data-processed') and file.filename.endswith('.csv')])
    remove_all_entries_from_validated_files(forecasts_changed)
    print(f"files changed: {forecasts_changed}")
    check_formatting(my_path)


if __name__ == "__main__":
    main()
