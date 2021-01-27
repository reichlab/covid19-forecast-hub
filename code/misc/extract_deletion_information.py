import pandas as pd
from itertools import groupby, chain
from datetime import datetime

def get_sections(fle):
    with open("file_delete.txt","r", encoding='utf-16') as f:
        grps = groupby(f, key=lambda x: x.lstrip().startswith("commit"))
        for k, v in grps:
            if k:
                yield chain([next(v)], (next(grps)[1]))

deleted_files = pd.DataFrame(columns = ['file_name', 'commit_date', 'commit_link', 'commit_message'])
for section in get_sections("file_delete.txt"):
    commit_infos = list(section)
    commit_infos = list(filter(('\n').__ne__, commit_infos)) 
    files_in_commit = []
    commit_date =  datetime.strptime(' '.join((' '.join(commit_infos[2].strip("\n").split())).split(' ')[2:6]), '%b %d %H:%M:%S %Y').strftime("%m/%d/%y-%H:%M:%S")
    commit_message = ' '.join(commit_infos[3].strip('\n').split())
    commit_link = "https://github.com/reichlab/covid19-forecast-hub/commit/" + str(commit_infos[0].strip('\n').split(' ')[-1])
    for info in commit_infos:
        info = ' '.join(info.strip("\n").split())
        if "delete mode" in info:
            files_in_commit.append(info.split("data-processed/")[-1])
    for file_in_commit in files_in_commit:
        line_to_add = {}
        line_to_add['file_name'] = file_in_commit
        line_to_add['commit_date'] = commit_date
        line_to_add['commit_link'] = commit_link
        line_to_add['commit_message'] = commit_message
        deleted_files = deleted_files.append(line_to_add, ignore_index=True)
deleted_files.to_csv("deleted_forecasts.csv", index = False)