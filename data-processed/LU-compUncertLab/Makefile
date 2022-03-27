#mcandrew;

PYTHON:=python3 -W ignore

COMMITprefix:=Forecasts generated for LUcompUncertLab-VAR__cumulativepredictions model on
COMMITsuffix:=$(shell date +"%Y-%m-%d")

COMMIT:=$(COMMITprefix) $(COMMITsuffix)

runall: create_location_specific_folder dataprocessed convert_raw_data2weeks buildmodel transformDailyPredictions2Weekly addCumulativeTargets postprocess fromSamples2Quantiles plotTrajectories
.PHONY: runall
#----------------------------------------------------------------------------------------------
checkout_dev:
#  This moves the git repo over to the ludev branch. 	
	git checkout ludev

expert_one_location:
	export LOCATION=42

create_location_specific_folder:
# creates this folder if it does not already exist
	mkdir -p location_specific_forecasts

dataprocessed:
# Update the incident cases, deaths, and hospitalizations to the latest
# QUESTION --- Should we include a script right after here that reports the latest day of data?   
	$(PYTHON) data-processing.py && echo "Generate the three csv files"

convert_raw_data2weeks:
# Convert the threestreams data to weekly
	$(PYTHON) convert_daily_data_2_weekkly_data.py && echo "Transformed data to weekly"

buildmodel:
# This script subsets the above data to a single location and fits a model
# This is the only script we will need to change when we build an additional model
	echo "Building = " ${LOCATION}
	$(PYTHON) build.py --LOCATION ${LOCATION} && echo "model build"

transformDailyPredictions2Weekly:
# This converts daily cases and daily hosps to weekly targets
	echo "Transforming Targets = " ${LOCATION}
	$(PYTHON) fromDaily2WeeklyPredictions.py --LOCATION ${LOCATION} && echo "from daily to weekly predictions"

addCumulativeTargets:
# This adds a target that is cumualtive deaths
	echo "Adding cumulative deaths = " ${LOCATION}
	$(PYTHON) addCumulativeTargets.py --LOCATION ${LOCATION} && echo "Added Cumualative Targets"

postprocess:
# At the moment this scans the CSV file produced by addCumualtiveTargets and cuts any values to 0.
	echo "In POST = " ${LOCATION}
	$(PYTHON) post_process.py --LOCATION ${LOCATION} && echo "Post process complete"

fromSamples2Quantiles:
# This converts the above file that contains samples into quantiles.
	echo "To QUANTILES = " ${LOCATION}
	$(PYTHON) from_post_2_quantiles.py --LOCATION ${LOCATION} && echo "Mapped to quantiles complete"


plotTrajectories:
	echo "PLOT = " ${LOCATION}
	$(PYTHON) plotTrajectories.py --LOCATION ${LOCATION} && echo "Plotted trajectories"

zip:
	gzip -f *.LUcompUncertLab-VAR__cumulativepredictions.csv

#----------------------------------------------------------------------------------------------
# This adds, commit, and pushes the most recent changes. This is a VERY dangerous command.
send: add commit push
.PHONY: send
#----------------------------------------------------------------------------------------------
add:
	git add .

commit:
	git commit -m "$(COMMIT)"

push:
	git push
#----------------------------------------------------------------------------------------------
sync: remote fetch checkout_master merge 
.PHONY: sync
#----------------------------------------------------------------------------------------------
remote:
	git remote add upstream https://github.com/reichlab/covid19-forecast-hub.git

fetch:
	git fetch upstream

checkout_master:
	git checkout master

merge:
	git merge upstream/master # Merge updates to the master branch
#----------------------------------------------------------------------------------------------

