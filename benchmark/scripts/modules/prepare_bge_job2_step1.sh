#!/bin/bash

prepare_bge() {
    local task=$1

    # Skip if task file is empty (already processed)
    [ ! -s "$task" ] && return 0

    # Read the parameters from the task file
    local load_file=$(sed -n '1p' $task)
    local read_from=$(sed -n '2p' $task)
    local save_file=$(sed -n '3p' $task)

    # Generate the embedding (max 3 attempts)
    cd benchmark
    for i in {1..3}; do
        echo "Embed $read_from field of $load_file (Attempt $i of 3)"
        mkdir -p $(dirname $save_file)
        CUDA_VISIBLE_DEVICES=$SLURM_PROCID python3 -m sources.prepare_bge \
            --load-file $load_file --read-from $read_from --save-file $save_file && break
        echo "Failed to embed $read_from field of $load_file, retrying..." && sleep 5
        if [ $i -eq 3 ]; then
            echo "ERROR: Failed to embed $read_from field of $load_file after 3 attempts." >&2
            return 1
        fi
    done

    # Mark task as completed
    > $task
}

source devconfig.sh
source devsecret.sh
export QUEUE=$NFS_MOUNT/queue/benchmark/prepare_bge/

export -f prepare_bge
find $QUEUE -type f -name "*.task" | sort | while read -r line; do
    flock -n $line -c "prepare_bge $line" || true
done
