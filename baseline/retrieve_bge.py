import json
import argparse
from pathlib import Path
from collections import defaultdict

import faiss
import numpy as np
from tqdm import tqdm
from vllm import LLM, TokensPrompt

def normalize(vector: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(vector)
    return vector / norm if norm > 0 else vector

def main():
    # Parse the arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--indices-base", type=str, required=True)
    parser.add_argument("--queries-file", type=str, required=True)
    parser.add_argument("--results-file", type=str, required=True)
    parsed = parser.parse_args()

    # Read the queries
    qids, queries = [], []
    with Path(parsed.queries_file).open("r") as fp:
        for line in fp:
            data = json.loads(line)
            qids.append(data["id"])
            queries.append(data["query"])

    # Embed the queries using BGE
    engine = LLM("BAAI/bge-base-en-v1.5")
    tokenizer = engine.get_tokenizer()
    max_length = tokenizer.model_max_length
    tokenized_queries = tokenizer.batch_encode_plus(queries, truncation=True, max_length=max_length)
    tokenized_queries = list(map(lambda x: TokensPrompt(prompt_token_ids=x), tokenized_queries['input_ids']))
    embeded_queries = [normalize(np.array(x.outputs.embedding, dtype=np.float32)) for x in engine.embed(tokenized_queries)]

    # Build the index from the document vectors
    index = faiss.IndexFlatL2(768)
    auxil = faiss.IndexIDMap(index)
    for file in tqdm(
        list(Path(parsed.indices_base).glob("*.npz")),
        desc="Building the index", mininterval=3, ncols=120,
    ):
        data = np.load(file)
        ids, vectors = data["ids"], data["vectors"]
        auxil.add_with_ids(normalize(vectors.astype(np.float32)), ids.astype(np.int64))

    # Load the index into GPU and run the search
    auxil = faiss.index_cpu_to_all_gpus(auxil)
    batch_size, results = 512, defaultdict(list)
    for i in tqdm(
        range(0, len(embeded_queries), batch_size),
        desc="Searching the index", mininterval=3, ncols=120,
    ):
        batch_qids = qids[i:i + batch_size]
        batch_queries = embeded_queries[i:i + batch_size]
        D, I = auxil.search(np.array(batch_queries, dtype=np.float32), k=100)
        for qid, distances, indices in zip(batch_qids, D, I):
            for dist, idx in zip(distances, indices):
                results[qid].append((qid, idx, dist))

    # A topic may have multiple queries, which requires merging results
    for qid, entries in results.items():
        entries.sort(key=lambda x: x[2])

    # Write the results to the output file in TREC format
    with Path(parsed.results_file).open("w") as fp:
        for qid, entries in results.items():
            seen = set()
            for rank, (qid, idx, dist) in enumerate(entries, start=1):
                if idx in seen: continue
                if len(seen) >= 100: break
                sim = 1.0 / (1.0 + dist)
                fp.write(f"{qid} Q0 {idx} {rank} {sim} bge\n")
                seen.add(idx)

if __name__ == "__main__":
    main()
