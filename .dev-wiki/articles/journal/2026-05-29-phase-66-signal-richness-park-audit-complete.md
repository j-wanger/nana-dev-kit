---
title: "Phase 66 complete — Signal-Richness Falsification + Scorer Park + audit-log Disposition"
date: 2026-05-29
category: journal
tags: [eval-validity, falsification, signal-richness, park, audit-log, subtraction-test, phase-66]
phase: 66
---

# Phase 66 — Signal-Richness Falsification + Scorer Park + audit-log Disposition

Planned AND implemented in one session. The phase Jake invoked `/dev-plan` for ("build the scorer, gated on signal-richness") **resolved at the falsification checkpoint, not the build** — and that's the result worth having.

## What happened

The Phase-66 scorer (the "did-a-component-fire-and-change-an-action" with/without-feature delta) was gated on a signal-richness checkpoint moved up front. The gate **failed decisively** when measured against the live `.dev-wiki/enforcement.log`: only 11 (later 19, as this session's own editing accrued more) new-format `schema_version=1` records, all from a **single hook** (dev-wiki-scope-check), **zero `block`** firings, all `phase:"65"` intra-phase self-traffic. The 253 enforce-loop + 23 block records that *look* like signal are all pre-instrumentation legacy format (no `schema_version`).

Unbuildable for **four stacked reasons, two structural** (time won't fix them):
1. volume; 2. skew (0 blocks, 1 of 6 hooks);
3. **representativeness** — the log lives in the *kit's own* `.dev-wiki`, sampling the maintainer editing the kit, never the consuming-project agentic work enforcement governs;
4. **schema gap** — the record captures the hook's *decision*, not the agent's subsequent *action*; an action-delta is uncomputable without a schema extension + a counterfactual.

So the phase became **falsify + park + redirect** (approved at the dev-plan direction gate after a 3-way AskUserQuestion fork):

- **T1** — shipped `scripts/signal-richness-probe.sh`, a read-only deterministic gate that re-checks "is the scorer buildable yet?" in one command (classify new/legacy/debrief/malformed; predicate ≥2 hooks ∧ ≥1 block over schema_version-bearing records after `{hook,ts,action,reason}`-tuple dedup; emits SCOREABLE / NOT-SCOREABLE / NO-DATA / CORRUPT). 14-test functional-smoke; wired into `make test`.
- **T2** — parked the scorer behind that *runnable* trigger (not a calendar note) + recorded the 4-reason verdict naming both structural blockers, in `_CURRENT_STATE.md` Blockers + a decision article + active-knowledge.
- **T3** — resolved the long-open `audit-log` wire-or-cut (the redirect): **KEEP + harden**. The hook functions (eval-covered) and writes a human-facing forensic trail (`.nana/audit.jsonl`, "which model edited which file when") — judged by its *intended human consumer*, not by grepping for in-repo readers. While keeping, hardened the lone remaining raw-`printf` JSON interpolation of `$FILE_PATH` to `jq --arg` (fixing a latent JSONL-injection — same class Phase 65 fixed in the enforce loggers), added a functional-smoke the eval lacked (it only checked exit code), and reconciled the over-broad `file-lifecycle.md` claim.
- **T4** — full regression gate.

## Decisions

- [[park-enforcement-scorer-signal-insufficient]] — signal-richness gate fails; park the scorer behind a runnable probe-trigger; 2 of 4 blockers are structural. (high)
- [[audit-log-disposition]] — KEEP + harden; a human-facing forensic trail is not code-dead; the Phase-64 "write-only ⇒ deadweight" rule doesn't apply (those counters fed a *dead automated* reader). (high)

## Review Gate

Unified reviewer (Standard + 4 tasks) on the changeset: **7/10 SHIP-WITH-FIXES** → now clean SHIP. Found 2 real bugs, both fixed + regression-tested:
- **[CRITICAL]** the probe crashed (not classified) on a valid-JSON-but-non-object line (`42`, `[1,2]`, `null`) — `try fromjson catch` succeeds on a scalar, then `select(.__malformed__==true)` aborts jq under `set -e`. Fixed: `try (fromjson | if type=="object" then . else {malformed} end)`. New test case 14.
- **[HIGH]** `audit-log.sh`'s `mkdir -p .nana` was unguarded — aborted exit 1 on an unwritable dir despite the new fail-open comment. Fixed: `mkdir -p .nana 2>/dev/null || true`. New fail-open regression test.
- 2 LOW (null-hook count hardening; stale "14 scripts" in spec) also fixed.

The earlier adversarial spec review (7/10) also caught a wrong exit-criterion grep (`printf.*file_path` matched nothing — the code uses `"$FILE_PATH"`) before any code was written.

## Health Delta

- `make test`: 13 → **15** test scripts (+`test_signal_richness_probe.sh` 14 tests, +`test_audit_log.sh` 6 tests). All green.
- `make eval`: **52/52** unchanged (audit-log KEPT → no scenario deletion).
- `test_registration` 41/41, `test_settings_template` green, `harness-audit` DRIFT=none / MATCH=ok (INVENTORY 87→89).
- Net additive (probe + 2 tests + park records + hardening); no deletions.

## Soft Observations / Phase N+1 Candidates

- **The scorer's two structural preconditions are the real future work, IF revisited:** (a) extend the firing-record schema to capture the agent's *subsequent action* (a firing→response link) — a prerequisite for any action-delta; (b) point the probe at a *real consuming-project* log (the kit's own log is structurally unrepresentative). Both are recorded in the park; neither is "wait for more data."
- **Remaining Phase-63 roadmap items** ([[phase-63-remediation-roadmap]]): session-start.d author-global drift (install.sh line 92 already copies `extra_dirs/*.sh` — likely a verify-and-close, not a fix); long-cadence hook firing tests (pre-compact/post-compact/session-stop/stale-queue lack firing tests — a real coverage gap, but fiddly).
- **The probe could become a `make` target or a harness-audit mode** if re-checking the gate becomes routine; for now a standalone script is right.

## Activation Quality

Active knowledge: 4 entries (park verdict ×2, audit-log disposition, data-quality findings). All 4 were referenced this session (the phase was built directly from them) — ~100% hit rate. Healthy.

## Gate Compliance

`gate-log:phase-66 direction=approved delivery=<pending→accepted on this debrief>`. Direction gate approved 2026-05-29 (AskUserQuestion fork). Delivery gate: presented at debrief.
