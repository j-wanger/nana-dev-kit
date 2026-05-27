---
id: HEU-001
trigger: "choosing a storage backend for a single-user developer tool"
domain: dev-tooling
source_phase: 4
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Embedded Databases for Single-User Tools

## When this applies
Choosing a storage backend for a developer tool, CLI, or agent component
that will be used by one process at a time.

## Always
- Default to SQLite (zero-deploy, single-file, no server)
- Check: concurrent writes needed? If no → SQLite
- Check: data > 10GB? If no → SQLite
- Check: need network access from multiple hosts? If no → SQLite

## Never
- Reach for Postgres/Redis/Mongo for single-user dev tools
- Add Docker/server dependencies to a tool's install path
- Let "the right tool for the job" override deployment complexity budget

## Why
The deployment complexity budget for dev tooling is near-zero. Users should
not install database servers to use a development tool. SQLite's single-file
model also makes debugging trivial — one .db file to inspect, copy, or delete.

## Anti-pattern
"Postgres is more robust" → True, but irrelevant when robustness isn't the
constraint. The constraint is: `pip install && run` must work without Docker,
without servers, without configuration. Every external dependency is a
potential install failure.

## Source
Phase 4: memory server chose SQLite. Phase 32: LongMemEval benchmark showed
FTS5 handles 500+ questions at 91% recall@5. Phase 38: CWD bug proved
SQLite's single-file model is also debuggable.
