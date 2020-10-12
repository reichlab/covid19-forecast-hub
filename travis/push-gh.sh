#!/bin/sh

setup_git() {
  git config --global user.email "git@github.com"
  git config --global user.name "Github Actions CI"
}

commit_website_files() {
  echo "Commiting files..."
  git add .
  git commit --message "[skip ci] Github Actions build: $GITHUB_RUN_NUMBER"
}

upload_files() {
  echo "Uploading files..."
  git pull --rebase https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git
  git push https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git HEAD:master
  echo "pushed to github"
}

setup_git
commit_website_files
upload_files
