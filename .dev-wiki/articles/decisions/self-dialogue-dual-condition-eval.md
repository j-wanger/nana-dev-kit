---
title: "Self-Dialogue Dual-Condition Eval"
aliases: [self-dialogue-eval, inline-vs-subagent]
category: decisions
tags: [eval, self-dialogue, reasoning, subagent, iron-rules]
parents: [phase-47-self-dialogue-in-dev-plan, cognitive-enhancement-plan]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: medium
status: accepted
---

# Self-Dialogue Dual-Condition Eval

## Decision

Test both inline prompt technique (condition A) AND subagent isolation (condition B) to determine whether clean-context separation adds value over the technique alone.

## Context

Phase 47 introduces self-dialogue (devil's advocate reasoning with IRON RULE citations) to dev-plan approach formulation. The technique can be delivered two ways: (1) inline in the agent prompt alongside IRON RULES, or (2) via a separate clean-context subagent that only sees the approach + IRON RULES + objective. Prior art: adversarial-constraints-prompt.md in spec skill uses the clean-context subagent pattern successfully. However, whether clean-context separation adds measurable value over inline self-dialogue is unknown.

## Alternatives Considered

1. **Single condition (inline only)** — Simpler eval, fewer runs. But doesn't answer whether subagent isolation adds value, which is the key open question from the cognitive enhancement roadmap.
2. **Single condition (subagent only)** — Skips baseline technique measurement. If subagent shows improvement, we wouldn't know if the simpler inline approach achieves the same result.

## Rationale

One-variable-at-a-time methodology: condition A measures the self-dialogue technique in isolation, condition B adds the subagent variable. Delta between A and B directly answers whether clean-context separation matters. 6 total runs (3 per condition) stays within eval time budget.
