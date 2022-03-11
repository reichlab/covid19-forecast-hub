#mcandrew

from interface import interface
from model import VAR
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--LOCATION', type=str)
    args = parser.parse_args()
    location = args.LOCATION
    io = interface(0)
    
    print(location)
    io = interface(0)
        
    io.subset2locations([location])

    forecast_model = VAR(io.modeldata)
    forecast_model.fit()

    io.formatSamples( forecast_model)
    io.un_center() # multipy by std and add back running mean

    io.fromSamples2Quantiles()

    io.writeout(n)

