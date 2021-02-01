# Steps to get the deleted forecast files
# Step 0: open terminal at the root directory of the project
# Step 1: git log --diff-filter=D --summary -- "data-processed" > code/misc/file_delete.txt
# Step 2: python code/misc/extract_deletion_information.py

import pandas as pd
from itertools import groupby, chain
from datetime import datetime
import os
from github import Github

# Get the repository object through github API
def get_repo():
    g = Github(os.environ.get("auth_token"))
    covid_repo = g.get_repo("reichlab/covid19-forecast-hub")
    return covid_repo


# Get remaining API limit
def get_api_limit():
    g = Github(os.environ.get("auth_token"))
    return g.get_rate_limit().core.remaining


# Get lines in files that belong to a commit
def get_sections(fle):
    with open(fle,"r", encoding='utf-16') as f:
        grps = groupby(f, key=lambda x: x.lstrip().startswith("commit"))
        for k, v in grps:
            if k:
                yield chain([next(v)], (next(grps)[1]))

# Get all commit numbers belong to the summer migration pull request #720
repo = get_repo()
pr = repo.get_pull(720)
commits = pr.get_commits()
summer_migration_forecast_commits = []
for commit in commits:
    summer_migration_forecast_commits.append(str(commit.sha))

# Get all current existing file names in data-processed folder
existing_files = []
for path, subdirs, files in os.walk("./data-processed/"):
    for name in files:
        if ".csv" in name:
            existing_files.append(name)

deleted_files = pd.DataFrame(columns = ['file_name', 'commit_date', 'commit_link', 'commit_message', 'summer_migration'])
for section in get_sections("code/misc/file_delete.txt"):
    commit_infos = list(section)
    commit_infos = list(filter(('\n').__ne__, commit_infos)) 
    files_in_commit = []

    # Parse information from commit information
    commit_date =  datetime.strptime(' '.join((' '.join(commit_infos[2].strip("\n").split())).split(' ')[2:6]), '%b %d %H:%M:%S %Y').strftime("%m/%d/%y-%H:%M:%S")
    commit_message = ' '.join(commit_infos[3].strip('\n').split())
    commit_link = "https://github.com/reichlab/covid19-forecast-hub/commit/" + str(commit_infos[0].strip('\n').split(' ')[-1])
    commit_number = str(commit_infos[0].strip('\n').split(' ')[-1])
    summer_migration = False
    if commit_number in summer_migration_forecast_commits:
        summer_migration = True

    # Parse each file in the commit as a separate entity in the dataframe
    for info in commit_infos:
        info = ' '.join(info.strip("\n").split())
        if ("delete mode" in info) \
            and ("LICENSE" not in info) \
            and ("metadata" not in info) \
            and (".R" not in info) \
            and (".png" not in info) \
            and (".gitkeep" not in info) \
            and (".log" not in info) \
            and ("lock" not in info) \
            and ("METADATA" not in info) \
            and ("ignore" not in info) \
            and ("METADATA" not in info) \
            and ("truth" not in info) \
            and ("new_data" not in info) \
            and ("COVIDhub-ensemble-information" not in info) \
            and ("dd" not in info) \
            and ("Test" not in info) \
            and ("Imperial-forecast-dates" not in info):
            
            file_name = info.split("/")[-1]
            if file_name not in existing_files:
                files_in_commit.append(file_name)
    for file_in_commit in files_in_commit:
        line_to_add = {}
        line_to_add['file_name'] = file_in_commit
        line_to_add['commit_date'] = commit_date
        line_to_add['commit_link'] = commit_link
        line_to_add['commit_message'] = commit_message
        line_to_add['summer_migration'] = summer_migration
        deleted_files = deleted_files.append(line_to_add, ignore_index=True)
deleted_files.to_csv("code/misc/deleted_forecasts.csv", index = False)