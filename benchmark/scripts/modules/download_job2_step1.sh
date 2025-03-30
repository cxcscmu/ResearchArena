#!/bin/bash

download() {
    local task=$1

    # Skip if task file is empty (already processed)
    [ ! -s "$task" ] && return 0

    # Read the link and the path to save the file
    link=$(sed -n '1p' $task)
    path=$(sed -n '2p' $task)
    mkdir -p $(dirname $path)

    # Download from HuggingFace (max 3 attempts)
    for i in {1..3}; do
        echo "Downloading $link to $path (Attempt $i of 3)"
        wget --quiet --header="Authorization: Bearer $HF_TOKEN" $link -O $path && break
        echo "Failed to download $link, retrying..." && sleep 5
        if [ $i -eq 3 ]; then
            echo "ERROR: Failed to download $link after 3 attempts." >&2
            return 1
        fi
    done

    # Extract the file
    echo "Extracting $path"
    gunzip $path

    # Mark the task as completed
    > $task
}

source devconfig.sh
source devsecret.sh

export -f download
export QUEUE=$NFS_MOUNT/queue/benchmark/download

find $QUEUE -type f -name "*.task" | sort | while read -r line; do
    flock -n $line -c "download $line" || true
done
