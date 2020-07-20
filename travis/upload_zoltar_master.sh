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
bash ./travis/push-gh.sh