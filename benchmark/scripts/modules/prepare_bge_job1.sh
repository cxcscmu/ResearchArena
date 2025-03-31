#!/bin/bash

#SBATCH --job-name=prepare_bge
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G

source devconfig.sh
source devsecret.sh

export QUEUE=$NFS_MOUNT/queue/benchmark/prepare_bge

if [ -d $QUEUE ]; then
    exit 0
fi

mkdir -p $QUEUE

find $SSD_MOUNT/dataset/source -type f -name "public_*.jsonl" | while read -r path; do
    stem=$(basename ${path%.jsonl})
    task=$QUEUE/${stem}-title.task
    echo $path >> $task
    echo title >> $task
    echo "Added $task to queue"
done

find $SSD_MOUNT/dataset/source -type f -name "public_*.jsonl" | while read -r path; do
    stem=$(basename ${path%.jsonl})
    task=$QUEUE/${stem}-abstract.task
    echo $path >> $task
    echo abstract >> $task
    echo "Added $task to queue"
done

find $SSD_MOUNT/dataset/source -type f -name "corpus_*.jsonl" | while read -r path; do
    stem=$(basename ${path%.jsonl})
    task=$QUEUE/${stem}-text.task
    echo $path >> $task
    echo text >> $task
    echo "Added $task to queue"
done
