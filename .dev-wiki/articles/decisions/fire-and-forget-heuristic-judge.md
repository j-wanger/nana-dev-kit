---
title: "Fire-and-Forget Heuristic Judge"
aliases: [fire-and-forget-judge, heuristic-judge-isolation]
category: decisions
tags: [heuristic, judge, subagent, eval, reasoning]
parents: [phase-51-prompt-type-hooks]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

Phase 47 showed that same-context critique (self-dialogue) is net negative — it adds hedging without adding depth. The heuristic judge needs isolation from the planning agent to avoid contaminating the plan with judge feedback.

## Decision

Judge runs as an isolated subagent in fire-and-forget mode. Judge scores are logged and used only for routing (accept/revise/reject verdict), never injected back into the planner's context. This prevents the hedging behavior observed in Phase 47 while still enabling heuristic-informed quality assessment.

Alternative considered: integrated critique where judge findings are shown to the planner (rejected — Phase 47 negative result demonstrated this causes overcorrection and hedging).

## Consequences

- Judge output cannot influence the current planning pass — only future routing decisions
- Simpler integration: no feedback loop to manage or test
- Judge calibration can be tuned independently of planner behavior
- If judge accuracy is low, the cost is wasted computation (not degraded plans)
