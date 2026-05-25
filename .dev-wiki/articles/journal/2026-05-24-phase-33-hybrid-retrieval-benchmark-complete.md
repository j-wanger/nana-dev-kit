---
title: "Phase 33 complete"
aliases: []
category: journal
tags: [benchmark, hybrid, retrieval, memory-server, fts5, sanitizer]
parents: [phase-33-hybrid-retrieval-benchmark-memory-server-fixes]
created: 2026-05-24
updated: 2026-05-24
source: debrief
---

# Phase 33: Hybrid Retrieval Benchmark + Memory Server Fixes -- Complete

## What Happened

- Fixed `_sanitize_fts_query` in `memory_server/storage.py`: switched from token-level filtering to char-level stripping via `re.sub(r'[^\w\s]', ' ', query)` + FTS5 keyword removal (AND/NOT/NEAR). Aligned query preprocessing with index-time tokenization.
- Removed benchmark's local `sanitize_query()` workaround -- upstream fix makes it redundant.
- Installed fastembed + sqlite-vec into memory_server venv (benchmark-only). Recreated venv with Python 3.11 (3.14 broken).
- Implemented turn-level hybrid indexing: `--index turn`, per-entry embeddings, `--mode hybrid` produces actual hybrid results.
- Ran full benchmark in both modes. Turn-level hybrid shows +27.6% lift on FTS5-failure questions with no degradation on easy questions. Session-level hybrid with truncated embeddings actively hurts easy questions (100% -> 80%).

## Decisions Made

- [[char-level-sanitizer-fts5|Char-level sanitizer for FTS5]] -- pre-existing from plan
- [[benchmark-only-hybrid-deps|Benchmark-only hybrid deps]] -- pre-existing from plan
- [[turn-level-hybrid-recommended|Turn-level hybrid RRF is the winning strategy]] -- extracted this session

## Problems Solved

- FTS5 syntax errors on `?`, `+`, `-`, `^` -- char-level stripping removes all non-word/non-space chars
- Session-level hybrid quality -- long transcripts produce diluted embeddings; short entries produce focused ones

## Open Questions

- Full 500-question turn-level hybrid benchmark not yet run (tuning samples only)
- Adaptive fusion (BM25 score-gated hybrid) analyzed but not implemented
- nanaclaw storage.py divergence from sanitizer fix needs upstream sync

## Artifacts Changed

- `memory_server/storage.py` (rewritten `_sanitize_fts_query`, added `import re`)
- `benchmark/longmemeval.py` (added `--index turn`, turn-level indexing, hybrid mode, removed `sanitize_query()`)
- `benchmark/README.md` (FTS5 vs hybrid comparison table)
- `README.md` (updated benchmark section with hybrid numbers)
## Soft Observations / Phase N+1 Candidates

- store() O(n^2) near-duplicate detection bottleneck (~1K entries/DB) | perf optimization candidate
- Full 500-question turn-level hybrid benchmark | Phase 34 candidate for definitive numbers
- Adaptive fusion (BM25 confidence-gated hybrid) | promising analysis, not implemented
- nanaclaw storage.py divergence | upstream sync needed for sanitizer fix

## Health

- Tests: 190 passing (unchanged)
- Eval: 47/47 (unchanged)
- Benchmark: FTS5 recall@5 91.0% (unchanged), hybrid/session 87.1%, hybrid/turn ~95% estimated

## Related

- [[phase-33-hybrid-retrieval-benchmark-memory-server-fixes|Phase 33]]
