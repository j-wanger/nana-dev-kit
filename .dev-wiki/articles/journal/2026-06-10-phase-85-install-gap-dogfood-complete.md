---
title: "Phase 85 complete — Install-Gap Fix + Edge-Screener Dogfood: hook_dirs shipped on every path, checker directory currency, edge-screener single-registration migration, A5 zero-demand evidence"
aliases: [phase-85-debrief]
category: journal
tags: [install, hooks, drift, dogfood, edge-screener, memory-mcp, a5, drq-1]
parents: [phase-85-install-gap-dogfood]
created: 2026-06-10
updated: 2026-06-10
source: debrief
duration: ~3.5 hours (single session: plan + implement + debrief)
---

# Phase 85 complete — Install-Gap Fix + Edge-Screener Dogfood

## What Happened
- ALL 8 tasks [x]; exit criteria 9/9 via `eval/install-gap/run-exit-criteria.sh`. Five serialized stages executed as planned.
- **T1** install-path inventory: causal-path verdict **confirmed** — incident 5 was the Phase-82 drift-guided resync using the dir-blind checker as its shopping list; py-init/ts-init exempt (recursive copy), nana-init exempt (no-copy).
- **T2-T3** kit fixes: modules.json `project_local.extra_dirs` → top-level `hook_dirs` map (4 consumers migrated, zero old-key references remain); install.sh `ship_hook_dirs` helper on BOTH paths (consumer-conditioned, find-based, empty-glob tolerant; 3 new sandbox assertions).
- **T4** checker directory-currency cells + orphan flagging (`tests/test_install_drift_dircurrency.sh`, 7 seeded controls, Makefile-registered → 26 test scripts). DISCOVERY: latent bash-3.2 set-u empty-array crash in the checker, fixed with the `${arr[@]+...}` idiom.
- **T5** rehearsal GREEN → HARD checkpoint 1 approved (A1 confirmed; A3: **keep-current**) → live ~/.claude run (backup-phase85-20260610-093320.tgz, tested restore); post: drift 0, scope:global set equality.
- **T6** DRQ-1 verification (verdict: **string-keyed dedupe**, 2 headless probes with positive controls) → HARD checkpoint 2 approved → edge-screener migration: settings.json → `{}`, --project-local install, 17/17 basenames exactly once, firing probe each Stop hook exactly once; .bak deleted (superseded by backup-phase85-20260610-094413.tgz).
- **T7** dogfood: 2 real headless edge-screener work sessions (USER OVERRIDE: agent-driven per the spec's provenance-noted fallback; recorded in dogfood-evidence.md ## Provenance note) — post-migration baseline exact match (390 tests / 94.44% cov); Phase-10 candidate analysis written to edge-screener's .dev-wiki. A5: liveness probe exit 0, DB absent (row count 0) → zero voluntary memory use = genuine demand evidence, FILED.
- **T8** close-out: inventory rows finalized, eval-diff zero flips (52/52), 9/9 criteria.

## Decisions Made
- [[drq-1-settings-merge-semantics-are-string-keyed|DRQ-1: settings merge semantics are string-keyed dedupe]] — extracted this session
- [[a3-disposition-keep-current-for-registration-dead|A3 disposition: keep-current for registration-dead ~/.claude copies]] — extracted this session
- [[install-gap-dir-currency]] updated: A1 deferred don't-know RESOLVED to confirmed at checkpoint 1 (ledger row `held`)

## Problems Solved
- harness-audit.sh 3 stale 4b predicates false-DRIFTed against ship_hook_dirs + the Phase-74 recursive dot-copy — fixed at the review gate, verified DRIFT: none.
- bash-3.2 set-u empty-array crash in check-install-drift.sh — surfaced by the minimal sandbox kit, fixed within T4 scope.

## Review Gate
Reviewer 8/10, verdict revise. **HIGH**: harness-audit.sh:374 stale predicate false-DRIFTed after the T2/T3 migration (instrument-dead class) — FIXED inline (all 3 stale 4b predicates). **MEDIUM fixed**: assert-global-set.sh set-vs-multiset (seeded-duplicate control now exits 1); rehearsal fixture deviation RECORDED in checkpoint-1.md. **MEDIUM acknowledged**: _CURRENT_STATE 212-line pre-existing overage; pre-debrief staleness (reconciles in this debrief). Suggestions: DRQ-1 → working-knowledge ADOPTED; harness-audit 4b seeded control + checker dedup guard FILED as soft observations. Post-fix regression: test_scripts_smoke 4/4, exit criteria 9/9.

## Health Delta
- make test: 25 → 26 scripts, all green (~500 assertions + 7 seeded controls + 3 install assertions).
- make eval: 52/52, denominator unchanged, ZERO flips (eval/install-gap/eval-diff.md).
- Live ~/.claude: drift 0 WITH directory cells active; kit hooks == modules.json scope:global set.
- edge-screener: single-registration template-sourced install; 390 tests / 94.44% cov / mypy / ruff — exact pre-migration baseline.

## Artifacts Changed
- `modules.json` (extra_dirs → hook_dirs map), `install.sh` (ship_hook_dirs both paths), `scripts/check-install-drift.sh` (directory cells + orphan rows + bash-3.2 safety), `scripts/harness-audit.sh` (3 stale 4b predicates)
- `tests/test_install_drift_dircurrency.sh` NEW (26th script), `tests/test_install.sh` (+3), `Makefile`, README (25→26 count)
- `eval/install-gap/` NEW (inventory, rehearsal, checkpoints 1-2, drq1-verification, dogfood-evidence, assert scripts, run-exit-criteria 9/9)
- Out-of-repo (checkpoint-approved): `~/.claude` (live run), `/Users/jwang/edge-screener` (migration + dogfood + phase-10-candidate-analysis.md)

## Soft Observations / Phase N+1 Candidates
- check-tests-were-run.sh false positive with bite (Read .py triggers the nudge on read-only work; cost a 390-test re-run, 3 Stop cycles) | harden: key trigger on Edit/Write, not Read | eval/install-gap/dogfood-evidence.md session 2 (filed to Blockers)
- A5 demand evidence: consuming project generates ZERO voluntary memory-layer use, liveness-probed | next prune-on-value round input | eval/install-gap/dogfood-evidence.md (filed to Blockers)
- harness-audit.sh 4b DRIFT block lacks a seeded control — a stale predicate reads as project drift instead of instrument failure | seeded-control harden | this phase's review-gate HIGH is the evidence
- check-install-drift.sh section-2 set has no dedup guard (a script registered for two events would double-count drift rows; harmless today) | cheap guard | review-gate suggestion
- enforcement.log rows carry decision:null for all hooks — firing log still doesn't record allow/block distinctly | Phase-66 schema-gap echo | surfaced extracting dogfood evidence
- Headless `claude -p` sandbox sessions = cheap empirical probe for undocumented platform semantics (the DRQ-1 method) | reusable measurement method, wiki-capture candidate | eval/install-gap/drq1-verification.md
- _CURRENT_STATE.md at 212 lines vs 100 budget (pre-existing; Blockers is the bulk) | curation candidate | size-budgets.md

### Activation Quality
active-knowledge.md: 3 source sections, ~11 bullets. Hit rate 3/3 sections, ~11/11 bullets (~100%) — the install.sh/checker/register-settings line-cites drove T1-T4 directly; the DRQ-1 no-record bullet was consumed by T6 (its double-fire working model falsified, exactly its declared purpose); the couldnt-fire trap + A5 evidence-not-disposition bullets shaped T7; the scope:global set-equality + positive-control bullets shaped T5. No dead sections.

### Retro Check (Phases 81-85)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 2 classes: instrument-validity hazards (Ph82 seeded-control mandate, Ph83 4-of-6 measurement-artifact zeros, Ph84 zsh false 0/11 matrix + fixture circularity, Ph85 harness-audit false-DRIFT HIGH); registered-but-broken installs (5th instance Ph84 → structurally fixed Ph85) | high |
| 2. Decision Reversals | 3 ledger `bit` rows in 5 phases (Ph83 A2 zeros-measure-demand, Ph84 A1 detect-loop signal, Ph85 A2 double-fire) — every one absorbed by a pre-declared verification branch, none forced rework | high count, low damage |
| 3. User Corrections | Concentrated at gates/checkpoints, not mid-implementation: Ph82 A2 reject + >10-STOP re-scope; Ph83 A3 reject (vindicated) + 3 checkpoint overrides; Ph85 keep-current at checkpoint 1 | high |

Recommendations:
- Keep mandatory-empirical-verification attached to every accepted high-cost working model — 3/3 `bit` rows were caught by exactly that pattern (arming gate, capture-first, DRQ-1 probe).
- Instrument-validity is the dominant blocker class: standardize seeded/positive controls for ALL audit instruments (harness-audit 4b is the open gap — soft obs filed).
- Prune-on-value round 2 inputs have accumulated across 3 phases (A5 zero-demand, registration-dead copies, detect-loop, check-tests-were-run, Ph82 residue) — schedule it before the evidence decays (Ph83 lesson: filed utilization evidence DECAYS).

## Related
- [[phase-85-install-gap-dogfood|Phase 85: Install-Gap Fix + Edge-Screener Dogfood]] -- parent phase
