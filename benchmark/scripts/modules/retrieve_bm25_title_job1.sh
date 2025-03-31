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

export QUEUE=$NFS_MOUNT/queue/benchmark/retrieve_bm25_title

if [ -d $QUEUE ]; then
    exit 0
fi

mkdir -p $QUEUE

task=$QUEUE/title.task
echo $SSD_MOUNT/dataset/source/survey.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/title/queries.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/title/records.trec >> $task
echo title >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/title/results.trec >> $task

task=$QUEUE/abstract.task
echo $SSD_MOUNT/dataset/source/survey.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/abstract/queries.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/abstract/records.trec >> $task
echo abstract >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/abstract/results.trec >> $task

task=$QUEUE/text.task
echo $SSD_MOUNT/dataset/source/survey.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/text/queries.jsonl >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/text/records.trec >> $task
echo text >> $task
echo $SSD_MOUNT/benchmark/retrieve_bm25_title/text/results.trec >> $task
