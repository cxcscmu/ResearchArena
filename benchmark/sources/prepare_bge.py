import logging
import argparse
from pathlib import Path

import numpy as np
from vllm import LLM

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--load-file", type=str, required=True)
    parser.add_argument("--read-from", type=str, required=True)
    parser.add_argument("--save-file", type=str, required=True)
    parsed = parser.parse_args()

    load_file = Path(parsed.load_file)
    if load_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are allowed.")

    save_file = Path(parsed.save_file)
    if save_file.suffix != ".npy":
        raise NotImplementedError("Only 'jsonl' files are allowed.")

    engine = LLM("BAAI/bge-base-en-v1.5")

    logging.info(f"Reading the corpus from {load_file}.")
    prompts = list()
    with load_file.open("r") as fp:
        for line in fp:
            data = json.loads(line)
            prompts.append(data[parsed.read_from])

    outputs = engine.embed(prompts)

    embeddings_array = np.vstack([x.outputs.embedding for x in outputs])
    print(embeddings_array)


if __name__ == '__main__':
    main()
