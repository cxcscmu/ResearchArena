import os
import json
import logging
import argparse
from pathlib import Path
from typing import List

import numpy as np
from vllm import LLM, TokensPrompt
from elasticsearch import Elasticsearch, helpers

def normalize(vector: List[float]) -> List[float]:
    norm = np.linalg.norm(vector)
    return vector / norm if norm > 0 else vector

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
    corpus, ids = list(), list()
    with load_file.open("r") as fp:
        for line in fp:
            data = json.loads(line)
            if parsed.read_from in data:
                ids.append(data["id"])
                corpus.append(data[parsed.read_from])

    logging.info("Loading the dense embedding model.")
    engine = LLM("BAAI/bge-base-en-v1.5")
    tokenizer = engine.get_tokenizer()
    max_length = tokenizer.model_max_length

    logging.info("Computing the embeddings.")
    batch_size, j = 1024, 0
    for i in range(0, len(corpus), batch_size):
        batch_ids = ids[i:i + batch_size]
        batch_corpus = corpus[i:i+batch_size]
        logging.info(f"Processing batch {i}-{i+batch_size} out of {len(corpus)} records...")
        prompts = tokenizer.batch_encode_plus(batch_corpus, truncation=True, max_length=max_length)
        outputs = engine.embed(list(map(lambda x: TokensPrompt(prompt_token_ids=x), prompts['input_ids'])))
        batch_vectors = [normalize(x.outputs.embedding) for x in outputs]
        actions = [
            {
                "_index": "papers-semantic",
                "_id": doc_id,
                "_source": { parsed.read_from: vector }
            }
            for doc_id, vector in zip(batch_ids, batch_vectors)
        ]
        client = pool[(j := j + 1) % len(pool)].options(request_timeout=65536)
        helpers.bulk(client, actions)


if __name__ == '__main__':
    main()
