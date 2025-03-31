#!/bin/bash

job1_id=$(sbatch benchmark/scripts/modules/retrieve_bm25_title_job1.sh | awk '{print $4}')
job2_id=$(sbatch --dependency=afterok:$job1_id benchmark/scripts/modules/retrieve_bm25_title_job2.sh | awk '{print $4}')
echo "Submitted jobs: $job1_id, $job2_id"
