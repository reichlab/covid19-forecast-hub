#mcandrew

from interface import interface
import argparse

def fromSamples2Quantiles(dataPredictions):

    def createQuantiles(x):
        import numpy as np
        import pandas as pd

        quantiles = np.array([0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500
                              ,0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990])
        quantileValues = np.percentile( x["value"], q=100*quantiles)     
        return pd.DataFrame({"quantile":list(quantiles),"value":list(quantileValues)})

    dataQuantiles = dataPredictions.groupby(["forecast_date"
                                                  ,"target_end_date"
                                                  ,"location","target"]).apply(lambda x:createQuantiles(x)).reset_index().drop(columns="level_4")
    dataQuantiles["type"] = "quantile"
    return dataQuantiles

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--LOCATION')

    args = parser.parse_args()

    LOCATION = args.LOCATION

    io = interface(0,LOCATION)
        
    io.grab_post_process_predictions()

    quantiles = fromSamples2Quantiles(io.predictions)

    day = io.getForecastDate()
    quantiles.to_csv("./location_specific_forecasts/{:s}_LUcompUncertLab-VAR3Streams_FINAL__{:s}.csv.gz".format(day,io.fmtlocation)
                              ,header=True
                              ,index=False
                              ,mode="w"
                              ,compression="gzip")
