# Overview

## Quickstart

```bash
conda create -n ResearchArena python=3.10 -y
conda activate ResearchArena
pip install -r requirements.txt
```

```bash
bash benchmark/scripts/download.sh

bash benchmark/scripts/prepare_bge.sh
# If the above is taking a while... you can have more tasks joined dynamically in preempt mode!!!
sbatch --partition=preempt benchmark/scripts/modules/prepare_bge_job2.sh
```
