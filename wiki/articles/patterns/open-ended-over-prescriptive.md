---
title: Open-Ended Prompts Over Prescriptive Specs
tags: [reasoning-pattern, transferable, prompt-engineering]
created: 2026-05-28
updated: 2026-05-28
source: phase-42-harness-effectiveness-validation
---

# Open-Ended Prompts Over Prescriptive Specs

## Pattern

When directing an LLM agent to solve a domain problem, prompts that encourage reasoning ("think about what creates edge," "justify your choices") produce higher-quality output than prescriptive specs that dictate implementation details (specific libraries, schemas, file structures).

## Evidence

Phase 42 experiment: 5 implementations of a stock screener under different conditions. Open-ended prompts scored **+1.75 composite quality** over prescriptive specs. The best implementation (bare Claude Code, open-ended prompt) produced academic citations, cross-sectional percentile ranking, and honest backtesting that acknowledged limitations. The prescriptive spec implementation used more sophisticated methodology but overfitted, claiming implausible returns.

The prescriptive spec constrained the agent from making better domain decisions. The spec dictated pandas + yfinance + a specific file structure, which the agent followed compliantly rather than reasoning about what approach best fit the domain.

## When to apply

- Spec/contract design for agent tasks involving domain reasoning
- Planning prompts where the agent needs to choose an approach
- Review prompts where the agent should evaluate quality, not check compliance
- Any task where domain expertise adds value beyond mechanical execution

## How to apply

Replace prescriptive sections with reasoning-oriented ones:
- **Deliverables** → **Success Vision** (describe outcomes and qualities, not specific files)
- Add **Domain Research Questions** (what should the implementer investigate before committing?)
- **Approach** states goals and constraints, not implementation details

## Counter-indication

Prescriptive specs are appropriate for mechanical tasks with known-good patterns: CI/CD configuration, boilerplate scaffolding, migration scripts. The cost of reasoning there is wasted time; the benefit is zero.
