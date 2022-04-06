#!bin/bash

sbatch -W SLURMrunner_data.sh
echo "crazy bananas"

while read line; do
    echo Sending $line          # MARK progress
    sbatch $line SLURMrunner.sh # SUBMIT JOB
done < RUNS.csv
