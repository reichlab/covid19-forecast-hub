#mcandrew

import sys
import numpy as np
import pandas as pd

from interface import interface

if __name__ == "__main__":
    io = interface(0)
    forecast = io.grab_recent_forecast_file()
    forecast['value'] = forecast['value'].clip(lower=0)