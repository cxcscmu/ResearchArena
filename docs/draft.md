# Overview

## Quickstart

```bash
conda create -n ResearchArena python=3.10 -y
conda activate ResearchArena
pip install -r requirements.txt
```

# Prepare

```bash
bash benchmark/scripts/download.sh

bash benchmark/scripts/prepare_bge.sh
# If the above is taking a while... you can have more tasks joined dynamically in preempt mode!!!
sbatch --partition=preempt benchmark/scripts/modules/prepare_bge_job2.sh

sbatch benchmark/scripts/modules/run_elasticsearch.sh
# Please use squeue to find out what nodes the previous job has been dispatched on.
export HOSTNAMES=babel-0-31,babel-8-17,babel-9-7,babel-9-11

# Create the index across multiple shards.
curl -X PUT "http://babel-0-31:9200/papers" -H 'Content-Type: application/json' -d '
{
  "settings": {
    "number_of_shards": 4
  },
  "mappings": {
    "properties": {
      "title":    { "type": "text", "similarity": "BM25" },
      "abstract": { "type": "text", "similarity": "BM25" },
      "text":     { "type": "text", "similarity": "BM25" }
    }
  }
}'

bash benchmark/scripts/prepare_bm25.sh
```
