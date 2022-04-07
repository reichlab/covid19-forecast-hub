#!bin/bash

# sbatch -W SLURMrunner_data.sh
echo "crazy bananas"

sub='US'

while read line; do
    echo Sending $line          # MARK progress
    if [[ "$line" == *"$sub"* ]]; then
	    echo and waiting
	    sbatch -W $line SLURMrunner.sh
    else
	    sbatch $line SLURMrunner.sh # SUBMIT JOB
    fi
done < RUNS.csv

echo "Compiling predictions"
sbatch compilePredictions.sh
