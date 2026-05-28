---
title: "Two-Phase Eval Methodology"
aliases: [two-phase-eval, blind-agent-eval]
category: decisions
tags: [eval, methodology, reasoning, calibration]
parents: [phase-50-eval-advancement]
created: 2026-05-27
updated: 2026-05-27
source: debrief
confidence: high
---

## Context

Single-call eval (agent sees expert answers in context) produces 100% ceiling -- 20/20 scenarios at 5/5/5. The model has access to the expert's recommended approach and simply paraphrases it, making the eval useless for differentiation. This was discovered when all scenarios scored perfectly regardless of IRON RULES injection condition.

## Decision

Two-phase eval: (1) agent generates recommendation blind to expert answers (only sees scenario context + question), (2) separate judge scores the agent response against expert answers. Alternatives rejected: modified single-call with instructions to not peek (model still has answers in context), separate agent/judge subagents with shared context (still contaminates agent reasoning).

## Consequences

All future eval runs must use the two-phase protocol. Results from single-call runs are invalid for measuring differentiation. Cross-model judging (Haiku as judge) is compatible with two-phase and provides additional calibration. The two-phase design naturally supports different judge models without re-running the agent.
