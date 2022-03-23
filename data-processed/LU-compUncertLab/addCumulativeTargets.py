#mcandrew

from interface import interface
from model import VAR
import pandas as pd

import argparse

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--LOCATION', type=int)

    args = parser.parse_args()

    LOCATION = args.LOCATION
 
    io = interface(data=None,location = LOCATION)
    predictions = io.grab_recent_weekly_predictions()

    deathTargets = predictions.loc[ predictions.target.str.contains("death"),:]
    deathTargets["week"]  = deathTargets.target.str.extract("(\d+) week.*").astype("int")
    
    def cumulative(d):
        import numpy as np
        d = d.sort_values("week")
        cumulative_values = list(np.cumsum(d["value"]))

        weeks            = d.week.values
        target_end_dates = d.target_end_date.values 

        return pd.DataFrame({"week":weeks, "target_end_date":target_end_dates,"value": cumulative_values})
    deathTargets =  deathTargets.groupby(["forecast_date","location","sample"]).apply(cumulative)

    deathTargets = deathTargets.reset_index()
    deathTargets = deathTargets[["forecast_date","target_end_date","location","sample","value", "week"]]

    deathTargets["target"] = deathTargets["week"].astype(str) + " wk ahead cum death"
    deathTargets = deathTargets[["forecast_date","target_end_date","target","location","sample","value"]]

    
    predictions = predictions.append(deathTargets)
   
    day = io.getForecastDate()
    predictions.to_csv("./location_specific_forecasts/{:s}_LUcompUncertLab-VAR__{:s}__allpredictions.csv.gz".format(day,io.fmtlocation)
                              ,header=True
                              ,index=False
                              ,mode="w"
                              ,compression="gzip")
