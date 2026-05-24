---
title: "Phase 32 complete"
aliases: []
category: journal
tags: [benchmark, memory, evaluation, retrieval, longmemeval]
parents: [phase-32-longmemeval-s-benchmark]
created: 2026-05-24
updated: 2026-05-24
---

# Phase 32: LongMemEval-S Memory Benchmark — Complete

## Summary

Implemented diagnostic benchmark measuring memory_server retrieval quality against the LongMemEval-S dataset (500 questions). FTS5 recall@5 91.0% exceeds 50% threshold; README updated with benchmark results.

## Tasks Completed

1. [M] Dataset exploration + scaffold + smoke test -- benchmark/longmemeval.py with --smoke-test, .gitignore entries
2. [L] Full benchmark implementation -- --dry-run N flag, FTS5+hybrid detection, per-question DB isolation, recall@5/10, category breakdown, benchmark/README.md
3. [S] README + final verify -- Memory Benchmark section added, eval count 43->47 updated

## Key Results

- FTS5 recall@5: 91.0% (vs published BM25 baseline 86.2%)
- FTS5 recall@10: 95.2%
- Weakest: multi-session (83.7%), temporal-reasoning (86.9%)
- Hybrid mode: untested (fastembed/sqlite-vec not in benchmark venv)

## Decisions

- [[diagnostic-first-benchmark]] confidence upgraded medium -> high (results validate approach)

## Escape Hatches

- DISCOVERY: Python 3.14 pyexpat broken on macOS -- used Python 3.11 via uv venv for benchmark
- DISCOVERY: FTS5 syntax error on `?` in queries -- added sanitize_query() in benchmark script (not memory_server modification)

## Observations

- SQLite FTS5 competitive with BM25 baselines without any query rewriting
- Multi-session and temporal-reasoning weakness suggests multi-hop retrieval gap
- memory_server _sanitize_fts_query doesn't handle `?` character -- potential upstream fix

## Health

- Tests: 190 (unchanged)
- Eval: 47/47 (unchanged)
- Budget: ~300/300
