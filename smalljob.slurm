#!/usr/bin/env bash
####  SBATCH preamble

#SBATCH -J smalljob

#SBATCH --mail-user=$USER@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.slurm.out

#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=7G
#SBATCH --time=40:00:00

#SBATCH --account=kykwan
#SBATCH --partition=standard
#SBATCH --qos=normal

####  End SBATCH preamble
