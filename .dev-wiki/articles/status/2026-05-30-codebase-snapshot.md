---
title: "Codebase Snapshot 2026-05-30 (Phase 70 complete)"
aliases: []
category: status
tags: [snapshot, phase-70]
parents: [phase-70-anchor-headroom-screen]
created: 2026-05-30
updated: 2026-05-30
source: debrief
---

# Codebase Snapshot — 2026-05-30

## Metrics

| Metric | Value |
|--------|-------|
| Version | 0.5.0 |
| Skill .md files (templates) | 114 |
| Hook .sh files (templates) | 20 |
| Test scripts | 19 (`make test`, UNCHANGED) |
| Eval scenarios | 52 (`make eval` 100%, UNCHANGED) |
| Decision articles | 157 |
| Phase articles | 70 (all completed; Phase 70 delivery-accepted) |

## Module Structure

Unchanged from prior snapshots (see `_ARCHITECTURE.md`). This session added only one repo-only subtree:
- `eval/amplifier/anchor-screen/` (70 files) — the frozen single-decision anchor-headroom screen:
  `check.sh` (deterministic named-clause consensus-by-clause checker, `--selftest`/`--aggregate`/`--stability`/`--verify-pins`, NO LLM in scoring), `leak-check.sh` + `leak-vocab.txt`, `pre-registration.md`, `screen-record.md`, `verdicts/` ×7, `prompts/` ×7, `checks/` ×7, `fixtures/`, `runs/` ×30. NOT wired into install.sh / Makefile / `make test` / `make eval`.
- `.dev-wiki/articles/decisions/amplifier-anchor-headroom-screen.md` (finalized with the realized TERMINATE result + handoff).
- `specs/phase-70-anchor-headroom-screen.md` (NEW spec).

## Test Status

- `make test`: 19 scripts green (UNCHANGED — anchor-screen self-tests are not make-test gates).
- `make eval`: 52/52 (100%, UNCHANGED).
- Frozen artifacts git-diff-empty: `emit-proxy-vector.sh`, `measurability-gate.sh`, and all CODE under `eval/comparison|corpus|reasoning`. No non-target regression.

## Recent Commits

```
df45592 Phase 70 T2-T5: anchor-headroom screen RESULT — PROGRAM-VERDICT: TERMINATE
be96783 Phase 70 plan + T1: frozen pre-registration + deterministic anchor-headroom screen apparatus
8740d1d Phase 69: Amplifier Representativeness Audit + Anchor-Validity Verdict
b8c255f Phase 68: Amplifier Measurement Instrument (Frontier 0 ruler)
79c064a Phase 67: Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate
```

(Phase 70 committed `be96783` + `df45592`, pushed to `main`. Delivery accepted.)

## Notes

- PROGRAM-VERDICT: TERMINATE — the amplifier single-decision-anchor measurement line is closed. No active phase.
- `_ARCHITECTURE.md` file inventory predates several phases; counts synced this session, broader inventory flagged for a `/dev-scan` refresh.
