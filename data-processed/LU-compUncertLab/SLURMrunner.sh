#!/bin/bash

#SBATCH --partition=health,lts,hawkcpu,infolab,engi,eng
 
# Request 1 hour of computing time
#SBATCH --time=3:00:00
#SBATCH --ntasks=1
 
# Give a name to your job to aid in monitoring
#SBATCH --job-name covidForecasting
 
# Write Standard Output and Error
#SBATCH --output="myjob.%j.%N.out"
 
cd ${SLURM_SUBMIT_DIR} # cd to directory where you submitted the job
 
# launch job
module load anaconda3
module load conda/biostats
export PYTHONPATH=$PYTHONPATH:$HOME/pythonpkgs
export LOCATION=${LOCATION}
make
 
exit
