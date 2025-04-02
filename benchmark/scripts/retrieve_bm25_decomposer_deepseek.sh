#!/bin/bash

#SBATCH --job-name=retrieve_bm25_decomposer_deepseek
#SBATCH --output=logs/%x.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

source devconfig.sh
source devsecret.sh

export WORKSPACE=$SSD_MOUNT/benchmark/retrieve_decomposer_deepseek
mkdir -p $WORKSPACE

cd benchmark

# Prepare the queries.
python3 -m sources.retrieve_decomposer_deepseek \
    --surveys-file $SSD_MOUNT/dataset/source/survey.jsonl \
    --replays-file $WORKSPACE/replays.jsonl \
    --queries-file $WORKSPACE/queries.jsonl \
    --records-file $WORKSPACE/records.trec

# # Retrieve from the abstract field.
# python3 -m sources.retrieve_bm25 \
#     --queries-file $WORKSPACE/queries.jsonl \
#     --query-field abstract \
#     --results-file $WORKSPACE/bm25_abstract_results.trec
