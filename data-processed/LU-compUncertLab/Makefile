#mcandrew;

PYTHON:=python3 -W ignore

COMMITprefix:=Forecasts generated for LUcompUncertLab-VAR__cumulativepredictions model on
COMMITsuffix:=$(shell date +"%Y-%m-%d")

COMMIT:=$(COMMITprefix) $(COMMITsuffix)

runall: remote fetch checkout merge dataprocessed interface buildmodel generateForecasts postprocess plotTrajectories zip 
.PHONY: runall

remote:
	git remote add upstream git@github.com:computationalUncertaintyLab/covid19-forecast-hub.git

fetch:
	git fetch upstream

checkout:
	git checkout master

merge:
	git merge upstream/master

dataprocessed:
	$(PYTHON) data-processing.py && echo "Generate the three csv files"

interface:
	$(PYTHON) interface.py && echo "data interface built"

buildmodel:
	$(PYTHON) build.py && echo "model build"
	LOCATION = 20

generateForecasts:
	$(PYTHON) accumulate.py && echo "forecasts generated"

postprocess:
	$(PYTHON) post_process.py && echo "Post process complete"

plotTrajectories:
	$(PYTHON) plotTrajectories.py && echo "Plotted trajectories"

add:
	git add .

commit:
	git commit -m "$(COMMIT)"

push:
	git push

zip:
	gzip -f *.LUcompUncertLab-VAR__cumulativepredictions.csv

send: add commit push
.PHONY: send

