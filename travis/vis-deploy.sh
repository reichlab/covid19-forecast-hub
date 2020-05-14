#!/bin/sh

git checkout gh-pages
git fetch origin master
git checkout origin/master  -- ./visualization/vis-master/dist
cd ./visualization/vis-master
cp -r ./dist/* ../../

git add .
git commit -m "Auto Build Visualization"
git push