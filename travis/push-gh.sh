#!/bin/sh

setup_git() {
  git config --global user.email "git@github.com"
  git config --global user.name "Github Actions CI"
}

commit_website_files() {
  echo "Commiting files..."
  git add .
  git commit --message "Travis build: $GITHUB_RUN_NUMBER"
}

upload_files() {
  echo "Uploading files..."
  git remote add origin-pages https://${GH_TOKEN}@github.com/reichlab/covid19-forecast-hub.git > /dev/null 2>&1
  git branch --set-upstream-to origin-pages HEAD:master
  git pull --rebase
  git push HEAD:master
  echo "pushed to github"
}

setup_git
commit_website_files
upload_files
