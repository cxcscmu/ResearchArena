#!/bin/bash

#SBATCH --job-name=download
#SBATCH --output=logs/%x-%j.log
#SBATCH --time=2-00:00:00
#SBATCH --partition=general

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G

source devconfig.sh
source devsecret.sh

export QUEUE=$NFS_MOUNT/queue/benchmark/download

if [ -d $QUEUE ]; then
    exit 0
fi

mkdir -p $QUEUE

files=(
    corpus_019b4979.jsonl.gz
    corpus_0be9cc19.jsonl.gz
    corpus_0e3a02fe.jsonl.gz
    corpus_0e984d82.jsonl.gz
    corpus_137aa169.jsonl.gz
    corpus_148332d2.jsonl.gz
    corpus_19ea3317.jsonl.gz
    corpus_1c56411e.jsonl.gz
    corpus_1c5952ce.jsonl.gz
    corpus_1e0b04b1.jsonl.gz
    corpus_1f633857.jsonl.gz
    corpus_2065f23c.jsonl.gz
    corpus_21742a0a.jsonl.gz
    corpus_21e5e6b9.jsonl.gz
    corpus_3a08a1b6.jsonl.gz
    corpus_3c4026e4.jsonl.gz
    corpus_41a20780.jsonl.gz
    corpus_4268e8f4.jsonl.gz
    corpus_4406304f.jsonl.gz
    corpus_46908973.jsonl.gz
    corpus_54fd518f.jsonl.gz
    corpus_566118e5.jsonl.gz
    corpus_5acd7389.jsonl.gz
    corpus_5da3ee65.jsonl.gz
    corpus_64ab4792.jsonl.gz
    corpus_66463394.jsonl.gz
    corpus_6bfa9e49.jsonl.gz
    corpus_742d37a7.jsonl.gz
    corpus_75f4bdf1.jsonl.gz
    corpus_7c589ff8.jsonl.gz
    corpus_842fd995.jsonl.gz
    corpus_868da052.jsonl.gz
    corpus_87eca8b9.jsonl.gz
    corpus_8b43f30f.jsonl.gz
    corpus_8f3dcd3c.jsonl.gz
    corpus_926005ce.jsonl.gz
    corpus_9ca6bd9a.jsonl.gz
    corpus_9ddf8276.jsonl.gz
    corpus_9fdf787f.jsonl.gz
    corpus_9ff7b468.jsonl.gz
    corpus_a05219e9.jsonl.gz
    corpus_a5fe6527.jsonl.gz
    corpus_a7ba9537.jsonl.gz
    corpus_a9972753.jsonl.gz
    corpus_a9bf7fbb.jsonl.gz
    corpus_ac3e0e5a.jsonl.gz
    corpus_ad36856c.jsonl.gz
    corpus_afd79522.jsonl.gz
    corpus_b7dcea6d.jsonl.gz
    corpus_bc29e01c.jsonl.gz
    corpus_cb16c39a.jsonl.gz
    corpus_cbfbc1d8.jsonl.gz
    corpus_cdaaa3af.jsonl.gz
    corpus_d131183e.jsonl.gz
    corpus_d34ed360.jsonl.gz
    corpus_d5ae639c.jsonl.gz
    corpus_d931fd29.jsonl.gz
    corpus_dcdabf4d.jsonl.gz
    corpus_de02a0b7.jsonl.gz
    corpus_e25d905c.jsonl.gz
    corpus_e6a3c3b4.jsonl.gz
    corpus_faf30028.jsonl.gz
    corpus_fc999713.jsonl.gz
    corpus_ff6fb700.jsonl.gz
    public_00.jsonl.gz
    public_01.jsonl.gz
    public_02.jsonl.gz
    public_03.jsonl.gz
    survey.jsonl.gz
)

for file in ${files[@]}; do
    task=$QUEUE/$file.task
    echo https://huggingface.co/datasets/haok1402/ResearchArena/resolve/main/$file >> $task
    echo $SSD_MOUNT/dataset/source/$file >> $task
    echo "Added $file to the queue."
done
