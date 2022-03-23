#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface
from epiweeks import Week

if __name__ == "__main__":
   
    io = interface(0,location = 1)

    data = io.data
    
    unique_dates = data.date.unique()

    fromDate2EW = { "date":[], "start_date":[], "end_date":[], "EW":[] }
    for date in unique_dates:
        fromDate2EW["date"].append(date)

        dt = pd.to_datetime(date)
        week = Week.fromdate(dt)

        startdate = week.startdate()
        fromDate2EW["start_date"].append( startdate )

        enddate = week.enddate()
        fromDate2EW["end_date"].append( enddate )

        fromDate2EW["EW"].append( week.cdcformat() )
    fromDate2EW = pd.DataFrame(fromDate2EW)

    data = data.merge(fromDate2EW, on = ["date"])

    def aggregate(x):
        cases =  x.cases.sum()
        hosps =  x.hosps.sum() 
        deaths = x.deaths.sum()

        return pd.Series({"cases":cases,"deaths":deaths,"hosps":hosps})
        
    weekly_date = data.groupby( ["location", "location_name", "start_date", "end_date", "EW"]).apply(aggregate)
    weekly_date = weekly_date.reset_index()

    weekly_date.to_csv("threestreams__weekly.csv.gz", compression = "gzip")
