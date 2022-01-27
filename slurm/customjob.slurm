#!/usr/bin/env bash
####  SBATCH preamble

#SBATCH -J customjob

#SBATCH --mail-user=$USER@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.slurm.out

#SBATCH --nodes=1
#SBATCH --cpus-per-task=${CPUS}
#SBATCH --mem=${MEM}G
#SBATCH --time=${TIME}:00:00

#SBATCH --account=kykwan0
#SBATCH --partition=standard
#SBATCH --qos=normal

####  End SBATCH preamble

${COMMAND}
