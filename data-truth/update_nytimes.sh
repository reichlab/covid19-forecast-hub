#!/bin/bash

git checkout master
git pull

Rscript data-truth/nytimes/nytimes.R

git add data-truth/nytimes/raw/us-counties.csv
git add data-truth/nytimes/raw/us-states.csv
git add data-truth/nytimes/raw/us.csv
git add 'data-truth/nytimes/truth_nytimes-Cumulative Cases.csv'
git add 'data-truth/nytimes/truth_nytimes-Cumulative Deaths.csv'
git add 'data-truth/nytimes/truth_nytimes-Incident Cases.csv'
git add 'data-truth/nytimes/truth_nytimes-Incident Deaths.csv'

git commit -m "Update NYTimes truth data"
git push
