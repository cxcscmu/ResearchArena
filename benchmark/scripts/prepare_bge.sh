#!/bin/bash

#SBATCH --job-name=prepare_bge
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G

source devconfig.sh
source devsecret.sh

cd benchmark
python3 -m sources.prepare_bge
