---
title: "Eval-validity verdict: instrument is MIXED — binary corpus sensitive, LLM-judge evals blind"
aliases: ["eval-validity-verdict", "phase-63-eval-verdict", "instrument-mixed"]
category: decisions
tags: [eval-validity, instrument-sensitivity, measurement, llm-judge, real-agentic-eval, subtraction-test]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Verdict token

`instrument: mixed`

Recorded probe delta: **54 → 53 → 54** (binary corpus eval). Disabling the `rm -rf` guard in `block-dangerous-bash.sh` flipped `hook-block-rm-rf` PASS→FAIL and the aggregate score 54→53; a byte-identical revert restored 54/54. Non-zero delta on a known-broken variant ⇒ that instrument has sensitivity.

## Context

The maintainer distrusted the apparatus that drove the Phase 58/59/61 cuts ("I don't feel that's the right setup"). Phase 63 settled it empirically rather than by assertion, per [[eval-validity-instrument-sensitivity-probe]]. Three apparatuses were characterized:
- **(a)** `eval/comparison/` — the A/B/C clean-room (stock-screener / task-tracker).
- **(b)** `eval/reasoning/` — 25-scenario LLM-as-judge.
- **(c)** `eval/corpus/` + `make eval` — 54 deterministic binary scenarios.

## Decision (the answer to "is our eval valid, and if not, what replaces it")

The instrument is **MIXED — and each half fails differently, exactly as predicted:**

- **(c) the deterministic binary corpus → SENSITIVE.** Proven by the live probe above. It gates *contracts* (exit codes, output patterns, file/section presence) which are fully observable, so a real defect deterministically flips a scenario. **Keep it as-is as the contract gate; it earns trust.**
- **(a)+(b) the LLM-judge evals → BLIND-by-construction at the n they were run.** The Phase 58/59/61 net-zero composite deltas (0.00, −0.40, −0.67) are all *strictly inside their own measured run-to-run spread* (0.79, 1.19, 2.0); the result files themselves label them "variance-dominated." The project's own "meaningful" bar (~+0.5) is *smaller than the noise floor*, so a true small-positive feature and a worthless one produce the **same observable**. As feature-gates these are uninformative.

**Crucial nuance (forced by adversarial verification):** the 58/59/61 CUTs were still *correct decisions* — but they rode a signal the instrument CAN resolve (Phase 59's poor-topic arm, delta=−1.0 > spread=0.5, a real traced negative + a pre-registered VETO + burden-of-proof-on-the-feature), **NOT** the blind rich-topic zeros they also cite. So the maintainer's distrust of (a)/(b) *as feature-gates* is correct; the decisions themselves stand on separate, resolvable evidence.

## Proposed replacement (PROPOSE-not-build — see roadmap)

Replace synthetic self-graded reasoning scenarios with a **dogfood real-workflow eval** keyed on already-logged observables — measure the *action a component took*, not a judge's opinion of prose.

- **Minimal non-blind observable:** *did-a-component-fire-and-change-an-action* (binary, deterministic — structurally like the corpus probe).
- **Substrate already exists (zero new code):** `.dev-wiki/enforcement.log` (244 lines, 23 real block actions + timestamps); git phase-commit cadence + revert/fixup count per phase (time-to-green / rework proxies); `detect-loop` `.loop-state` (repeated-failure counts).
- **Small new instrumentation:** tag each `enforcement.log` line with the active phase/feature-flag so a with/without-feature delta is computable.
- **Eval contract:** toggle a feature OFF, run a fixed scripted agentic task, assert the block-count delta is non-zero and time-to-green/rework regresses — a deterministic before/after on observed actions, **no LLM judge in the scoring path.**
- **Disposition of the old apparatuses:** keep (c); demote (b) to a calibration tool only (never a feature gate) unless run at n large enough that spread < the decision threshold; retire (a)'s confounded A-vs-C arm.

## Consequences

The recurring "measured, ambiguous, deferred" cycle is broken by characterizing the *instrument* rather than producing more verdicts from a blind one. Building the real-agentic eval is deferred to Phase 64+ (see [[phase-63-remediation-roadmap]]) and gated on this `sensitive`/`mixed` result + maintainer approval, per the propose-not-build scope of [[harden-hot-cache-curation-deterministic|the governing spec]]. Governed by [[eval-validity-instrument-sensitivity-probe]], [[deadweight-requires-affirmative-evidence]].
