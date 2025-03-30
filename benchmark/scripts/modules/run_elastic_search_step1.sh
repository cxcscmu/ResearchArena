#!/bin/bash

source devconfig.sh
source devsecret.sh

export ES_HOME=$SSD_MOUNT/bin/elasticsearch-8.17.4/
export HOSTNAMES=($(scontrol show hostnames $SLURM_JOB_NODELIST))
export HOSTNAMES=$(IFS=,; echo "${HOSTNAMES[*]}")

$ES_HOME/bin/elasticsearch \
    -Ecluster.name=researcharena \
    -Enode.name=$(hostname) \
    -Enetwork.host=0.0.0.0 \
    -Ediscovery.seed_hosts=$HOSTNAMES \
    -Ecluster.initial_master_nodes=$HOSTNAMES \
    -Epath.data=$SSD_MOUNT/elasticsearch/data_$SLURM_PROCID \
    -Epath.logs=$SSD_MOUNT/elasticsearch/logs_$SLURM_PROCID \
    -Enode.store.allow_mmap=false \
