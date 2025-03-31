import json
import logging
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--surveys-file", type=str, required=True)
    parser.add_argument("--queries-file", type=str, required=True)
    parser.add_argument("--records-file", type=str, required=True)
    parsed = parser.parse_args()

    surveys_file = Path(parsed.surveys_file)
    if surveys_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are read.")
    queries_file = Path(parsed.queries_file)
    if queries_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are written.")
    records_file = Path(parsed.records_file)
    if records_file.suffix != ".trec":
        raise NotImplementedError("Only 'trec' files are written.")

    logging.info(f"Reading the surveys from {surveys_file}.")
    ids, titles, influentials, relevants = list(), list(), list(), list()
    with surveys_file.open("r") as fp:
        for line in fp:
            data = json.loads(line)
            if "title" in data and "references" in data:
                ids.append(data["id"])
                titles.append(data["title"])
                influentials.append(data["references"]["influential"])
                relevants.append(data["references"]["relevant"])

    logging.info(f"Writing the records to {records_file}.")
    with records_file.open("w") as fp:
        for i, qids in enumerate(ids):
            for docno in influentials[i]:
                fp.write(f"{qids} Q0 {docno} 2\n")
            for docno in relevants[i]:
                fp.write(f"{qids} Q0 {docno} 1\n")

    logging.info(f"Writing the queries to {queries_file}.")
    with queries_file.open("w") as fp:
        for id, title in zip(ids, titles):
            json.dump({"id": id, "query": title}, fp)
            fp.write("\n")


if __name__ == "__main__":
    main()
