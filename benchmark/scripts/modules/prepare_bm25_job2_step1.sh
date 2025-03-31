#!/bin/bash

prepare_bm25() {
    local task=$1

    # Skip if task file is empty (already processed)
    [ ! -s "$task" ] && return 0

    # Read the parameters from the task file
    local load_file=$(sed -n '1p' $task)
    local read_from=$(sed -n '2p' $task)

    # Perform BM25 indexing (max 3 attempts)
    cd benchmark
    for i in {1..3}; do
        echo "Indexing $read_from field of $load_file (attempt $i)..."
        python3 -m sources.prepare_bm25 --load-file $load_file --read-from $read_from && break
        echo "Failed to index $read_from field of $load_file, retrying..." && sleep 5
        if [ $i -eq 3 ]; then
            echo "ERROR: Failed to index $read_from field of $load_file after 3 attempts." >&2
            return 1
        fi
    done

    # Mark task as completed
    > $task
}

source devconfig.sh
source devsecret.sh
export QUEUE=$NFS_MOUNT/queue/benchmark/prepare_bm25/

export -f prepare_bm25
find $QUEUE -type f -name "*.task" | sort | while read -r line; do
    flock -n $line -c "prepare_bm25 $line" || true
done
