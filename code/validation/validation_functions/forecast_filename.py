import os


def validate_forecast_file_name(filepath, forecast_file_path):
    # validate forecast file name == forecast file path
    forecast_file_name = os.path.basename(filepath)[11:]  # delete date
    forecast_file_name = forecast_file_name[:len(forecast_file_name)-4]
    if forecast_file_name == forecast_file_path:
        return False, "no errors"
    else:
        return True, ["FORECAST FILENAME ERROR: Please rename %s to proper format" % filepath]
