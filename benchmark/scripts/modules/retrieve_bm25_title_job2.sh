#!/bin/bash

#SBATCH --job-name=retrieve_bm25_title
#SBATCH --output=logs/%x-%A/subtask-%a.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --array=0-3
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

retrieve_bm25_title() {
    local task=$1

    # Skip if task file is empty (already processed)
    [ ! -s "$task" ] && return 0

    # Read the parameters from the task file
    local surveys_file=$(sed -n '1p' $task)
    local queries_file=$(sed -n '2p' $task)
    local records_file=$(sed -n '3p' $task)
    local query_field=$(sed -n '4p' $task)
    local results_file=$(sed -n '5p' $task)

    mkdir -p $(dirname $queries_file)
    mkdir -p $(dirname $records_file)
    mkdir -p $(dirname $results_file)

    # Run the retrieval
    cd benchmark
    python3 -m sources.retrieve_bm25_title \
        --surveys-file $surveys_file --queries-file $queries_file --records-file $records_file
    if [ $? -ne 0 ]; then
        echo "Error: Retrieval failed for task $task"
        exit 1
    fi
    python3 -m sources.retrieve_bm25 \
        --queries-file $queries_file --query-field $query_field --results-file $results_file
    if [ $? -ne 0 ]; then
        echo "Error: Retrieval failed for task $task"
        exit 1
    fi

    # Mark task as completed
    > $task
}

source devconfig.sh
source devsecret.sh
export QUEUE=$NFS_MOUNT/queue/benchmark/retrieve_bm25_title

export -f retrieve_bm25_title
find $QUEUE -type f -name "*.task" | sort | while read -r line; do
    flock -n $line -c "retrieve_bm25_title $line" || true
done
