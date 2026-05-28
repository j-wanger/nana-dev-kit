---
title: "Cross-Model Judge via Agent Parameter"
aliases: [cross-model-judge-via-agent-param, cross-model-judging]
category: decisions
tags: [eval, reasoning, cross-model, calibration, judge]
parents: [phase-50-eval-advancement]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: medium
---

## Context

Self-grading bias is acknowledged but untested: the same LLM writes responses and evaluates them, inflating absolute scores (mean 4.83 vs target < 4.5). Relative comparisons remain valid, but absolute calibration is unknown. AgentCoder 3-agent separation principle suggests cross-model judging breaks this correlation.

## Decision

Use Claude Code Agent model parameter to dispatch judge subagent as Sonnet while the agent runs the default model. Store raw agent responses in the results schema for re-judging without re-running the agent. Calibration criterion: mean < 4.5 and >=15% below 5. Fallback: try Haiku; if all Claude models correlate, non-Claude judging is out of scope for this phase.

Alternatives rejected:
- **Anthropic API direct** -- requires additional infrastructure (API keys, request handling) beyond what Agent() provides.
- **External model API (GPT-4o, Gemini)** -- out of scope; introduces provider dependency.
- **Same-model temperature variation** -- doesn't break the self-grading correlation.

## Consequences

Extends results schema with raw responses and judge/agent model metadata. Enables future re-judging experiments without re-running agent evaluations. If cross-model calibration passes, it becomes the default judge for future eval runs.
