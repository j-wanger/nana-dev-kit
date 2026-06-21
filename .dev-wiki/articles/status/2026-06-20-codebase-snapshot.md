---
title: "Codebase Snapshot 2026-06-20"
aliases: [2026-06-20-codebase-snapshot]
category: status
tags: [snapshot, phase-94]
parents: [phase-94-consumer-memory-remeasure]
created: 2026-06-20
updated: 2026-06-20
source: debrief
---

# Codebase Snapshot 2026-06-20

Captured at the Phase 94 (Clean Consumer Memory Re-measure) debrief — EVIDENCE ONLY, delivery gate pending.

## Metrics

- Test scripts: 29 `tests/test_*.sh` (README reports 28; Phase 94 added ZERO kit test scripts — `eval/memory-remeasure/` is phase-evidence, not registered in `make test`).
- Eval scenarios: 50 (denominator unchanged; detect-loop cut at Phase 88 set it 52→50).
- Project-scoped hooks: 18 `templates/.claude/hooks/*.sh` (17 in `modules.json` hooks array + 1 global).
- Skills: 25 `templates/.claude/skills/*/`.
- Decision articles: 193 · Journals: 93 · Phase articles: 93.

## Module Structure

Top-level: `benchmark/`, `docs/`, `eval/`, `memory_server/`, `patches/`, `quarantine/`, `scripts/`, `specs/`, `templates/`, `tests/`, `wiki/`.

New this phase: `eval/memory-remeasure/` (verify-firing.sh, tally-demand.py, fixtures/**, memory-demand-remeasure.md) — consumer memory-LAYER demand re-measure apparatus, repo-only, NOT in install.sh / make test / make eval.

## Test Status

`make test` ALL-PASS (no regression — Phase 94 touched zero kit code). git diff scope = `eval/` + `.dev-wiki/` + `specs/` + `.claude/rules/` only.

## Recent Commits

- 83db25a Phase 93 — delivery accepted; flip delivery gate (5f830dc verified)
- 5f830dc Phase 93: install.sh idempotent update / consuming-project re-sync mode
- 01091d9 Phase 92 — delivery accepted; flip delivery gate (1dc1d80 verified)
- 1dc1d80 Phase 92 — Strategic Inflection Review & Roadmap Re-sequencing
- e62e4dd Phase 91 — delivery accepted; flip delivery gate (318e9b6 verified)

(Phase 94 commit pending delivery acceptance — repair-commit `318e9b6` is the Phase-91 verification SHA pinned as the re-measure window.)
