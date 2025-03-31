#!/bin/bash

#SBATCH --job-name=elasticsearch
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --nodes=4
#SBATCH --cpus-per-task=64
#SBATCH --mem=512G

srun -W 0 benchmark/scripts/modules/run_elasticsearch_step1.sh
