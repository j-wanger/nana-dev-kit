---
title: "Phase 66: Signal-Richness Falsification + Scorer Park + audit-log Disposition"
aliases: ["phase-66-signal-richness-park-audit", "phase-66"]
category: phases
tags: [eval-validity, measurement-before-optimization, falsification, signal-richness, subtraction-test, park, audit-log]
parents: [phase-63-remediation-roadmap, instrument-not-score-enforcement-firing-substrate]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope: ["scripts/signal-richness-probe.sh", "tests/test_signal_richness_probe.sh", "tests/test_audit_log.sh", "Makefile", "templates/.claude/hooks/audit-log.sh", "templates/.claude/hooks/dev-wiki-scope-check.sh", "modules.json", "templates/.claude/settings.json", "install.sh", "templates/.claude/rules/file-lifecycle.md", "README.md", "eval/README.md", "self-test.md", "scripts/harness-audit.sh", "tests/test_install.sh", "tests/test_templates.sh", "eval/corpus/hook-audit-log-*/**", "eval/corpus/lifecycle-full-session-flow/**", ".dev-wiki/**", ".claude/rules/**"]
entry_criteria: "Phase 65 complete + committed; spec specs/phase-66-signal-richness-park-audit.md nana:approved 2026-05-29 (Tier-1 7/10 → fixes incorporated); direction confirmed 2026-05-29 (falsify + park + redirect, after the signal-richness gate failed decisively — scorer unbuildable, 2 of 4 blockers structural)"
exit_criteria: "signal-richness-probe emits SCOREABLE/NOT-SCOREABLE/NO-DATA/CORRUPT + real log returns NOT-SCOREABLE + functional-smoke test green and in make test (14 scripts); scorer parked with the runnable-probe trigger + 4-reason verdict naming both structural blockers (representativeness, schema-gap) in Blockers + decision article + active-knowledge (NO scorer code); audit-log disposition DECIDED with written rationale (verdict + named human consumer + raw-path handling) and executed (keep: tests/ smoke + doc reconcile; cut: full ref-sweep + 2 scenarios deleted → make eval 50 + lifecycle rewire + no dangling refs); make test green / make eval at expected count / test_registration + test_settings_template green; referential integrity intact"
---

# Phase 66: Signal-Richness Falsification + Scorer Park + audit-log Disposition

## Objective

Verify deterministically whether the enforcement-firing log has accrued enough real signal to build a "did-a-component-fire-and-change-an-action" scorer; since it has not, ship a re-checkable probe that encodes the gate, park the scorer behind a design-gated trigger, and resolve the long-open `audit-log` disposition. No scorer is built this phase. See [[park-enforcement-scorer-signal-insufficient]] and [[instrument-not-score-enforcement-firing-substrate]].

## Scope

Build `scripts/signal-richness-probe.sh` (read-only deterministic reporter over `enforcement.log`) + its functional-smoke test (→ `make test` 14th script). Record the failed verdict + a runnable-probe trigger in the Blockers/decision-article/active-knowledge. Dispose of `audit-log` on subtraction-test evidence (the hook functions + is eval-covered; `.nana/audit.jsonl` has no code consumer, only human forensic use): decide keep-or-cut, execute the chosen path with a full reference sweep. **Out:** any scorer code (no with/without run, no graded eval scenario); extending the firing-record schema (a future precondition, only *recorded* here); re-tracking/truncating `enforcement.log`; promoting `.nana/audit.jsonl` into the firing-log family.

## Exit Criteria

See the spec (`specs/phase-66-signal-richness-park-audit.md`) for the machine-checkable list. Headline gates: probe emits the four-state verdict + real log → NOT-SCOREABLE; `test_signal_richness_probe.sh` green and wired into `make test` (14 scripts); scorer parked (verdict + both structural blockers + runnable trigger, no scorer code); audit-log decided + executed (registration + generated-settings invariants intact; `make eval` at the count implied by keep/cut); referential integrity intact.

## Constraints

No silent scorer rebuild (read-only count/classify only; no ON/OFF harness run, no new graded `eval/corpus/*`). Signal predicate computed over `schema_version`-bearing records only (≥2 distinct hooks AND ≥1 `block`, after full-tuple dedup) — rejects the degenerate one-hook/zero-block sample. `schema_version` (not `phase`) is the new/old discriminator. Three distinct negative verdicts (NO-DATA ≠ NOT-SCOREABLE ≠ CORRUPT at >50% unparseable). Don't delete the human-facing audit trail by code-utility; don't reintroduce audit-log's raw-`$FILE_PATH` surface into the firing log. audit-log disposition reconciles ALL coupled surfaces atomically (regenerate `settings.json` via `make template`, never hand-edit).

## Abort Rule

Probe can't deterministically separate new-format from legacy records → STOP (falsification not reproducible, park unfounded). audit-log CUT would dangle a working/active-knowledge link or a test depends on the target → STOP, reconcile (or choose KEEP). `make eval` lands on an unexpected count or `test_registration` regresses → revert. Do NOT reintroduce a scored fixture eval (settled = corpus-duplication). Blocked >3 attempts → mark [blocked:], report, ask skip-or-abort.
