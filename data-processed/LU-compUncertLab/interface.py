#mcandrew

class interface(object):
    def __init__(self,data=None):
        import pandas as pd
        
        if data is None:
            pass
        else:
            self.data          = pd.read_csv("threestreams.csv.gz")
            self.centered_data = pd.read_csv("centered_std_threestreams.csv.gz")
            self.running_means = pd.read_csv("running_mean_threestreams.csv.gz")
            self.stds          = pd.read_csv("stds.csv.gz")

            self.locations     = sorted(self.data.location.unique())
            
        self.buildDataForModel()
        self.getForecastDate()
        self.generateTargetEndDays()
        self.generateTargetNames()

        self.numOfForecasts = 28 # FOR NOW THIS IS HARDCODED AS a 28 day ahead AHEAD

    def subset2locations(self,locations):

        def subset(d):
            return d.loc[d.location.isin(locations)]

        self.data          = subset(self.data)
        self.centered_data = subset(self.centered_data)
        self.running_means  = subset(self.running_means)

        self.locations = locations 

        self.buildDataForModel()
        
    def buildDataForModel(self):
        import numpy as np
        
        #y = np.array(self.centered_data.drop(columns=["location","location_name"]).set_index("date"))
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

    def generateTargetEndDays(self):
        import numpy as np
        import datetime
        import pandas as pd

        start = pd.to_datetime(self.thisWeek.enddate())
        
        target_end_days = []
        for f in np.arange(1,28+1): # four days ahead
            ted = (start+np.timedelta64(f,"D")).strftime("%Y-%m-%d")
            target_end_days.append(ted)
        self.target_end_days = target_end_days
        return target_end_days
    
    def generateTargetNames(self):
        import numpy as np

        # first target is always cases, second deaths, and third hosps.
        targets = []
        trgts = ["case","death","hosp"]
        for trgt in trgts:
            targets.append(["{:d} day ahead inc covid {:s}".format(ahead,trgt) for ahead in np.arange(1,28+1)])

        self.targets = targets
        return targets

    #----------processing model samples
    def formatSamples(self,model):
        import numpy as np
        import pandas as pd
        
        dataPredictions = {"forecast_date":[]
                           ,"target_end_date":[]
                           ,"location":[], "target":[],"sample":[],"value":[]}
        predictions = model.fit["ytilde"][:,-model.F:,:] # this is coming from the model object

        F = self.numOfForecasts
        for sample,forecasts in enumerate(np.moveaxis(predictions,2,0)):
            
            for n,forecast in enumerate(forecasts):
                dataPredictions["forecast_date"].extend(F*[self.forecast_date])
                dataPredictions["location"].extend( F*[self.locations[0]] )
                dataPredictions["target_end_date"].extend( self.target_end_days )
                dataPredictions["target"].extend( self.targets[n] )
                dataPredictions["sample"].extend( F*[sample] )
                dataPredictions["value"].extend( forecast )
        dataPredictions = pd.DataFrame(dataPredictions)

        self.dataPredictions = dataPredictions
        return dataPredictions

    def un_center(self):
        stds = self.transform_stds_long()
        running_means = self.transform_running_means_long()

        predictions = self.dataPredictions

        # create a fake target
        def fromtarget2T(x):
            if "case" in x:
                return "cases"
            elif "hosp" in x:
                return "hosps"
            else:
                return "deaths"
        predictions["T"] = [ fromtarget2T(_) for _ in predictions.target]

        key = ["location","T"]
        predictions = predictions.merge( stds, on = key )
        predictions = predictions.merge(running_means, on = key)

        predictions = predictions.drop(columns=["T"])

        predictions.value = predictions["value"]*predictions["std"] + predictions["mean"]
        self.dataPredictions = predictions

    def fromSamples2Quantiles(self):
        
        def createQuantiles(x):
            import numpy as np
            import pandas as pd

            quantiles = np.array([0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500
                                  ,0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990])
            quantileValues = np.percentile( x["value"], q=100*quantiles)     
            return pd.DataFrame({"quantile":list(quantiles),"value":list(quantileValues)})

        dataQuantiles = self.dataPredictions.groupby(["forecast_date"
                                                      ,"target_end_date"
                                                      ,"location","target"]).apply(lambda x:createQuantiles(x)).reset_index().drop(columns="level_4")
        dataQuantiles["type"] = "quantile"
        
        self.dataQuantiles = dataQuantiles
        return dataQuantiles

    def writeout(self,n):
        if n:
            self.dataQuantiles.to_csv("{:s}_LUcompUncertLab-VAR.csv".format(self.forecast_date),header=False,index=False,mode="a")
        else:
            self.dataQuantiles.to_csv("{:s}_LUcompUncertLab-VAR.csv".format(self.forecast_date),header=True,index=False,mode="w")

    def writeout_predictions(self,n):
        if n:
            self.dataPredictions.to_csv("{:s}_LUcompUncertLab-VAR__predictions.csv.gz".format(self.forecast_date),header=False,index=False,mode="a",compression="gzip")
        else:
            self.dataPredictions.to_csv("{:s}_LUcompUncertLab-VAR__predictions.csv.gz".format(self.forecast_date),header=True,index=False,mode="w",compression="gzip")

            
    # post processing help
    def grab_recent_forecast_file(self):
        import pandas as pd
        return pd.read_csv("{:s}_LUcompUncertLab-VAR.csv".format(self.forecast_date))

    def transform_stds_long(self):
        stds = self.stds
        stds = stds.drop(columns = ["location_name"]).sort_values("date")
        stds = stds.groupby(["location"]).apply(lambda x: x.iloc[-1]).drop(columns=["date"])

        stds_long = stds.melt(id_vars = ["location"]).rename(columns={"variable":"T","value":"std"})
        
        return stds_long

    def transform_running_means_long(self):
        running_means = self.running_means
        running_means = running_means.drop(columns = ["location_name"]).sort_values("date")
        running_means = running_means.groupby(["location"]).apply(lambda x: x.iloc[-1]).drop(columns=["date"])

        running_means.index = running_means.index.rename("T")
        running_means.columns = running_means.columns.rename("T")
        
        running_means_long = running_means.melt(id_vars = ["location"]).rename(columns={"variable":"T","value":"mean"})
        
        return running_means_long

    def grab_recent_predictions(self):
        from glob import glob
        import pandas as pd
        predictionfiles = sorted(glob("*predictions.csv.gz"))

        self.predictions = pd.read_csv(predictionfiles[-1])
        return self.predictions
   
if __name__ == "__main__":
    pass

