---
title: "Deterministic success criteria over eval ceremony for mechanical changes"
aliases: ["deterministic-success-over-eval-ceremony", "no-judge-eval-for-deterministic-change"]
category: decisions
tags: [subtraction-test, eval, deterministic, process-theatre, validation, harness]
created: 2026-05-29
updated: 2026-05-29
confidence: high
source: plan
phase: 60
---

# Deterministic success criteria over eval ceremony for mechanical changes

## Decision

For a change whose output is byte-identical given identical inputs — dedup, reorder, a line cap, a conditional advisory line in a shell hook — the rigorous validator is **structural assertions + bidirectional firing tests**, NOT a judge-scored A/B eval. Do not manufacture an eval for a deterministic change.

## Why

Phases 58–59 used judge A/B evals because they changed **reasoning behavior** and the open question was an **effect size** only a judge could estimate. A judge has measured inter-run variance (mean 2.97–4.85 on identical conditions). Applied to a deterministic transform, that judge adds variance to *launder*, not signal — it cannot reveal anything a `grep`/`awk`/`wc`/firing-test cannot reveal exactly and re-runnably in one command.

This is the subtraction test applied to **validation ceremony**, not just to features: an eval that cannot improve the confidence of a deterministic result does not earn its complexity. Same lens that produced the Phase 59 CUT ([[cut-active-research-step-2-7]]) — "does this earn its complexity?" — says *don't add* eval ceremony here.

## When this applies

- The change is a refactor/dedup/reorder/cap, or a deterministic hook/config edit.
- Success can be stated as a command that returns 0/1 with no model in the loop.

## When it does NOT apply (use a judge eval)

- The change alters what the model *reasons or generates* (prompt/spec/injection changes), and the question is whether quality moved — then judge A/B with ≥3 runs/condition, within-round paired deltas, and a variance gate (the Phase 58–59 methodology) is the right instrument.

## Boundary discipline

When a deterministic change sits on top of an unverified *behavioral* claim (e.g. AGENTS.md:84 "~300 always-loaded lines degrade instruction-following"), do not fake-test the behavioral claim with the deterministic change's tests. Carve it out as a separate research-phase candidate and say so explicitly — neither ignore it nor launder it.

## Related

- [[cut-active-research-step-2-7]] — the precedent for killing un-earned complexity by measurement
- [[measure-residual-research-delta]] — when a with-vs-without measurement IS the right functional test (behavioral change, no binary runner)
- nana-soul: "deterministic validators at boundaries over neural judges at the end"
