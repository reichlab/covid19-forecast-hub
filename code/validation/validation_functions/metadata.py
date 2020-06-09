
import dateutil
import os
import glob
from dateutil.parser import parse
import re
import yaml
import pandas as pd


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


def output_duplicate_models(existing_metadata_name, output_errors):
    for mname, mfiledir in existing_metadata_name.items():
        if len(mfiledir) > 1:
            error_string = ["METADATA ERROR: Found duplicate model abbreviation %s - in %s metadata" %
                            (mname, mfiledir)]
            output_errors[mname + "METADATA model_name"] = error_string
    return output_errors
