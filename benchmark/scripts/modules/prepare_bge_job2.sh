#!/bin/bash

#SBATCH --job-name=prepare_bge
#SBATCH --output=logs/%x-%A/subtask-%a.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --array=0-7
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --gres=gpu:1

srun -W 0 benchmark/scripts/modules/prepare_bge_job2_step1.sh
