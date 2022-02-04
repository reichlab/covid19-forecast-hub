#mcandrew

import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from interface import interface
from model import VAR

if __name__ == "__main__":

    io = interface(0)
    
    for location in io.locations:
        io.subset2locations([location])
        
        forecast_model = VAR(io.modeldata)
        forecast_model.fit()

        io.formatSamples()
        io.fromSamples2Quantiles()
