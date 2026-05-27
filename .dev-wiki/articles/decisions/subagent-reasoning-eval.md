---
title: Subagent-Based Reasoning Eval
aliases: []
category: decisions
tags: [eval, reasoning, subagent, methodology]
parents: [phase-44-heuristic-learning-foundation]
created: 2026-05-26
updated: 2026-05-26
source: debrief
confidence: medium
---

## Context

Phase 44 needed a reasoning eval runner to establish baseline scores for decision-quality measurement. The original spec assumed Anthropic SDK direct API calls, but no ANTHROPIC_API_KEY is available in the development environment. An alternative execution mechanism was needed.

## Decision

Use Claude Code subagents (via the Agent tool) instead of Anthropic SDK API calls for reasoning eval. Each subagent receives a scenario + judge prompt and returns structured scores. Self-grading bias is acknowledged but constant across conditions, making relative comparisons valid.

## Consequences

- No API key dependency -- eval runs anywhere Claude Code runs
- Self-grading bias produces ceiling scores (5/5 across all dimensions in baseline) -- need harder scenarios or cross-model judging for meaningful deltas
- Variance is zero across 3 runs, confirming judge consistency but also confirming the scenarios are too easy for the model
- Future phases should add adversarial scenarios (ambiguous tradeoffs, counter-intuitive expert answers) to create scoring headroom
- Cross-model judging (Haiku agent, Opus judge) is a natural follow-up if ceiling persists
