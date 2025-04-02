#!/bin/bash

#SBATCH --time=48:00:00
#SBATCH --job-name=retrieve_bge_decomposer
#SBATCH --output=logs/%x/%j.log

#SBATCH --mem=96G
#SBATCH --cpus-per-task=24
#SBATCH --gres=gpu:A6000:2

source devconfig.sh
source devsecret.sh

##############################################################################
# Decomposer
##############################################################################

echo "Retrieving BGE for decomposer-based queries"

METHOD=retrieve_decomposer_openai
python3 -m baseline.retrieve_bge \
    --indices-base $SSD_MOUNT/dataset/bge-abstract \
    --queries-file $SSD_MOUNT/benchmark/$METHOD/queries.jsonl \
    --results-file $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec
mkdir -p reports/$METHOD/ && trec_eval -m all_trec \
    $SSD_MOUNT/benchmark/$METHOD/records.trec \
    $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec > reports/$METHOD/bge_abstract.log

METHOD=retrieve_decomposer_claude
python3 -m baseline.retrieve_bge \
    --indices-base $SSD_MOUNT/dataset/bge-abstract \
    --queries-file $SSD_MOUNT/benchmark/$METHOD/queries.jsonl \
    --results-file $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec
mkdir -p reports/$METHOD/ && trec_eval -m all_trec \
    $SSD_MOUNT/benchmark/$METHOD/records.trec \
    $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec > reports/$METHOD/bge_abstract.log

METHOD=retrieve_decomposer_deepseek
python3 -m baseline.retrieve_bge \
    --indices-base $SSD_MOUNT/dataset/bge-abstract \
    --queries-file $SSD_MOUNT/benchmark/$METHOD/queries.jsonl \
    --results-file $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec
mkdir -p reports/$METHOD/ && trec_eval -m all_trec \
    $SSD_MOUNT/benchmark/$METHOD/records.trec \
    $SSD_MOUNT/benchmark/$METHOD/bge_abstract_results.trec > reports/$METHOD/bge_abstract.log
