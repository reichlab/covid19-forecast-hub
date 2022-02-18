#mcandrew

from interface import interface
from model import VAR
import pandas as pd

if __name__ == "__main__":
    
    io = interface(0)
    predictions = io.grab_recent_predictions()
    cumPredictions = {"forecast_date":[]
                    ,"target_end_date":[]
                    ,"location":[], "target":[],"sample":[],"value":[]}

    sum = 0
    for index, row in predictions.iterrows():
        # if hopsitalizations, skip
        if row['target'][-4:] != "hosp":
            # if 1, sum = 0
            # add to sum, copy row, change target to say n + " day ahead cum covid case"/"death"
            if row['target'].split()[0] == "1":
                sum = 0
            sum += row["value"]
            cumPredictions["forecast_date"].append(row["forecast_date"])
            cumPredictions["target_end_date"].append(row["target_end_date"])
            cumPredictions["location"].append(row["location"])
            cumPredictions["target"].append(row["target"].replace("inc", "cum"))
            cumPredictions["sample"].append(row["sample"])
            cumPredictions["value"].append(sum)
    cumPredictions = pd.DataFrame(cumPredictions)
    pd.concat(predictions, cumPredictions)
