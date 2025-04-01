#!/bin/bash

#SBATCH --job-name=retrieve_bge_zeroshot_openai
#SBATCH --output=logs/%x.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --gres=gpu:1

source devconfig.sh
source devsecret.sh

cd benchmark
export WORKSPACE=$SSD_MOUNT/benchmark/retrieve_zeroshot_openai

# Retrieve from the title field.
python3 -m sources.retrieve_bge \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field title \
    --results-file $WORKSPACE/bge_title_results.trec

# Retrieve from the abstract field.
python3 -m sources.retrieve_bge \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field abstract \
    --results-file $WORKSPACE/bge_abstract_results.trec

# Retrieve from the text field.
python3 -m sources.retrieve_bge \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field text \
    --results-file $WORKSPACE/bge_text_results.trec
