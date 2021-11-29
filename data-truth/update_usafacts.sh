#!/bin/bash

git checkout master
git pull

Rscript data-truth/usafacts/usafacts.R

git add data-truth/usafacts/raw/covid_confirmed_usafacts.csv
git add data-truth/usafacts/raw/covid_deaths_usafacts.csv
git add 'data-truth/usafacts/truth_usafacts-Cumulative Cases.csv'
git add 'data-truth/usafacts/truth_usafacts-Cumulative Deaths.csv'
git add 'data-truth/usafacts/truth_usafacts-Incident Cases.csv'
git add 'data-truth/usafacts/truth_usafacts-Incident Deaths.csv'

git commit -m "Update USAFacts truth data"
git push
