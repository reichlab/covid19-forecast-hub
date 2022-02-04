#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface
from model import VAR

if __name__ == "__main__":

    io = interface(0)
    for n,location in enumerate(io.locations):

        io = interface(0)
        io.subset2locations([location])

        runningmeans = io.data.rolling(window=7).mean().replace(np.nan,0)

        d = io.data.set_index(["location","location_name","date"]).loc[:,["cases","deaths","hosps"]]
        centered_data = d - runningmeans.values

        # format running mean to output. Running mean is missing location and date info
        d = d.reset_index()
        runningmeans = runningmeans.reset_index()
        runningmeans["location"]      = d.location
        runningmeans["location_name"] = d.location_name
        runningmeans["date"]          = d.date

        stds = centered_data.std()
        centered_std = centered_data / stds
        centered_std = centered_std.reset_index()

        stds = pd.DataFrame({"cases":[stds.cases],"deaths":[stds.deaths],"hosps":[stds.hosps]
                             ,"location":[d.location.iloc[0]]
                             ,"location_name":[d.location_name.iloc[0]]
                             ,"date":[d.date.iloc[-1]]})
        
        if n:
            centered_data.to_csv("centered_threestreams.csv.gz",compression="gzip",index=True,mode="a",header=False)

            runningmeans.to_csv("running_mean_threestreams.csv.gz"
                                ,compression="gzip",mode="a",header=False,index=False)

            centered_std.to_csv("centered_std_threestreams.csv.gz"
                                ,compression="gzip",mode="a",header=False,index=False)

            stds.to_csv("stds.csv.gz",compression="gzip",mode="a",header=False,index=False)
        else:
            centered_data.to_csv("centered_threestreams.csv.gz",compression="gzip",index=True,mode="w",header=True)

            runningmeans.to_csv("running_mean_threestreams.csv.gz"
                                ,compression="gzip",mode="w",header=True,index=False)
            
            centered_std.to_csv("centered_std_threestreams.csv.gz"
                                ,compression="gzip",mode="w",header=True,index=False)

            stds.to_csv("stds.csv.gz",compression="gzip",mode="w",header=True,index=False)
