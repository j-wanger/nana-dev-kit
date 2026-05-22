---
title: "T0 wording over structural subagent for thinking protocol"
aliases: [t0-wording-fix, thinking-protocol-wording]
category: decisions
tags: [thinking-protocol, dev-plan, adversarial]
parents: [phase-14-adversarial-thinking-and-review]
created: 2026-05-21
updated: 2026-05-21
source: plan
confidence: high
---

## Context

T0 thinking protocol in dev-plan Step 6 was confirmed performative — agent rubber-stamps user input instead of genuinely challenging. Three reviews flagged this. Two options: rewrite the wording with output-format forcing functions, or introduce a clean-context contrarian subagent.

## Decision

Wording fix chosen over structural subagent. Replace 3 abstract T0 checks (challenge frame, read subtext, delay commitment) with output-format requirements: name weakest assumption + what breaks, identify alternative framing, state what info would change recommendation. Add non-vacuity gate: re-prompt once if vacuous, then log and proceed. ~15 lines, testable, addresses the immediate rubber-stamping issue.

If wording fix fails, contrarian subagent is Phase 15 escalation.

## Consequences

- T0 becomes falsifiable — output must name specific assumptions, not generic agreement
- Non-vacuity gate adds one retry before accepting potentially weak output
- Soul remains frozen at 59/60 (T0 lives in dev-plan SKILL.md, not soul)
- If wording alone is insufficient, structural subagent approach is deferred, not abandoned
