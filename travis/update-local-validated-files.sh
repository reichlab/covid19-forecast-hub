# Replace the validated_files.csv with locally_validated_files.csv at every build except PRs
echo "replacing validated files"
cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

echo "Merge detected.. push to github"
bash ./travis/push-gh.sh