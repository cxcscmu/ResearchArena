#!/bin/bash

#SBATCH --job-name=retrieve_bm25_title
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

source devconfig.sh
source devsecret.sh

cd benchmark

# Prepare the queries.
python3 -m sources.retrieve_bm25_title \
    --surveys-file $SSD_MOUNT/dataset/source/survey.jsonl \
    --queries-file $SSD_MOUNT/benchmark/retrieve_bm25_title/queries.jsonl \
    --records-file $SSD_MOUNT/benchmark/retrieve_bm25_title/title/records.trec

# Retrieve from the title field.
python3 -m sources.retrieve_bm25 \
    --queries-file $SSD_MOUNT/benchmark/retrieve_bm25_title/queries.jsonl \
    --query-field title \
    --results-file $SSD_MOUNT/benchmark/retrieve_bm25_title/title/results.trec

# Retrieve from the abstract field.
python3 -m sources.retrieve_bm25 \
    --queries-file $SSD_MOUNT/benchmark/retrieve_bm25_title/queries.jsonl \
    --query-field abstract \
    --results-file $SSD_MOUNT/benchmark/retrieve_bm25_title/abstract/results.trec

# Retrieve from the title field.
python3 -m sources.retrieve_bm25 \
    --queries-file $SSD_MOUNT/benchmark/retrieve_bm25_title/queries.jsonl \
    --query-field text \
    --results-file $SSD_MOUNT/benchmark/retrieve_bm25_title/text/results.trec
