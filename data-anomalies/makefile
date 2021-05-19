# make for data anomaly processing

# Define global variables
# Where covidData is installed: assumes covidData repo is in same directory as covid19-forecast-hub
COVIDDATADIR = ../../covidData/

## weekly process
all: commit plot_data

pull:
	git -C ../ pull origin master --ff-only

## rebuild covidData
coviddata:
	cd $(COVIDDATADIR)code/data-processing; make all

## run scripts for revisions and outliers
make_csvs: pull coviddata
	Rscript create-revisions-csv.R
	Rscript create-outliers-csv.R

commit: make_csvs
	git -C ../ add data-anomalies/revisions-*.csv data-anomalies/outliers-*.csv
	git -C ../ commit -m "adding updated revisions and outlier csv files"
	git -C ../ push origin 

plot_data: make_csvs
	Rscript plot_data_for_review.R

plot_outliers: make_csvs
	Rscript plot_outliers.R

