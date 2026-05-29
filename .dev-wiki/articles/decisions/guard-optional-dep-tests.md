---
title: "Guard optional-dependency tests instead of forcing the dep into install"
aliases: ["optional-dep-test-skip", "sqlite-vec-test-guard", "make-test-halt-fix"]
category: decisions
tags: [testing, optional-dependency, memory-venv, make-test, sqlite-vec, fail-open]
parents: [phase-58-active-domain-research-in-dev-plan]
created: 2026-05-28
updated: 2026-05-28
source: debrief
confidence: high
---

## Context

`make test` had been halting at `tests/test_memory.sh` across Phases 56-58 — the
recurring "make test halts" symptom. The user requested a fix: "fix the memory venv
so make test runs end-to-end." Investigation found the root cause was twofold, not a
simple environment problem:

1. The optional `sqlite-vec` dependency was absent from the (otherwise healthy,
   uv-built, Py3.13) venv. The historical `libpython3.11.dylib` symptom was stale
   from an older venv and not the real cause.
2. `test_memory.sh` forced `_vec_available=True` and hard-crashed on the missing
   `memories_vec` table instead of skipping when the *optional* dependency was
   absent. A failing optional-subsystem test that halts the suite masks every
   downstream suite.

`sqlite-vec` (and `fastembed`) live intentionally in
`memory_server/requirements-optional.txt` ("without these, FTS5-only mode") — the
kit is designed to run vector-free by default.

## Decision

Make the vec-requiring tests in `test_memory.sh` probe for the extension once and
**SKIP cleanly** (FTS5-only mode) when it is absent, rather than assuming presence
and halting. Also install `sqlite-vec==0.1.9` into the local venv so the full path
runs locally.

Did NOT add `sqlite-vec` to `install.sh`'s required deps.

Alternatives considered:
- **(a) Add `sqlite-vec` to install.sh required deps** — rejected: contradicts the
  documented optional/FTS5-only design and bloats every install with
  `fastembed` + `sqlite-vec`.
- **(b) Make vector search default-on for the kit** — deferred as a separate design
  call; raised to the user as a Phase N+1 candidate.

The principle: a test for an OPTIONAL dependency must be conditional on its presence,
not assume-and-halt — otherwise a missing optional dep takes down the whole suite.
This mirrors the kit's existing fail-open hook discipline.

## Consequences

- `make test` is GREEN end-to-end (exit 0). Memory suite is 11/11 with `sqlite-vec`
  present, 7/7 (FTS5-only, vec tests skipped) when absent — both branches verified.
- The "make test halts" recurring blocker is closed at the durable level: a missing
  optional dep can no longer halt the suite.
- The optional-vs-required design boundary stays intact — installs remain lean.
- Open follow-on: whether vector search should be default-on for the kit (add to
  `install.sh`) or stay opt-in remains an undecided design call.
- `tests/test_memory.sh` grew ~20 lines (a one-time probe + 2 VEC_OK guards). No new
  test scripts.
