---
title: "Phase 32: LongMemEval-S Memory Benchmark"
aliases: []
category: phases
tags: [benchmark, memory, evaluation, retrieval]
parents: []
created: 2026-05-24
updated: 2026-05-24
source: debrief
status: completed
scope: ["benchmark/longmemeval.py", "benchmark/README.md", ".gitignore", "README.md"]
entry_criteria: "Phase 31 complete, 190 tests passing, 47/47 eval"
exit_criteria: "benchmark/longmemeval.py exists and parses, --smoke-test exits 0, --dry-run 3 exits 0, benchmark/README.md exists, .gitignore has benchmark/data + benchmark/results, make test passes"
---

# Phase 32: LongMemEval-S Memory Benchmark

## Objective

Implement a diagnostic benchmark measuring memory_server retrieval quality against the LongMemEval-S dataset. Single Python script with three phases: dataset download/parse, per-question indexing/querying with isolated SQLite DBs, and scoring/report generation. Results inform retrieval improvements; README inclusion conditional on recall > 50%.

## Scope

Files and modules affected:
- `benchmark/longmemeval.py` -- single entry point implementing full benchmark pipeline
- `benchmark/README.md` -- usage instructions and interpretation guide
- `.gitignore` -- exclude benchmark/data/ and benchmark/results.json
- `README.md` -- conditional Memory Benchmark section with recall numbers

## Exit Criteria

- [x] benchmark/longmemeval.py exists and parses (ast.parse)
- [x] --smoke-test exits 0 (downloads 3 questions, indexes, queries, asserts recall > 0)
- [x] --dry-run 3 exits 0 and produces valid output
- [x] benchmark/README.md exists with usage and interpretation guide
- [x] .gitignore has benchmark/data and benchmark/results entries
- [x] make test passes (no regressions)

## Approach

Single Python script pattern. One entry point (benchmark/longmemeval.py) with three phases: (1) download + parse dataset, (2) per-question indexing + querying with isolated SQLite DBs, (3) scoring + report generation. Each conversation session stored as one memory entry (content = full session text concatenated, category = "fact", tags = [session_id]). Query with verbatim question text. FTS5-only and hybrid (when fastembed + sqlite-vec available). Results saved to benchmark/results.json. Diagnostic first -- README inclusion conditional on meaningful results.

## Constraints

- Per-question DB isolation (tempfile) to prevent cross-contamination
- FTS5 search with verbatim question text (no query rewriting)
- Hybrid mode detection via availability check (fastembed + sqlite-vec)
- Progress reporting every 50 questions for the full 500-question run
- DATASET_REVISION constant for reproducibility

## Results

- FTS5 recall@5: 91.0% (beats published BM25 baseline 86.2%)
- FTS5 recall@10: 95.2%
- Weakest categories: multi-session (83.7%), temporal-reasoning (86.9%)
- Hybrid mode untested (fastembed/sqlite-vec not installed in benchmark venv)
- README inclusion: approved (91.0% >> 50% threshold)
- Discovery: Python 3.14 pyexpat broken on macOS -- used Python 3.11 via uv venv
- Discovery: FTS5 syntax error on `?` in queries -- added sanitize_query() in benchmark script

## Notes

- 1 decision: diagnostic-first-benchmark (confidence high, validated by results)
- Tasks ordered by dependency: 1 (scaffold), 2 (depends 1), 3 (depends 1-2)
- No cross-wiki knowledge required; uses existing memory_server/storage.py API
