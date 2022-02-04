#mcandrew

class interface(object):
    def __init__(self,data=None):
        import pandas as pd
        
        if data is None:
            pass
        else:
            self.data = pd.read_csv("threestreams.csv.gz")
            self.centered_data = pd.read_csv("centered_threestreams.csv.gz")
            self.running_means = pd.read_csv("running_mean_threestreams.csv.gz")
            self.locations = sorted(self.data.location.unique())
            
        self.buildDataForModel()
        self.getForecastDate()
        self.generateTargetEndDates()
        self.generateTargetNames()

        self.numOfForecasts = 4 # FOR NOW THIS IS HARDCODED AS a 4 WEEK AHEAD

    def subset2locations(self,locations):

        def subset(d):
            return d.loc[d.location.isin(locations)]

        self.data          = subset(self.data)
        self.centered_data = subset(self.centered_data)
        self.running_means  = subset(self.running_means)
        
    def buildDataForModel(self):
        import numpy as np
        
        y = np.array(self.centered_data.drop(columns=["location","location_name"]).set_index("date"))
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

    #----------processing model samples
    def formatSamples(self,model):
        import numpy as np
        import pandas as pd
        
        dataPredictions = {"forecast_date":[],"target_end_date":[],"location":[], "target":[],"sample":[],"value":[]}
        predictions = model.fit["ytilde"][:,-self.F:,:] # this is coming from the model object

        F = self.numOfForecasts
        for sample,forecasts in enumerate(np.moveaxis(predictions,2,0)):
            for n,forecast in enumerate(forecasts):
                dataPredictions["forecast_date"].extend(F*[self.forecast_date])
                dataPredictions["location"].extend( F*[self.timeseriesName[n]] )
                dataPredictions["target_end_date"].extend( self.target_end_dates )
                dataPredictions["target"].extend( self.targets )
                dataPredictions["sample"].extend( F*[sample] )
                dataPredictions["value"].extend( forecast )
        dataPredictions = pd.DataFrame(dataPredictions)

        self.dataPredictions = dataPredictions
        return dataPredictions

    def fromSamples2Quantiles(self):
        
        def createQuantiles(self,x):
            import numpy as np
            import pandas as pd

            quantiles = np.array([0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500
                                  ,0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990])
            quantileValues = np.percentile( x["value"], q=100*quantiles)     
            return pd.DataFrame({"quantile":list(quantiles),"value":list(quantileValues)})

        dataQuantiles = self.dataPredictions.groupby(["forecast_date","target_end_date","location","target"]).apply(lambda x:createQuantiles(x)).reset_index().drop(columns="level_4")
        dataQuantiles["type"] = "quantile"
        
        self.dataQuantiles = dataQuantiles
        return dataQuantiles
 
    






    
if __name__ == "__main__":
    pass

