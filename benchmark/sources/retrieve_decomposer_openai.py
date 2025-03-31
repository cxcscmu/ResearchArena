import json
import logging
import argparse
import asyncio
from pathlib import Path

from openai import AsyncOpenAI
from openai import RateLimitError, APIError, Timeout
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type

prompt_template = """### Below is an example on how to decompose a complex question into sub-questions and search queries.

Question: should the death penalty be legalized?

<Decomposition>
    - What are the arguments in favor of the death penalty?
        - Does the death penalty serve as a deterrent to crime?
        - Is the death penalty a just punishment for certain crimes?
        - How does the death penalty compare to other forms of punishment in terms of cost and effectiveness?
    - What are the arguments against the death penalty?
        - What is the risk of executing innocent people with a death penalty?
        - Are there any ethical concerns surrounding the death penalty?
        - To what extent is the death penalty applied fairly and without bias?
        - In practice, how expensive is the death penalty?
    - What is the current legal status of the death penalty in various jurisdictions?
        - In which countries or states is the death penalty currently legal?
        - What are the trends in death penalty legislation and public opinion?
    - What are the alternatives to the death penalty?
        - How effective are alternative punishments to the death penalty, e.g. life imprisonment?
        - What are the costs and benefits of alternatives to the death penalty?
    - How do the pros and cons of the death penalty compare to its alternatives?
</Decomposition>

<Queries>
    - arguments in favor of the death penalty
    - death penalty as a deterrent to crime
    - death penalty as a just punishment
    - death penalty cost and effectiveness comparison
    - arguments against the death penalty
    - risk of executing innocent people with death penalty
    - ethical concerns surrounding the death penalty
    - fairness and bias in death penalty application
    - current legal status of the death penalty worldwide
    - trends in death penalty legislation and public opinion
    - alternatives to the death penalty
    - effectiveness of life imprisonment without parole
    - costs and benefits of death penalty alternatives
</Queries>

Question: {title}

### Instructions:

1. What sub-questions do I need to know in order to fully understand and answer the above Question.
    - Format your response as a bullet-point style outline of questions and sub-questions in the <Decomposition> tag.
    - Order your sub-questions such that one question comes after another if it needs to use the answer to the previous one.
    - Do not ask unnecessary or tangential sub-questions, only those that are critical to finding important information.  
2) Next, write a list of search queries that would likely lead to results addressing all the sub-questions.
    - Enumerate your queries in a bullet-point style list inside the <Queries> tag.

You may refer to the example above for guidance.
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
        max_tokens=1024,
    )
    return response.choices[0].message.content

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--surveys-file", type=str, required=True)
    parser.add_argument("--replays-file", type=str, required=True)
    parser.add_argument("--queries-file", type=str, required=True)
    parser.add_argument("--records-file", type=str, required=True)
    parsed = parser.parse_args()

    surveys_file = Path(parsed.surveys_file)
    if surveys_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are read.")
    replays_file = Path(parsed.replays_file)
    if replays_file.suffix != ".jsonl":
        raise NotImplementedError("Only 'jsonl' files are written.")
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
            break

    logging.info(f"Writing the records to {records_file}.")
    with records_file.open("w") as fp:
        for i, qids in enumerate(ids):
            for docno in influentials[i]:
                fp.write(f"{qids} Q0 {docno} 2\n")
            for docno in relevants[i]:
                fp.write(f"{qids} Q0 {docno} 1\n")

    logging.info(f"Writing the queries to {queries_file}.")
    batch_size, client = 32, AsyncOpenAI()
    with queries_file.open("w") as fp1, replays_file.open("w") as fp2:
        for i in range(0, len(ids), batch_size):
            batch_ids = ids[i:i + batch_size]
            batch_titles = titles[i:i + batch_size]
            batch_prompts = [prompt_template.format(title=title) for title in batch_titles]
            logging.info(f"Processing batch {i}-{i+batch_size} out of {len(ids)} records...")
            batch_queries = await asyncio.gather(*[generate_response(client, prompt) for prompt in batch_prompts])
            for id, queries in zip(batch_ids, batch_queries):
                json.dump({"id": id, "replay": queries}, fp2)
                fp2.write("\n")
                matched = queries.partition("<Queries>")[-1].strip()
                if matched == "":
                    continue
                matched = matched.partition("</Queries>")[0].strip()
                if matched == "":
                    continue
                for line in matched.splitlines():
                    query = line.lstrip("- ")
                    if query == "":
                        continue
                    json.dump({"id": id, "query": query}, fp1)
                    fp1.write("\n")

if __name__ == "__main__":
    asyncio.run(main())
