#!/bin/bash

export NFS_MOUNT=/home/haok/ResearchArena
export SSD_MOUNT=/data/group_data/cx_group/ResearchArena
find $NFS_MOUNT/queue -type f -name "*.task" -empty -delete

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ResearchArena
