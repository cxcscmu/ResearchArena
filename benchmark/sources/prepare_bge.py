import json
import logging
import argparse
from pathlib import Path

import numpy as np
from vllm import LLM, TokensPrompt

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--load-file", type=str, required=True)
    parser.add_argument("--read-from", type=str, required=True)
    parser.add_argument("--save-file", type=str, required=True)
    parsed = parser.parse_args()

    load_file = Path(parsed.load_file)
    if load_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are read.")

    save_file = Path(parsed.save_file)
    if save_file.suffix != ".npz":
        raise NotImplementedError("Only 'npz' files are saved.")

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
    batch_size, vectors = 8192, []
    for i in range(0, len(corpus), batch_size):
        corpus_batch = corpus[i:i+batch_size]
        logging.info(f"Processing batch {i}-{i+batch_size} out of {len(corpus)} records...")
        prompts = tokenizer.batch_encode_plus(corpus_batch, truncation=True, max_length=max_length)
        outputs = engine.embed(list(map(lambda x: TokensPrompt(prompt_token_ids=x), prompts['input_ids'])))
        vectors.extend([x.outputs.embedding for x in outputs])

    logging.info(f"Saving the vectors into {save_file}.")
    ids, vectors = np.array(ids), np.array(vectors, dtype=np.float32)
    with save_file.open("wb") as fp:
        np.savez(fp, ids=ids, vectors=vectors)

if __name__ == '__main__':
    main()
