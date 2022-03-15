#mcandrew

from interface import interface
from model import VAR
import pandas as pd

if __name__ == "__main__":
    
    io = interface(data=None,location = 20)
    predictions = io.grab_recent_predictions()

    predictions["day"]  = predictions.target.str.extract("(\d+).*").astype("int")
    predictions["hosp"] = predictions.target.str.match(".*hosp$")
    predictions["target_no_time"] = predictions.target.str.extract(".* day ahead (.*)")
    
    fromDaily2Weekly = pd.DataFrame({"day":[x+1 for x in range(27+1)], "week": [1]*7 + [2]*7  + [3]*7 + [4]*7})

    predictions = predictions.merge(fromDaily2Weekly, on = ["day"])

    hospitilizations     = predictions[predictions.hosp==True]
    not_hospitilizations = predictions[predictions.hosp==False]
    
    def addUp(x):
        import pandas as pd

        vals = [ max(v,0) for v in x["value"]]
        summedPrediction = sum(vals)

        maxEndDate = max(pd.to_datetime(x.target_end_date)) 
        
        return pd.Series({"target_end_date": maxEndDate, "value":summedPrediction})
    groupedPredictions = not_hospitilizations.groupby(["forecast_date","location","target_no_time","sample","week"]).apply(addUp)
    groupedPredictions = groupedPredictions.reset_index()

    groupedPredictions["week_ahead"] = " week ahead "
    groupedPredictions["target"] = groupedPredictions["week"].astype(str) + groupedPredictions["week_ahead"] + groupedPredictions["target_no_time"] 

    groupedPredictions = groupedPredictions["forecast_date","target_end_date","location","target","sample","value"]
    dailyAndWeeklyPredictions = groupedPredictions.append(hospitilizations)

    day = io.getForecastDate()
    dailyAndWeeklyPredictions.to_csv("./location_specific_forecasts/{:s}_LUcompUncertLab-VAR__{:s}__weeklypredictions.csv.gz".format(date,io.fmtlocation)
                              ,header=True
                              ,index=False
                              ,mode="w"
                              ,compression="gzip")
