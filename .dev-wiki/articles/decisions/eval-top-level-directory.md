---
title: "eval/ as top-level directory (not tests/eval/)"
aliases: [eval-top-level-directory]
category: decisions
tags: [eval, directory-structure, architecture]
parents: [phase-20-eval-harness]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

The eval corpus needs a home. Two candidates: `tests/eval/` (under existing test tree) or `eval/` (new top-level directory). Existing tests live in `tests/` and use `make test`.

## Decision

Eval corpus lives at `eval/` (top-level), not `tests/eval/`. Eval has different semantics from regression tests: it produces quantitative scores (not pass/fail), benchmarks harness quality (not correctness), and should be independently runnable via `make eval` without coupling to `make test`.

Alternative considered: `tests/eval/` -- rejected to keep clear separation between regression tests (fast, binary, run on every commit) and eval benchmarks (slower, scored, run on demand).

## Consequences

New top-level directory in the repo. `_ARCHITECTURE.md` directory layout needs updating. `make eval` is separate from `make test` -- they never call each other. The eval/ directory contains corpus, schemas, validators, and documentation.
