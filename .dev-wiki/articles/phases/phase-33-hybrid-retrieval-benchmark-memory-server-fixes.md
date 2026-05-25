---
title: "Phase 33: Hybrid Retrieval Benchmark + Memory Server Fixes"
aliases: []
category: phases
tags: [benchmark, memory, retrieval, hybrid, fts5, fastembed, sqlite-vec]
parents: [phase-32-longmemeval-s-benchmark]
created: 2026-05-24
updated: 2026-05-24
source: plan
status: completed
scope: ["memory_server/storage.py", "benchmark/longmemeval.py", "benchmark/README.md", "README.md"]
entry_criteria: "Phase 32 complete, 190 tests passing, 47/47 eval, FTS5 baseline established (recall@5 91.0%)"
exit_criteria: "_sanitize_fts_query uses char-level stripping, benchmark sanitize_query() removed, hybrid benchmark runs with --mode hybrid, docs updated with FTS5 vs hybrid comparison table, make test passes"
---

# Phase 33: Hybrid Retrieval Benchmark + Memory Server Fixes

## Objective

Fix `_sanitize_fts_query` in memory_server/storage.py to handle the full set of FTS5 special characters using char-level stripping, remove the benchmark's workaround, install fastembed+sqlite-vec for hybrid retrieval, run the full LongMemEval-S benchmark in both modes, and document the comparison.

## Scope

Files and modules affected:
- `memory_server/storage.py` -- _sanitize_fts_query rewrite (char-level stripping)
- `benchmark/longmemeval.py` -- remove sanitize_query(), add hybrid indexing path
- `benchmark/README.md` -- FTS5 vs hybrid comparison table
- `README.md` -- updated benchmark section with hybrid numbers

## Exit Criteria

- [ ] `_sanitize_fts_query` uses `re.sub(r'[^\w\s]', ' ', query)` with FTS5 keyword stripping
- [ ] `sanitize_query()` removed from `benchmark/longmemeval.py`
- [ ] `--mode hybrid` produces actual hybrid results (not FTS5 fallback)
- [ ] `benchmark/README.md` contains FTS5 vs hybrid comparison table
- [ ] `README.md` updated with hybrid benchmark numbers
- [ ] `make test` passes

## Constraints

- fastembed + sqlite-vec are benchmark-only deps, NOT added to install.sh (prevents ~500MB bloat)
- FTS5 recall@5 must remain >= 91% after sanitizer rewrite (no regression)
- Per-question DB isolation means ~25K embedding calls for full run (expect long runtime)

## Checkpoints

- After Task 1: verify FTS5 recall hasn't regressed with --smoke-test
- After Task 3: verify --dry-run 3 --mode hybrid shows HYBRID results (not FTS5 fallback)
- If hybrid recall@5 < 85%: STOP and investigate before full run

## Assumptions

- nomic-embed-text-v1.5 produces 768d vectors matching vec0 table schema. If false: check config.py defaults.
- fastembed + sqlite-vec installable in existing memory_server venv. If false: use benchmark/.venv/ fallback.
- storage.py search_hybrid() RRF fusion (alpha=0.4, k=60) is correct. If false: tune parameters.

## Notes

- Phase 32 discovered `?` causes FTS5 syntax errors; benchmark has local workaround (`sanitize_query` at line 68)
- Full FTS5 special character set: `? - + ^ ~ { } [ ] | \` plus bare `AND`, `OR`, `NOT`, `NEAR`
- Current `_sanitize_fts_query` only strips `( ) " * :`
- Published hybrid baseline elsewhere: 95.2% recall@5 (different retrieval units, not directly comparable)
- Three workstreams sequenced by dependency: sanitizer fix -> benchmark cleanup -> hybrid implementation
