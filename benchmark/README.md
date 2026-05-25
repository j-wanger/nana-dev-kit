# LongMemEval-S Memory Benchmark

Measures retrieval quality of `memory_server/` against the [LongMemEval-S dataset](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned) (500 questions, ~50 sessions per question, 6 categories).

## Setup

```bash
# Base deps
uv venv benchmark/.venv --python 3.11
uv pip install --python benchmark/.venv/bin/python nanoid pydantic pyyaml huggingface_hub

# Hybrid mode (optional)
uv pip install --python benchmark/.venv/bin/python fastembed sqlite-vec
```

## Usage

```bash
# Verify setup
benchmark/.venv/bin/python benchmark/longmemeval.py --smoke-test

# Quick validation
benchmark/.venv/bin/python benchmark/longmemeval.py --dry-run 10

# Full benchmark — session-level (default)
benchmark/.venv/bin/python benchmark/longmemeval.py --full --mode both

# Full benchmark — turn-level indexing (recommended for hybrid)
benchmark/.venv/bin/python benchmark/longmemeval.py --full --mode both --index turn
```

## Indexing strategies

**`--index session`** (default): Each conversation session stored as one entry. FTS5 searches full text. For hybrid, embeddings are truncated to 512 chars.

**`--index turn`**: Each conversation turn stored as a separate entry with session context. Produces high-quality embeddings (short texts, ~100-500 chars) that match how `memory_server` stores data in production.

## Results (500 questions, session-level)

| Mode | recall@5 | recall@10 |
|------|----------|-----------|
| FTS5 | **91.0%** | **95.2%** |
| Hybrid (RRF α=0.4) | 87.1% | 90.7% |

Session-level hybrid hurts recall because 512-char truncated embeddings are misleading — they represent the session opener, not the full content. RRF fusion introduces wrong sessions and displaces correct FTS5 results.

## Results (40-question diagnostic, session vs turn)

Tested on 20 FTS5-failure questions + 20 easy questions:

| Mode | Failures r@5 | Easy r@5 | Safe? |
|------|-------------|---------|-------|
| FTS5 session | 51.2% | 100% | baseline |
| Hybrid RRF session | **82.9%** | **80%** ❌ | NO |
| Rerank session | 60.1% | 100% | YES |
| **Hybrid RRF turn** | **78.8%** | **100%** ✅ | **YES** |
| FTS5 turn | 54.3% | 100% | YES |
| Rerank turn | 61.9% | 100% | YES |

**Winner: Turn-level hybrid RRF.** +27.6% lift on hard questions, no degradation on easy ones.

### Why turn-level works

- Turn entries are short (~100-500 chars) → high-quality embeddings
- Embeddings align with FTS5 instead of fighting it
- Matches production `memory_store` behavior (short facts, not full transcripts)
- Session-level hybrid with truncated embeddings actively misleads the ranker

### FTS5 failure analysis (87/500 questions)

- 92% of failures are multi-session (45) or temporal-reasoning (35)
- Failure pattern: counting queries ("How many X did I...?") needing 3-5 sessions
- Different sessions use different vocabulary for the same activity → vocabulary mismatch
- BM25 score predicts failures: avg top score 9.3 (failures) vs 19.5 (successes)

### Published baselines (rohitg00/agentmemory)

| Method | recall@5 |
|--------|----------|
| BM25 | 86.2% |
| Hybrid (BM25 + embedding) | 95.2% |

**Caveat**: Different retrieval units (chunks vs. full sessions) and BM25 implementations.

## Categories

- `single-session-user` — answer in one session, about user info
- `single-session-assistant` — answer in one session, about assistant behavior
- `single-session-preference` — answer in one session, about preferences
- `multi-session` — answer requires info from multiple sessions
- `temporal-reasoning` — answer requires understanding time relationships
- `knowledge-update` — answer reflects updated information

## Output

Results saved to `benchmark/results.json` (gitignored):

```json
{
  "fts5/session": {
    "mode": "fts5",
    "index_strategy": "session",
    "overall_recall_at_5": 0.91,
    "overall_recall_at_10": 0.952,
    "per_category": { ... }
  }
}
```
