#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface
from visualize import viz

import argparse

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--LOCATION', type=int)

    args = parser.parse_args()

    LOCATION = args.LOCATION
    
    #PREPARE DATA
    io = interface(0,LOCATION)
    quantiles = io.grab_recent_quantiles()

    io.include_weekly_data()
    io.weeklydata = io.weeklydata.loc[io.weeklydata.location==LOCATION]
    
    io.subset2location()

    visual = viz(quantiles,io.data,io.weeklydata, LOCATION)
    visual.forecastVizLOCS()
