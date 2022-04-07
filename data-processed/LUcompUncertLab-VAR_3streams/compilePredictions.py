from interface import interface
from glob import glob
import pandas as pd

if __name__ == "__main__":
	io = interface(0)
	final_filename = "{:s}-LUcompUncertLab-VAR_3streams.csv".format(io.forecast_date)

	for n, file in enumerate(glob('./location_specific_forecasts/{:s}_LUcompUncertLab-quantiles*'.format(io.forecast_date))):
		curr = pd.read_csv(file, compression='gzip')
		if n == 0:
			curr.to_csv(final_filename, index=False)
		else:
			curr.to_csv(final_filename, index=False, mode='a', header=False)