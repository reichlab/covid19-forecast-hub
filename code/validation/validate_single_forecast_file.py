from test_formatting import validate_forecast_file
import sys
import glob
import os

forecast_paths = glob.glob('data-processed/**/*.csv')
if __name__ == "__main__":
    filename = None
    if len(sys.argv) >1:
        filename = sys.argv[1]
    if filename is not None:
        if os.path.sep not in filename:
            filenames = [p for p in forecast_paths if filename in p]
            if len(filenames) == 0:
                print(f"No forecast file with name: {filename}")
        else:
            filenames = [filename]
        for forecast in filenames:
            print(f"\nVALIDATING {forecast}")
            is_error, errors = validate_forecast_file(forecast, silent=True)
            if is_error:
                print(f"✘ Error in {forecast}. Error(s):\n {errors}")
            else:
                print(f"✓ {forecast} is valid with no errors")