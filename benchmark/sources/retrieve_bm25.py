import os
import json
import logging
import argparse
from pathlib import Path

from elasticsearch import Elasticsearch

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--queries-file", type=str, required=True)
    parser.add_argument("--query-field", type=str, required=True)
    parser.add_argument("--results-file", type=str, required=True)
    parsed = parser.parse_args()

    queries_file = Path(parsed.queries_file)
    if queries_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are read.")
    results_file = Path(parsed.results_file)
    if results_file.suffix != ".trec":
        raise NotImplementedError("Only 'trec' files are written.")

    logging.info(f"Connecting to Elasticsearch.")
    pool = [Elasticsearch(f"http://{host}:9200") for host in os.getenv("HOSTNAMES").split(",")]
    assert len(pool) > 0, "No Elasticsearch hosts specified."

    logging.info(f"Reading the queries from {queries_file}.")
    ids, queries = list(), list()
    with queries_file.open("r") as fp:
        for line in fp:
            data = json.loads(line)
            if "query" in data:
                ids.append(data["id"])
                queries.append(data["query"])

    logging.info(f"Retrieving the references via BM25.")
    batch_size, j, results = 8, 0, list()
    for i in range(0, len(queries), batch_size):
        batch_ids = ids[i:i + batch_size]
        batch_texts = queries[i:i + batch_size]
        logging.info(f"Processing batch {i}-{i+batch_size} out of {len(queries)} records...")

        batch_requests = []
        for text in batch_texts:
            batch_requests.append({ "index": "papers" })
            batch_requests.append({
                "size": 100,
                "_source": False,
                "query": {
                    "match": {
                        parsed.query_field: text
                    }
                }
            })
        client = pool[(j := j + 1) % len(pool)].options(request_timeout=65536)
        response = client.msearch(body=batch_requests)

        # parse the response into trec_eval format
        for qid, res in zip(batch_ids, response["responses"]):
            if "hits" not in res or "hits" not in res["hits"]:
                logging.warning(f"No hits found for query ID {qid}. Response: {res}")
                continue
            for rank, hit in enumerate(res["hits"]["hits"]):
                results.append(
                    "{qid} Q0 {docno} {rank} {sim} {run_id}".format(
                        qid=qid,
                        docno=hit["_id"],
                        rank=rank + 1,
                        sim=hit["_score"],
                        run_id=f"bm25-{parsed.query_field}"
                    )
                )

    logging.info(f"Writing the results to {parsed.results_file}.")
    with results_file.open("w") as fp:
        for res in results:
            fp.write(res + "\n")

if __name__ == "__main__":
    main()
