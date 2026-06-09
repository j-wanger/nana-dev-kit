---
title: "Phase 80: Assumption-Surfacer Completeness Screen"
aliases: ["assumption-surfacer-completeness-screen", "phase-80-assumption-screen", "assumption-gate-screen"]
category: phases
tags: [assumption-interrogation, blind-yes, surfacer, completeness, screen, scope-anchored, framing-pass, cost-of-error, amplifier, circularity]
parents: []
created: 2026-06-09
updated: 2026-06-09
source: plan
status: active
scope: ["eval/assumption-screen/**"]
entry_criteria: "Phase 79 complete/accepted. A handover doc + a team-upskilling conversation proposed reframing the dev-plan human gate from approving the APPROACH to taking accept/reject/don't-know positions on the plan's load-bearing ASSUMPTIONS. The plan was interrogated live via that very mechanism; Jake ACCEPTED 3 assumptions and REJECTED A2 ('can't trust the agent-CHOSEN assumption set — solve set-completeness before building anything'). The reject makes Phase 80 a SCREEN, not a build."
exit_criteria: "eval/assumption-screen/ carries a committed ancestor-guarded pre-registration + a deterministic NO-LLM check.sh (--selftest both-ways) + a screen-record.md with a closed-vocabulary ^PROGRAM-VERDICT (TRUSTWORTHY | UNTRUSTWORTHY | INSTRUMENT-DEAD). Either: T1 returns INSTRUMENT-DEAD (non-circular ground truth not constructible) and the phase stops cheap; OR the surfacer is scored against outcome-determined ground truth + a blind baseline + a cost-sort-adversarial control, and the verdict gates whether Phase 81 builds the gate/ledger/all-accept block."
---

# Phase 80: Assumption-Surfacer Completeness Screen

## Objective
EARN the right to build the assumption-approval gate. Jake's live A2 reject made set-completeness a
blocking precondition, so Phase 80 validates a scope-anchored assumption surfacer against NON-CIRCULAR
controls before any gate depends on it. The screen's real question (post-review reframe): **does the
scope+framing surfacer BEAT a blind (outcome-unaware) baseline at recovering assumptions the project's own
history later PROVED load-bearing?** Ground truth is outcome-determined + mechanically extracted, not
author-selected (author-selected = the agent-internal review's CRITICAL circularity finding). Structurally
the amplifier's harness-vs-baseline question; `surfacer ≈ baseline` is a legitimate 5th-null TERMINATE,
pre-registered up front. The gate + ledger + all-accept block defer to Phase 81, gated on this verdict.

## Scope
- NEW repo-only `eval/assumption-screen/` (amplifier program is closed; this is a new line). NOT wired
  into install.sh / Makefile / make test / make eval.
  - `spike/` — circularity-escape feasibility (T1 GATE).
  - `pre-registration.md` + `.prereg-commit` — verdict rule + variance-derived bar procedure, ancestor-guarded.
  - `surfacer.md` + `coverage-check.sh` — scope-anchored + framing surfacer, deterministic coverage-property check.
  - `fixtures/` + `checks/` — mechanical ground truth + blind-baseline + planted pos/neg + cost-sort-adversarial.
  - `check.sh` (cloned from `eval/amplifier/anchor-screen/check.sh`, NO LLM, `--selftest`) + `runs/` + `verdicts/`.
  - `screen-record.md` — `^PROGRAM-VERDICT`.
- UNTOUCHED: dev-plan SKILL.md, any ledger, the all-accept block (all Phase 81).

## Exit Criteria
- [ ] T1 GATE resolved: `spike/feasibility.md` with `DECISION: GO` (≥3 phases' non-circular labels) or `DECISION: INSTRUMENT-DEAD` (stop cheap)
- [ ] Pre-registration committed BEFORE scoring runs; `.prereg-commit` an ancestor of the verdict commit (anti-retrofit)
- [ ] `bash eval/assumption-screen/check.sh --selftest` exit 0 (deterministic, NO LLM in scoring)
- [ ] cost-sort-adversarial control present + scored
- [ ] `screen-record.md` carries `^PROGRAM-VERDICT: (TRUSTWORTHY|UNTRUSTWORTHY|INSTRUMENT-DEAD)` + the surfacer-vs-baseline result + named limits + the Phase-81 gate consequence

## Key Decisions
- [[assumption-surfacer-completeness-screen]] (low→pending) — the full rationale: the four live verdicts,
  the review's CRITICAL circularity finding, the surfacer-beats-blind-baseline reframe, the spike-first
  gate, the two-track verdict, the cost-sort-adversarial control, the cuts (signature-detector,
  exogenous interrogator).

## Abort Rule
If blocked >3 attempts on a task, mark [blocked] in tasks.md + ask the user skip/abort. T1 INSTRUMENT-DEAD
is NOT a block — it is a valid cheap terminal outcome that stops the phase honestly.
