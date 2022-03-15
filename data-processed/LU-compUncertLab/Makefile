#mcandrew;

PYTHON:=python3 -W ignore

COMMITprefix:=Forecasts generated for LUcompUncertLab-VAR__cumulativepredictions model on
COMMITsuffix:=$(shell date +"%Y-%m-%d")

COMMIT:=$(COMMITprefix) $(COMMITsuffix)

runall: checkout_dev dataprocessed buildmodel transformDailyPredictions2Weekly # postprocess plotTrajectories
.PHONY: runall
#----------------------------------------------------------------------------------------------
checkout_dev:
	git checkout ludev

dataprocessed:
	$(PYTHON) data-processing.py && echo "Generate the three csv files"

buildmodel:
	$(PYTHON) build.py --LOCATION 20 && echo "model build"

transformDailyPredictions2Weekly:
	$(PYTHON) fromDaily2WeeklyPredictions.py && echo "from daily to weekly predictions"

postprocess:
	$(PYTHON) post_process.py && echo "Post process complete"

plotTrajectories:
	$(PYTHON) plotTrajectories.py && echo "Plotted trajectories"

zip:
	gzip -f *.LUcompUncertLab-VAR__cumulativepredictions.csv
#----------------------------------------------------------------------------------------------
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
sync: remote fetch checkout merge 
.PHONY: sync
#----------------------------------------------------------------------------------------------
remote:
	git remote add upstream https://github.com/reichlab/covid19-forecast-hub.git

fetch:
	git fetch upstream

checkout:
	git checkout master

merge:
	git merge upstream/master # Merge updates to the master branch
#----------------------------------------------------------------------------------------------

