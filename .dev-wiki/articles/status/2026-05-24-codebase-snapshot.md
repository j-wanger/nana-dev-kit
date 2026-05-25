---
title: "Codebase Snapshot 2026-05-24"
aliases: []
category: status
tags: [snapshot]
parents: []
created: 2026-05-24
updated: 2026-05-24
---

# Codebase Snapshot 2026-05-24

## Metrics

- Files: ~350 (excluding .git, .dev-wiki, benchmark/data, benchmark/.venv)
- Tests: 190 (6 scripts)
- Eval: 47/47 scenarios (4 categories)
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated
- Version: 0.5.0
- Phases completed: 33

## Recent Commits

- `513bfd0` Phase 32: LongMemEval-S Memory Benchmark
- `dac7c90` Phase 31: Integration Eval + Memory Gating
- `60865c2` Phase 30: Data-Driven Report Generators
- `b35d624` Regenerate HTML reports for v0.5.0+
- `6a63927` Debrief Phase 29: v0.5.1 Grade Push

## Key Changes Since Last Snapshot

- memory_server/storage.py: _sanitize_fts_query rewritten (char-level stripping)
- benchmark/longmemeval.py: turn-level hybrid indexing, removed sanitize_query()
- FTS5 vs hybrid comparison documented in benchmark/README.md
