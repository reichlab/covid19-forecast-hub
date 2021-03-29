# Tell bash shell to report errors and exit
set -e

# Re-validate data before uploading
bash ./travis/validate-data.sh

# Upload to zoltar at every merged pull request
echo "Upload forecasts to Zoltar "
bash ./travis/upload-to-zoltar.sh

# Replace the validated_files.csv with locally_validated_files.csv at every build except PRs
echo "replacing validated files"
cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

echo "Update metadata.json"
python code/populate_metadata.py

echo "Merge detected.. push to github"
bash ./travis/push-gh.sh