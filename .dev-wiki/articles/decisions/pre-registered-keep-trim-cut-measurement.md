---
title: "Pre-registered teeth-having keep/trim/cut measurement (Phase 59)"
aliases: ["pre-registered-measurement", "teeth-having-measurement", "keep-trim-cut-rule"]
category: decisions
tags: [measurement, eval, residual-delta, llm-as-judge, pre-registration, subtraction-test, keep-trim-cut, dev-plan-step-2-7]
parents: [phase-59-validate-research-delta]
created: 2026-05-28
updated: 2026-05-28
source: plan
confidence: high
---

## Context

Phase 58 left dev-plan's Step 2.7 (active domain research) with a +0.5 composite residual delta at n=1: single run, on a deliberately research-FAVORABLE topic, and reasoning-only (decision_quality flat 4→4, reasoning_quality 3→4). That is at the significance threshold with unknown variance against a judge whose inter-run mean ranges 2.97–4.85. A keep/trim/cut decision resting on that number would be both under-powered and easy to bias toward "keep" — the feature is already shipped, so inertia and motivated reasoning both favor keeping it. The decision needed structural defenses against self-serving conclusions, not just more runs.

## Decision

Make the measurement non-self-serving by construction:

- **Pre-register first, machine-gated ordering.** Topics + each topic's falsifiable web-richness classification + the full keep/trim/cut decision rule are written into `eval/research-measurement/results.md` BEFORE any approach is generated or any score seen. Ordering (pre-registration block precedes results) is enforced as a grep gate — not a convention.
- **Burden of proof on the feature.** KEEP requires affirmative satisfaction of every gate; absence of disproof is not KEEP. Inconclusive ⇒ lean CUT, never default KEEP. The written verdict quotes the mean/spread it is keyed to.
- **Research-poor topic is a VETO, not an average term.** A real-negative delta on the research-POOR-but-gate-firing topic forces TRIM/CUT even if rich topics win. The poor topic does ~80% of the decision work, so ≥1 verified-thin-but-fires topic is mandatory (run FIRST behind a checkpoint).
- **Variance is a hard inconclusive-gate.** ≥3 runs/condition/topic floor; escalate to 5 if within-topic spread > |delta|; if still >, declare variance-dominated ⇒ trim/cut. Within-round paired deltas only (cancels the judge's large baseline variance); never pool cross-round absolute scores.
- **Diagnose poor-topic nulls via `injected_findings_count`.** Δ≈0 with injected_findings_count>0 ⇒ judge filtered junk ⇒ TRIM signal (production has no judge). Δ≈0 with injected_findings_count=0 ⇒ gate correctly injected nothing ⇒ keep-compatible. Record which.
- **Cost enters the ledger.** Net quality delta is weighed against per-fire cost (tool calls, latency, injected tokens); a true +0 on a fired topic is net-negative.
- **Qualified keep + length control.** Per-dimension scores reported — a KEEP resting on a reasoning-only lift is a qualified keep. On the KEEP-on-rich path, B−A must beat C−A where C is a length-matched-irrelevant control on the linchpin topic.

Alternatives considered & rejected: (a) symmetric n-sweep without poor-topic emphasis — rejected, the poor topic does ~80% of the decision work; (b) composite-only scoring — rejected, a reasoning-only lift must surface as a qualified keep; (c) cross-model judge — deferred to a future lever (deliberately-excluded alternative, noted as a scope call).

## Consequences

The keep/trim/cut call becomes defensible and auditable: anyone can read the pre-registration block, then the results, and check the verdict was applied mechanically rather than reverse-engineered. The cost is real work up front (a pre-registration block, ~21–28 measurement runs, a length control only if KEEP-leans). It accepts that the outcome may be "cut a feature we already shipped" — that is the subtraction test working as intended, per [[measure-residual-research-delta]]. Directional, not publication-grade: n=3 topics × ≥3 runs answers keep/trim/cut, not a significance claim.
