import csv
import numpy as np
import pandas as pd

if __name__ == "__main__":
	locs = cases.location.astype(str).unique()
	f = open("RUNS.csv", "w")
	for l in locs:
		f.write("--export=ALL,LOCATION={:s}\n".format(l))
	f.close()