#!/usr/bin/env bash

set -e

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"Travis build:"* ]]; then
    echo "This is an auto commit from travis. Not doing anything."
    exit 0
fi


# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`


# Importing necessary python libraries
echo "Updating Dependencies..."
npm install
sudo apt-get install python3-pandas
sudo apt install python3-pip
pip3 install --upgrade setuptools
pip3 install -r visualization/requirements.txt

# Validate the data
source ./travis/validate-data.sh

# Do not run builds on branches outside of master
if [[ "$TRAVIS_BRANCH" != "master" ]]; then
    echo "Not on master. Not doing anything else."
    exit 0
fi

# Update the truth data
if [[ "$TRAVIS_EVENT_TYPE" == *"cron"* || "$TRAVIS_COMMIT_MESSAGE" == *"FORCE_ZOLTAR"* ]]; then
    echo "updating truth data..."
    bash ./travis/update-truth.sh

    echo "Upload truth to Zoltar"
    python3 ./code/zoltar_scripts/upload_truth_to_zoltar.py
    # Upload to zoltar at every merged pull request
    echo "Upload forecasts to Zoltar "
    bash ./travis/upload-to-zoltar.sh

    # Replace the validated_files.csv with locally_validated_files.csv at every build except PRs
    echo "replacing validated files"
    cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

    echo "Merge detected.. push to github"
    bash ./travis/push.sh
fi

# Upload to zoltar at every merged pull request
# if [[ "$TRAVIS_COMMIT_MESSAGE" == *"Merge pull request"* ]]; then
#    echo "Upload forecasts to Zoltar "
#    bash ./travis/upload-to-zoltar.sh
# fi

# Replace the validated_files.csv with locally_validated_files.csv at every build except PRs
# if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
#    echo "replacing validated files"
#    cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

#    echo "Merge detected.. push to github"
#    bash ./travis/push.sh
# fi

## Automatically deploy visualization.
## TODO - This code does not work yet
# if [[ "$TRAVIS_COMMIT_MESSAGE" == *"trigger build"* ]]; then
#     source ./travis/vis-deploy.sh
# fi
#

# Functions below are for testing purposes
if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test truth"* ]]; then
    echo "updating truth data..."
    bash ./travis/update-truth.sh
    echo "Push the truth"
    bash ./travis/push.sh
    echo "Upload truth to Zoltar"
    python3 ./code/zoltar_scripts/upload_truth_to_zoltar.py
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test zoltar upload"* ]]; then
    echo "Upload forecasts to Zoltar"
    bash ./travis/upload-to-zoltar.sh
    echo "Push validated file db to GitHub"
    bash ./travis/push.sh
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test truth zoltar"* ]]; then
    echo "Upload truth to Zoltar"
    python3 ./code/zoltar_scripts/upload_truth_to_zoltar.py
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"create zoltar validated file"* ]]; then
    echo "Create new validated zoltar forecast list"
    bash ./travis/create-validated-file-db.sh
    echo "Push the validated file db to Zoltar"
    bash ./travis/push.sh
fi