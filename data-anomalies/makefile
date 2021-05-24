# make for data anomaly processing

# Define global variables
# Where covidData is installed: assumes covidData repo is in same directory as covid19-forecast-hub
COVIDDATADIR = ../../covidData/


pull:
	git -C ../ pull origin master --ff-only

## rebuild covidData
coviddata:
	cd $(COVIDDATADIR)code/data-processing; make all

## run scripts for revisions and outliers
revision_csvs: pull coviddata
	Rscript create-revisions-csv.R

commit_revisions: pull
	git -C ../ add data-anomalies/revisions-*.csv
	git -C ../ commit -m "adding updated revision csv files"
	git -C ../ push origin 

## outlier-specific analysis and plotting

## with fresh covidData install, generates plots for review
plot_data_for_review: coviddata
	Rscript plot_data_for_review.R

## once all reviews have been generated, reads them in, and plots for checking
check_outliers: 
	Rscript create-outliers-csv.R
	Rscript plot_outliers.R

commit_outliers:
	git -C ../ add data-anomalies/outliers-*.csv
	git -C ../ commit -m "adding updated outliers csv files"
	git -C ../ push origin 
