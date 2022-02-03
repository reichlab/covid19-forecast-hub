#mcandrew

class interface(object):
    def __init__(self,data=None):
        import pandas as pd
        
        if data is None:
            pass
        else:
            self.data = pd.read_csv("threestreams.csv.gz")
        
        self.buildDataForModel()
        self.getForecastDate()
        self.generateTargetEndDates()
        self.generateTargetNames()

        self.numOfForecasts = 4 # FOR NOW THIS IS HARDCODED AS a 4 WEEK AHEAD

    def subset2locations(self,locations):
        d = self.data
        d = d.loc[d.location.isin(locations)]
        self.data = d
        return d
        
    def buildDataForModel(self):
        import numpy as np
        
        y = np.array(self.data.drop(columns=["location","location_name"]).set_index("date"))
        self.modeldata = y.T
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
                
if __name__ == "__main__":
    pass

