#!/bin/bash

#SBATCH --job-name=prepare_bm25
#SBATCH --output=logs/%x-%A/subtask-%a.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --array=0-3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

srun -W 0 benchmark/scripts/modules/prepare_bm25_job2_step1.sh
