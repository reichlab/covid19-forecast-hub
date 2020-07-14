#!/usr/bin/env python
# coding: utf-8

import pickle
import json
from pathlib import Path

p = pickle.load(open(Path(__file__).parent.resolve()/'validated_file_db.p', 'rb'))
json.dump(p, open(Path(__file__).parent.resolve() /'validated_file_db.json', 'w'))


