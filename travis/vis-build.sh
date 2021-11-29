#!/usr/bin/env bash

set -e

setup_git() {
  git config --global user.email "git@github.com"
  git config --global user.name "Github Actions CI"
}

commit_website_files() {
  echo "Commiting files..."
  git add .
  git commit --message "Build local visualization: $GITHUB_RUN_NUMBER"
}

upload_files() {
  echo "Uploading files..."
  git pull --rebase https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git
  git push https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git HEAD:master
  echo "pushed to github"
}

# Script for building 
echo "> Building visualization"
npm run build-viz-linux
setup_git
commit_website_files
upload_files


