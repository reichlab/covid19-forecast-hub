#mcandrew

class interface(object):
    def __init__(self,fluhosp,includedstates):
        self.fluhosp = fluhosp
        
        self.includedstates = includedstates
        self.timeseriesName = includedstates

        self.buildDataForModel()
        self.getForecastDate()
        self.generateTargetEndDates()
        self.generateTargetNames()

        self.numOfForecasts = 4 # FOR NOW THIS IS HARDCODED AS a 4 WEEK AHEAD

    def buildDataForModel(self):
        import numpy as np
        y = np.array(self.fluhosp.drop(columns=["location"]))
        self.y = y.T
        return y.T

    def getForecastDate(self):
        import datetime
        from epiweeks import Week

        from datetime import datetime as dt

        today = dt.today()
        dayofweek = today.weekday()

        thisWeek = Week.thisweek()
        if dayofweek in {6,0}: # a SUNDAY or MONDAY
            thisWeek = thisWeek-1
        else:
            pass
        self.thisWeek = thisWeek
        
        forecastDate = ((thisWeek+1).startdate() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
        self.forecast_date = forecastDate
        return forecastDate

    def generateTargetEndDates(self):
        import numpy as np
        
        target_end_dates = []
        for f in np.arange(1,4+1): # four weeks ahead
            ted = ((self.thisWeek+int(f)).enddate()).strftime("%Y-%m-%d")
            target_end_dates.append(ted)
        self.target_end_dates = target_end_dates
        return target_end_dates

    def generateTargetNames(self):
        import numpy as np

        targets = ["{:d} wk ahead inc covid cases".format(ahead) for ahead in np.arange(1,4+1)]
        self.targets = targets
        return targets

    def writeData(self,writeout,dataQuantiles,QS,TP,LAG):
            quantileString = "LAG{:02d}/MEPAcast_preprocess__{:03d}_{:03d}_{:03d}.csv".format(LAG,TP,QS,LAG)
            dataQuantiles.to_csv(quantileString ,header=True,mode="w",index=False)
                
    def accessPredictionsAndQuantiles(self,QS,TP,LAG):
        import pandas as pd

        mostRecentFile = "LAG{:02d}/MEPAcast_preprocess__{:03d}_{:03d}_{:03d}.csv".format(LAG,TP,QS,LAG)
        print(mostRecentFile)
        quantiles = pd.read_csv(mostRecentFile)

        #mostRecentFile = sorted(glob("*allPredictions*.csv"))[-1]
        #predictions = pd.read_csv(mostRecentFile)

        self.quantiles = quantiles #,self.predictions = quantiles,predictions
        return quantiles#,predictions

if __name__ == "__main__":
    pass

