---
title: "Phase 89: Post-Trim Dogfood & Demand-Evidence Round"
aliases: [phase-89]
category: phases
tags: [dogfood, trim-trial, memory-layer, demand-evidence, edge-screener]
parents: []
created: 2026-06-11
updated: 2026-06-11
source: plan
status: active
scope: ["eval/dogfood-round/**"]
entry_criteria: "Phase 88 delivery accepted (3b36d37); install drift 0 (post-trim templates synced to ~/.claude 2026-06-11) — the trim-trial windows are live"
exit_criteria: "10 machine-checkable criteria via eval/dogfood-round/run-exit-criteria.sh (specs/phase-89-dogfood-demand-evidence.md)"
---

# Phase 89: Post-Trim Dogfood & Demand-Evidence Round

## Objective

Run real edge-screener work sessions under the freshly-synced post-trim harness to (1) accrue
genuine exposure for the two Phase-88 trim-trial observation windows (ak-ride-along d43950f +
wk-seeding df3e623 — record trigger-relevant events against their pre-stated revert triggers,
never re-grade) and (2) generate clean memory-layer demand evidence for the deferred A4/A6
round (pinned evidence schema; liveness probe first; evidence, NOT disposition).

## Scope

Files and modules affected:
- `eval/dogfood-round/**` (new: evidence files, probes, schema)
- edge-screener sessions are external (its own `.dev-wiki/`; no quant code in nana-dev-kit)

## Exit Criteria

- [ ] The spec's 10 machine-checkable criteria, aggregated by `eval/dogfood-round/run-exit-criteria.sh` (ALL-PASS only on a full run; seeded-failure + skip-slow visible-partial controls). See `specs/phase-89-dogfood-demand-evidence.md` ## Exit criteria.

## Constraints (optional)

- Evidence, NOT disposition: the A4/A6 memory-layer call belongs to a future prune round — prevents this phase from laundering a dogfood zero into a cut.
- Trim-trial triggers are pre-stated (Blockers filings); this phase records trigger-relevant events only — prevents retroactive re-grading.
- Dogfood evidence must come from the CONSUMING project — in-kit measurement leaks always-loaded working-knowledge (Ph80 INSTRUMENT-DEAD class).
- Any log-based evidence must account for the enforcement.log run-provenance hazard (Phase-82 misc filing).

## Notes

Precedent: Phase 85 T4 dogfood protocol — liveness probe FIRST, ≥2 real-work sessions, pinned
evidence schema (hook | event | timestamp | helped/neutral/noise), evidence filed not disposed.
