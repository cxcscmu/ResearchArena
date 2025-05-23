#!/bin/bash

#SBATCH --job-name=prepare_bm25
#SBATCH --output=logs/%x-%A/subtask-%a.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --array=0-7
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

srun -W 0 benchmark/scripts/modules/prepare_bm25_job2_step1.sh
