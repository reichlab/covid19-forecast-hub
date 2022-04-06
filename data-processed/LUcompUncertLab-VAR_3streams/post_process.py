#mcandrew

import sys
import numpy as np
import pandas as pd

import argparse

from interface import interface

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--LOCATION')

    args = parser.parse_args()

    LOCATION = args.LOCATION
    
    io = interface(0,LOCATION)
    forecast = io.grab_recent_all_predictions()
    forecast['value'] = forecast['value'].clip(lower=0)

    forecast["target_end_date"] = pd.to_datetime(forecast.target_end_date)
    forecast["target_end_date"] = forecast.target_end_date.dt.strftime("%Y-%m-%d")
    
    day = io.getForecastDate()
    forecast.to_csv("./location_specific_forecasts/{:s}_LUcompUncertLab-VAR3Streams__{:s}.csv.gz".format(day,io.fmtlocation)
                              ,header=True
                              ,index=False
                              ,mode="w"
                              ,compression="gzip")
