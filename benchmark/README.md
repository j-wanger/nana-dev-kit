# LongMemEval-S Memory Benchmark

Measures retrieval quality of the vendored `memory_server/` against the [LongMemEval-S dataset](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned) (500 questions, ~50 sessions per question, 6 categories).

## Setup

```bash
uv venv benchmark/.venv --python 3.11
uv pip install --python benchmark/.venv/bin/python nanoid pydantic pyyaml huggingface_hub
```

For hybrid mode (optional):
```bash
uv pip install --python benchmark/.venv/bin/python fastembed sqlite-vec
```

## Usage

```bash
# Verify setup (3 questions, asserts recall > 0)
benchmark/.venv/bin/python benchmark/longmemeval.py --smoke-test

# Quick validation (N questions)
benchmark/.venv/bin/python benchmark/longmemeval.py --dry-run 10

# Full benchmark (500 questions, ~10 minutes)
benchmark/.venv/bin/python benchmark/longmemeval.py --full

# Hybrid mode (requires fastembed + sqlite-vec)
benchmark/.venv/bin/python benchmark/longmemeval.py --full --mode both
```

## What it measures

**Recall@K**: For each question, all ~50 conversation sessions are indexed as individual memory entries. The question is searched verbatim. Recall@K = proportion of gold sessions appearing in the top-K results.

**Retrieval unit**: One memory entry = one full conversation session (all turns concatenated). This differs from some published baselines which use smaller chunks.

## Interpreting results

| Metric | Meaning |
|--------|---------|
| recall@5 > 80% | Strong — most answers found in top 5 |
| recall@5 50-80% | Acceptable — answers usually in top 10 |
| recall@5 < 50% | Needs investigation — possible adapter issue |

### Published baselines (rohitg00/agentmemory)

| Method | recall@5 |
|--------|----------|
| BM25 | 86.2% |
| Hybrid (BM25 + embedding) | 95.2% |

**Caveat**: These baselines use different retrieval units (conversation chunks vs. our full-session entries) and different BM25 implementations. Direct numeric comparison is informative but not apples-to-apples.

## Categories

The dataset has 6 question types:
- `single-session-user` — answer in one session, about user info
- `single-session-assistant` — answer in one session, about assistant behavior
- `single-session-preference` — answer in one session, about preferences
- `multi-session` — answer requires info from multiple sessions
- `temporal-reasoning` — answer requires understanding time relationships
- `knowledge-update` — answer reflects updated information

## Output

Results are saved to `benchmark/results.json` (gitignored). Format:

```json
{
  "fts5": {
    "mode": "fts5",
    "total_questions": 500,
    "overall_recall_at_5": 0.85,
    "overall_recall_at_10": 0.92,
    "per_category": { ... }
  }
}
```
