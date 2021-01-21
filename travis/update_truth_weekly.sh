#!/usr/bin/env bash
# Tell bash shell to report errors and exit
set -e

echo "updating truth data..."
# update truth data
cd ./data-truth

# update zoltar truth
python3 ./zoltar-truth-data.py

# upload daily truth
python3 ./get-truth-data.py

# update nytimes and usa facts
cd ../
echo "updating nytimes truth data..."
python3 ./data-truth/nytimes/nytimes.py

echo "updating usafacts truth data..."
python3 ./data-truth/usafacts/usafacts.py

# push new truths to github
echo "Merge detected.. push to github"
bash ./travis/push-gh.sh
