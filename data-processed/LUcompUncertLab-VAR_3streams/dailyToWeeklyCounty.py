#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface
from epiweeks import Week

if __name__ == "__main__":
    io = interface(0, location=1)
    county_data = io.county_data

    unique_dates_c = county_data.date.unique()

    fromDate2EWC = { "date":[], "start_date":[], "end_date":[], "EW":[] }

    for date in unique_dates_c:
        fromDate2EWC["date"].append(date)

        dt = pd.to_datetime(date)
        week = Week.fromdate(dt)

        startdate = week.startdate()
        fromDate2EWC["start_date"].append( startdate )

        enddate = week.enddate()
        fromDate2EWC["end_date"].append( enddate )

        fromDate2EWC["EW"].append( week.cdcformat() )
    fromDate2EWC = pd.DataFrame(fromDate2EWC)

    county_data = county_data.merge(fromDate2EWC, on = ["date"])

    def aggregate(x):
        cases =  x.county_cases.sum()
        hosps =  x.state_hosps.sum() 
        deaths = x.state_deaths.sum()

        return pd.Series({"county_cases":cases,"state_deaths":deaths,"state_hosps":hosps})
    weekly_date = county_data.groupby( ["location", "location_name", "start_date", "end_date", "EW"]).apply(aggregate)
    weekly_date = weekly_date.reset_index()

    weekly_date.to_csv("threestreams__weekly__county.csv.gz", compression = "gzip")