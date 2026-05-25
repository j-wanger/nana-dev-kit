---
title: "Benchmark-only hybrid deps"
aliases: [hybrid-deps-benchmark-only, fastembed-sqlite-vec-scope]
category: decisions
tags: [benchmark, fastembed, sqlite-vec, dependencies]
parents: [phase-33-hybrid-retrieval-benchmark-memory-server-fixes]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

Hybrid retrieval requires `fastembed` (~500MB for ONNX runtime) and `sqlite-vec`. These are heavy dependencies that most users of the dev kit would never need. The question: where to install them and whether to add them to the standard install path.

## Decision

fastembed + sqlite-vec are benchmark-only dependencies. NOT added to `install.sh` venv setup. Installed into the existing `~/.claude/memory_server/.venv/` for convenience (shared Python environment with memory_server). If venv installation fails, fallback to `benchmark/.venv/`.

**Rationale:** Adding ~500MB of ONNX dependencies to every install would bloat the kit for a feature most users won't exercise. The benchmark is a diagnostic tool, not a runtime requirement.

## Consequences

- Users running the benchmark need to manually install: `pip install fastembed sqlite-vec` (or the benchmark script handles it).
- The memory_server venv may grow significantly when benchmark deps are installed.
- If venv isolation becomes important later, a separate benchmark venv can be created without breaking anything.
- `install.sh --status` won't report hybrid deps availability (benchmark-scoped).
