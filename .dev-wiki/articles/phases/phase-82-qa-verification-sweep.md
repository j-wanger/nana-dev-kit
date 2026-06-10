---
title: "Phase 82: QA & Verification Sweep (ultracode)"
aliases: [phase-82, qa-verification-sweep]
category: phases
tags: [qa, verification, registration, hook-firing, drift, docs-accuracy, multi-agent]
parents: []
created: 2026-06-09
updated: 2026-06-09
source: plan
status: active
scope: ["modules.json", "templates/**", "scripts/*", "tests/*", "install.sh", "Makefile", "README.md", "eval/**"]
entry_criteria: "Phase 81 delivery accepted (gate flipped, pushed); make test green, make eval 52/52"
exit_criteria: "All 10 machine-checkable spec exit criteria pass via eval/qa-sweep/run-exit-criteria.sh (specs/phase-82-qa-verification-sweep.md)"
---

# Phase 82: QA & Verification Sweep (ultracode)

## Objective

Comprehensive QA pass over the nana-dev-kit implementation via multi-agent orchestration: verify registration/wiring integrity (modules.json ↔ filesystem ↔ generated settings template), hook firing (functional, not presence — HEU-012), skill↔companion integrity, single-source schema consistency (assumption-ledger schema, hooks array), installed-copy drift, test/eval coverage gaps, and docs accuracy (README/MANIFEST/AGENTS.md). Adversarially verify findings; fix confirmed in-scope defects; file the rest as deferred items.

## Scope

Files and modules affected:
- `modules.json`, `templates/.claude/settings.json` (generated), `install.sh`
- `templates/.claude/hooks/*` (18 scripts incl. session-start.d/), `templates/.claude/skills/**` (25 dirs + MANIFEST)
- `scripts/*` (check-install-drift.sh, check-assumption-ledger.sh, register-settings.py, ...)
- `tests/*` (20 scripts), `eval/**` (52 scenarios; repo-only measurement infra read-only)
- `README.md`, `templates/.claude/skills/MANIFEST`, `templates/AGENTS.md`

## Exit Criteria

All 10 machine-checkable criteria from `specs/phase-82-qa-verification-sweep.md`, assembled into `eval/qa-sweep/run-exit-criteria.sh` (T4):

- [x] `make test` exits 0 ("All tests passed")
- [x] `make eval` reports 52/52 pass
- [x] `check-install-drift.sh` reports 0 drift (installed copy converged)
- [x] verification-matrix.md has header + ≥8 area rows
- [x] every area (wiring/firing/companions/schema/drift/coverage/docs/usage) present as an anchored row label
- [x] `check-assumption-ledger.sh --schema .dev-wiki/assumption-ledger.md` exits 0
- [x] assumption-ledger append-only held through the phase (no deleted lines in `git log -p`)
- [x] `make template` regeneration idempotent (no uncommitted settings drift)
- [x] no `clean`-verdict matrix row whose command column lacks a backticked command
- [x] every `deferred` matrix row has a filed Blocker naming its area

All 10 pass via `eval/qa-sweep/run-exit-criteria.sh` (2026-06-09).

## Tasks

4 tasks (M/M/L/M, see tasks.md): T1 controls-first baseline + matrix skeleton → T2 8-area READ-ONLY candidate fan-out → T3 orchestrator-only verification + mid-phase findings report + serialized fixes → T4 matrix close-out + deferred filings + exit-criteria run.

## Notes

- A 6-file installed-copy drift (pre-Phase-81 dev-plan/dev-debrief in ~/.claude) was found and resynced during planning; `check-install-drift.sh --count` = 0 at planning time.
- First live dogfood of the Phase-81 assumption-approval gate (positions REPLACE approach-approval; ledger block required).
- Frozen measurement apparatus (eval/amplifier/*, eval/assumption-screen/) is read-only — findings there are filed, not fixed.
- OUTCOME (2026-06-09): 4/4 tasks [x]; 58 candidates → 35 fixed / 20 deferred-with-filings / 3 orphans; the >10-defects STOP fired, Jake re-scoped (all 4 clusters); enforcement layer restored from 15-day dormancy ([[hook-event-shape-normalization]]); drift pass 2b + 11 stale ~/.claude copies refreshed ([[drift-compare-installed-presence]]); reviewer 9/10 ACCEPT, findings fixed inline. READY FOR COMPLETION — delivery gate pending.
