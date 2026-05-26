---
title: "Three-condition comparison design"
aliases: [three-condition, abc-comparison]
category: decisions
tags: [eval, comparison, methodology, experimental-design]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

A binary comparison (with vs without harness) cannot decompose which harness components contribute value. The harness has three layers: context injection (rules, AGENTS.md), active features (hooks, skills, memory), and the combination. Understanding which layer provides value informs future development priorities.

## Decision

Three conditions: A (bare baseline subagent), B (context-injection subagent with .claude/rules/ and AGENTS.md), C (full harness with hooks/skills/memory via manual session). This yields three pairwise comparisons: A-vs-B tests context injection value, A-vs-C tests full harness value, B-vs-C isolates active feature value. Alternative considered: two-condition only (loses ability to decompose harness value into components).

## Consequences

- Three pairwise comparisons provide richer insight than binary
- A-vs-B is automatable via parallel subagents; C requires manual user session
- Results are incremental: A-vs-B available immediately, full analysis after user runs C
- Methodology documentation must clearly specify all three conditions for reproducibility
