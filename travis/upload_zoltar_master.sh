# Tell bash shell to report errors and exit
set -e

# Re-validate data before uploading
bash ./travis/validate-data.sh

# Populate the validated_files_db.json
# script pulls the source field from zoltar, splits based on separator, first param is key, second param is value. 
# python code/populate_cache.py

# Upload to zoltar at every merged pull request
echo "Upload forecasts to Zoltar "
bash ./travis/upload-to-zoltar.sh

# Replace the validated_files.csv with locally_validated_files.csv at every build except PRs
echo "replacing validated files"
cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

echo "Merge detected.. push to github"
bash ./travis/push-gh.sh