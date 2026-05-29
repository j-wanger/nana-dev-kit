---
title: "Run measurement fan-out as a Workflow (Phase 59)"
aliases: ["measurement-fan-out", "workflow-fan-out", "ab-judge-fan-out"]
category: decisions
tags: [measurement, workflow, fan-out, orchestration, subagents, dev-plan-step-2-7]
parents: [phase-59-validate-research-delta]
created: 2026-05-28
updated: 2026-05-28
source: plan
confidence: high
---

## Context

The Phase 59 measurement needs roughly 21–28 subagent runs: per topic, ≥3 clean-context A (objective-only) generations + ≥3 B (objective + injected findings) generations + a blind judge pass, across ≥3 topics, with possible escalation to 5 runs and an optional length-matched-irrelevant control. Running these as serial individual Agent dispatches is slow and bookkeeping-heavy. The user explicitly opted into Workflow orchestration for this phase.

## Decision

Execute the measurement fan-out via the Workflow tool. The research findings for each topic are gathered ONCE per topic (the feature's real output) and reused across that topic's B-runs. The research-POOR topic runs FIRST behind a human checkpoint (spec Checkpoint 2): its result is load-bearing (the VETO term), so it gates whether the rich-topic runs proceed at all. Rich topics fan out after the poor-topic checkpoint clears.

Alternative considered & rejected: serial individual Agent dispatches — rejected for efficiency given the run count and the user's explicit opt-in.

## Consequences

Faster wall-clock and cleaner aggregation. The poor-first ordering means a clear poor-topic VETO can short-circuit before spending the rich-topic budget. Clean-context isolation per run is preserved (each subagent naturally lacks the planner's context), satisfying the blind-judge / fresh-environment requirement convergent with Anthropic's "Demystifying evals" guidance. Risk: Workflow run failures or non-determinism must be caught — any run that errors is re-dispatched, not silently dropped from the n.
