#!bin/bash

while read line; do
    echo Sending $line          # MARK progress
    sbatch $line SLURMrunner.sh # SUBMIT JOB
done < RUNS.csv
