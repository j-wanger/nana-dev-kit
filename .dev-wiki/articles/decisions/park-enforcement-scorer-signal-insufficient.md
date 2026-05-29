---
title: "Park the enforcement-firing scorer — signal-richness gate fails, two blockers are structural"
aliases: ["park-enforcement-scorer-signal-insufficient", "phase-66-direction", "signal-richness-gate-fails", "scorer-parked"]
category: decisions
tags: [eval-validity, measurement-before-optimization, subtraction-test, falsification, signal-richness, phase-66]
parents: [instrument-not-score-enforcement-firing-substrate, eval-validity-verdict, phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phase 65 shipped the enforcement-firing measurement substrate ([[instrument-not-score-enforcement-firing-substrate]]): 6 lifecycle hooks emit fail-open `{schema_version,ts,hook,action,reason,phase}` records to `.dev-wiki/enforcement.log`. Phase 66 was planned to build the "did-a-component-fire-and-change-an-action" scorer the [[eval-validity-verdict]] proposed — but explicitly **gated** on a falsification checkpoint moved up front: first confirm the log accrued *signal-rich* real data (distinct action-changing firings, not just trivial allows).

The gate was measured on 2026-05-29 and **failed decisively**. The honest move is not to build the scorer. This decision records the failed verdict, parks the scorer behind a re-checkable trigger, and redirects the phase to the long-open `audit-log` disposition (user-approved at the dev-plan direction gate, 2026-05-29).

## Decision

**Do not build the scorer this phase. Park it behind a design-gated, re-runnable trigger. Redirect build effort to the `audit-log` subtraction-test disposition.**

### The measured verdict — NOT-SCOREABLE

Of the entire `enforcement.log`, only **11 records are new-format** (`schema_version=1`): all from a **single hook** (`dev-wiki-scope-check`), **zero `block`** (action-changing) firings, only 7 `advisory` + 4 `skipped`, all stamped `phase:"65"` — 100% intra-phase self-traffic. The 253 `enforce-loop` + 23 `block` records that *look* like signal are all **pre-instrumentation legacy format** (no `schema_version`, no `phase`) and are not what a scorer consumes. (A separate `dev-debrief` writer adds off-roster `{event:"debrief",...}` records — a different schema sharing the file.)

The scorer is unbuildable for **four stacked reasons, three of which time does not fix**:

1. **Volume** — 11 new-format records, half a day of accrual. *(time fixes this)*
2. **Skew** — 0 `block` firings, 1 of 6 hooks, the other 5 silent. A predicate that counts raw rows is fooled by one prolific hook.
3. **Representativeness — STRUCTURAL.** This log lives in the *kit's own* `.dev-wiki/` and samples the maintainer editing the kit, never the consuming-project agentic work the enforcement governs. The kit's own log will **never** be a representative sample. *(time does not fix this)*
4. **Schema gap — STRUCTURAL.** The record captures the hook's *decision*, not the agent's subsequent *action*. "Change-an-action" needs a firing→response link no field carries. Even rich data can't yield an action-delta without a schema extension + a counterfactual. *(time does not fix this)*

(Liveness is not in doubt: `test_firing_log.sh` proves each of the 6 hooks emits a well-formed record when fired, so the 5/6 historical silence is "no cause to fire," not "broken write path.")

### The park — a runnable trigger, not a calendar note

The deferral is legitimate only because it is **falsifiable and re-checkable**: `scripts/signal-richness-probe.sh` is the committed gate. Its `SCOREABLE` verdict (≥2 distinct hooks AND ≥1 `block` firing, over `schema_version`-bearing records after tuple-dedup) is the trigger — green ⇒ revisit the scorer. But volume is *necessary, not sufficient*: the trigger also requires the two structural blockers to be resolved first —

- **Representativeness:** real consuming-project provenance (point the probe at an installed project's log, not the kit's own), and
- **Schema gap:** a record schema that captures the agent's subsequent action (a precondition for *any* action-delta scorer — design it, then re-open).

A "come back later" that can't be expressed as a runnable check is rejected; this one is the probe + these two named preconditions.

## Why (not the alternatives)

- **Build it anyway** — fails the subtraction test: a scorer over 11 one-hook, zero-block, self-traffic records measures nothing. "Measurement before optimization; don't optimize what you haven't measured."
- **Just wait for data** — addresses only reason (1). Reasons (3) and (4) are structural; the kit's own log never becomes representative and the schema never grows an action field on its own. Waiting in this repo is futile; the park names what must *change*, not merely accrue.
- **Subtract the whole line** — rejected by the user at the direction gate (Phase-65 substrate retains standalone observability value; the corpus + fail-open proof remain the eval of record). The park keeps the option open at near-zero carrying cost (one probe + two lines of recorded preconditions).

## Verified (T1)

`scripts/signal-richness-probe.sh` is committed and reproduces the verdict on the live log:
`METRICS total=270 new=11 new_deduped=6 duplicates=5 legacy=257 debrief=2 malformed=0 hooks=1 blocks=0` → **VERDICT: NOT-SCOREABLE**. The trigger is therefore a runnable artifact, not a prose note — `bash scripts/signal-richness-probe.sh` re-checks the gate in one command. (The `duplicates=5` confirms the suspected byte-identical doubling — 11 raw new-format records collapse to 6 distinct tuples; the hook calls its logger once per path and is registered once, so this is not a hook-code bug, and the probe dedups it regardless.)

## Source

Phase 66 planning, 2026-05-29. Measured against the live `.dev-wiki/enforcement.log`. Adversarial spec review (7/10→revise→incorporated) verified the falsification against the real log and surfaced the off-roster writer + the suspected double-emit (every multi-event new-format timestamp appears exactly twice). Builds on [[instrument-not-score-enforcement-firing-substrate]] (fixture-replay ≡ corpus) and [[eval-validity-verdict]] (`instrument: mixed`).
