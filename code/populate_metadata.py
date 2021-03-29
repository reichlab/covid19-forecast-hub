import yaml
import json
from pathlib import Path

path = Path('./data-processed/')
files = [f for f in path.glob('**/metadata*')]

metadata = dict()

for f in files:
    with open(f, 'r', encoding="utf8") as stream:
        metadata_temp = yaml.safe_load(stream)
    metadata_temp.update((k, v.replace('  ', ' ')) for k,v in metadata_temp.items() if v)
    metadata[metadata_temp['model_abbr']] = metadata_temp
    
json.dump(metadata, open("metadata.json","w"), indent=4)