#!/usr/bin/env bash
####  SBATCH preamble

#SBATCH -J bigjob

#SBATCH --mail-user=$USER@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.slurm.out

#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=80:00:00

# TODO
#SBATCH --account=kykwan
#SBATCH --partition=standard
#SBATCH --qos=normal

####  End SBATCH preamble
