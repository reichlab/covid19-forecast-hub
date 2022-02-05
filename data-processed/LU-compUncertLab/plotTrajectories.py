#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface
from visualize import viz

if __name__ == "__main__":

    #PREPARE DATA
    io = interface(0)
    quantiles = io.grab_recent_forecast_file()

    for state, quants in quantiles.groupby(["location"]):
        io = interface(0)
        io.subset2locations([str(state)])

        visual = viz(quants,io.data,state)
        visual.forecastVizLOCS()
