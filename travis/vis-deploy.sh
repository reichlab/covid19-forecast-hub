#!/bin/sh
setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

push_to_gh_pages() {
  git checkout --track gh-pages 
  git fetch origin master
  git checkout origin/master  -- ./visualization/vis-master/dist
  cd ./visualization/vis-master
  cp -r ./dist/* ../../
  git add .
  git commit -m "Auto Build Visualization"
  git push https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git gh-pages
}

setup_git
push_to_gh_pages

