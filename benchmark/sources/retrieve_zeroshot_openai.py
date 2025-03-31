import json
import logging
import argparse
import asyncio
from pathlib import Path

from openai import AsyncOpenAI
from openai import RateLimitError, APIError, Timeout
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type

prompt_template = """Create a search query that gathers supporting materials for writing a survey paper on the following topic: {title}.
"""

@retry(
    retry=retry_if_exception_type((RateLimitError, APIError, Timeout)),
    wait=wait_random_exponential(min=1, max=60),
    stop=stop_after_attempt(6),
)
async def generate_response(client: AsyncOpenAI, prompt: str):
    response = await client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        seed=42,
        temperature=0,
        max_tokens=512,
    )
    return response.choices[0].message.content

async def main():
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
    batch_size, client = 32, AsyncOpenAI()
    with queries_file.open("w") as fp:
        for i in range(0, len(ids), batch_size):
            batch_ids = ids[i:i + batch_size]
            batch_titles = titles[i:i + batch_size]
            batch_prompts = [prompt_template.format(title=title) for title in batch_titles]
            logging.info(f"Processing batch {i}-{i+batch_size} out of {len(ids)} records...")
            batch_queries = await asyncio.gather(*[generate_response(client, prompt) for prompt in batch_prompts])
            for id, query in zip(batch_ids, batch_queries):
                json.dump({"id": id, "query": query}, fp)
                fp.write("\n")

if __name__ == "__main__":
    asyncio.run(main())
