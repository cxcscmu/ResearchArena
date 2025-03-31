#!/bin/bash

#SBATCH --job-name=retrieve_bm25_zeroshot_openai
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

source devconfig.sh
source devsecret.sh

export WORKSPACE=$SSD_MOUNT/benchmark/retrieve_zeroshot_openai
mkdir -p $WORKSPACE/bm25_title $WORKSPACE/bm25_abstract $WORKSPACE/bm25_text

cd benchmark

#Prepare the queries.
python3 -m sources.retrieve_zeroshot_openai \
    --surveys-file $SSD_MOUNT/dataset/source/survey.jsonl \
    --queries-file $WORKSPACE/queries.jsonl \
    --records-file $WORKSPACE/records.trec

# Retrieve from the title field.
python3 -m sources.retrieve_bm25 \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field title \
    --results-file $WORKSPACE/bm25_title_results.trec

# Retrieve from the abstract field.
python3 -m sources.retrieve_bm25 \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field abstract \
    --results-file $WORKSPACE/bm25_abstract_results.trec

# Retrieve from the text field.
python3 -m sources.retrieve_bm25 \
    --queries-file $WORKSPACE/queries.jsonl \
    --query-field text \
    --results-file $WORKSPACE/bm25_text_results.trec
