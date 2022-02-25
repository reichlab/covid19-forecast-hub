#mcandrew

from interface import interface
from model import VAR
import pandas as pd

if __name__ == "__main__":
    
    
    io = interface(0)
    predictions = io.grab_recent_predictions()
    dailyPredictions = {"forecast_date":[]
                    ,"target_end_date":[]
                    ,"location":[], "target":[],"sample":[],"value":[]}
    weeklyPredictions = {"forecast_date":[]
                    ,"target_end_date":[]
                    ,"location":[], "target":[],"sample":[],"value":[]}
    
    # dSum: daily, wSum: weekly
    dSum = 0
    wSum = 0
    for index, row in predictions.iterrows():
        # if hopsitalizations, skip
        if row['target'][-4:] != "hosp":
            # if 1, sum = 0
            # add to sum, copy row, change target to say n + " day ahead cum covid case"/"death"
            day = row['target'].split()[0]
            if day == "1":
                dSum = 0

            # add the row's value to weekly sum and daily sum
            wSum += row["value"]
            dSum += row["value"]

            # every day take the sum
            dailyPredictions["forecast_date"].append(row["forecast_date"])
            dailyPredictions["target_end_date"].append(row["target_end_date"])
            dailyPredictions["location"].append(row["location"])
            dailyPredictions["target"].append(row["target"].replace("inc", "cum"))
            dailyPredictions["sample"].append(row["sample"])
            dailyPredictions["value"].append(dSum)

            # if day is end of week forecast, add to weeklyPredictions dictionary
            if day == "7" or day == "14" or day == "21" or day == "28":
                weeklyPredictions["forecast_date"].append(row["forecast_date"])
                weeklyPredictions["target_end_date"].append(row["target_end_date"])
                weeklyPredictions["location"].append(row["location"])
                newTarget = row["target"].replace("inc", "cum")
                if day == "7":
                    weeklyPredictions["target"].append(row["target"].replace("7 day", "1 wk"))
                if day == "14":
                    weeklyPredictions["target"].append(row["target"].replace("14 day", "2 wk"))
                if day == "21":
                    weeklyPredictions["target"].append(row["target"].replace("21 day", "3 wk"))
                if day == "28":
                    weeklyPredictions["target"].append(row["target"].replace("28 day", "4 wk"))
                weeklyPredictions["sample"].append(row["sample"])
                weeklyPredictions["value"].append(wSum)
                wSum = 0
    
    date = dailyPredictions["forecast_date"][0]
    # dictionary to df
    dailyPredictions = pd.DataFrame(dailyPredictions)
    weeklyPredictions = pd.DataFrame(weeklyPredictions)
    # append the daily cumulative preds to incident forecast
    both = pd.concat([predictions, dailyPredictions])
    # append the weekly cumulative preds
    dailyAndWeeklyPred = pd.concat([both, weeklyPredictions])

    dailyAndWeeklyPred.to_csv("{:s}_LUcompUncertLab-VAR__cumulativepredictions.csv.gz".format(date),header=True,index=False,mode="w",compression="gzip")