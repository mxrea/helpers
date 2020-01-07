#!/usr/bin/env bash
####  SBATCH preamble

#SBATCH -J smalljob

#SBATCH --mail-user=$USER@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.slurm.out

#SBATCH --nodes=1
#SBATCH --cpus-per-task=7
#SBATCH --mem=35G
#SBATCH --time=1-00:00:00

#SBATCH --account=kykwan1
#SBATCH --partition=standard
#SBATCH --qos=normal

####  End SBATCH preamble

while :
do
    for f in /scratch/kykwan_root/kykwan/shared_data/jobs/*.sh; do
        bash "$f" -H > "${f}.out" && mv "$f" "${f}.done" &
    done
    wait
done
