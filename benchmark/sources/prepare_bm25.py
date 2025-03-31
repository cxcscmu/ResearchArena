import os
import json
import logging
import argparse
from pathlib import Path

from elasticsearch import Elasticsearch, helpers

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--load-file", type=str, required=True)
    parser.add_argument("--read-from", type=str, required=True)
    parsed = parser.parse_args()

    load_file = Path(parsed.load_file)
    if load_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are read.")

    logging.info(f"Connecting to Elasticsearch.")
    pool = [Elasticsearch(f"http://{host}:9200") for host in os.getenv("HOSTNAMES").split(",")]
    assert len(pool) > 0, "No Elasticsearch hosts specified."

    logging.info(f"Reading the corpus from {load_file}.")
    ids, corpus = list(), list()
    with load_file.open("r") as fp:
        for line in fp:
            data = json.loads(line)
            if parsed.read_from in data:
                ids.append(data["id"])
                corpus.append(data[parsed.read_from])

    logging.info(f"Preparing the BM25 indexing into {load_file}.")
    batch_size = 512
    for i in range(0, len(corpus), batch_size):
        batch_ids = ids[i:i + batch_size]
        batch_texts = corpus[i:i + batch_size]
        logging.info(f"Processing batch {i}-{i+batch_size} out of {len(corpus)} records...")
        actions = [
            {
                "_index": "papers",
                "_id": doc_id,
                "_source": { parsed.read_from: text }
            }
            for doc_id, text in zip(batch_ids, batch_texts)
        ]
        client = pool[i % len(pool)].options(request_timeout=65536)
        helpers.bulk(client, actions)


if __name__ == "__main__":
    main()
