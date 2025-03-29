#!/bin/bash

#SBATCH --job-name=download
#SBATCH --output=logs/%x-%A/subtask-%a.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --array=0-3
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

srun benchmark/scripts/modules/download_job2_step1.sh
