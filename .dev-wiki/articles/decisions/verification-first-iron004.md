---
title: "Verification-First Approach for IRON-004 Investigation"
aliases: [verification-first-iron004]
category: decisions
tags: [iron-rules, eval, investigation]
parents: [phase-53-open-questions]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: medium
status: accepted
---

## Context

IRON-004 ("simpler system wins") was flagged as overriding domain reasoning on scenario 015 (deadline-constrained). However, this concern predates Phase 51's selective injection system — the ground-truth map assigns 015 to IRON-005 only, not IRON-004. If the matcher doesn't select IRON-004 for scenario 015, the open question is already resolved by the selective injection architecture.

## Decision

Use verification-first approach: run the heuristic trigger matcher on scenario 015 before committing to eval runs. The matcher check is ~1 subagent call vs 6 eval runs (3 per scenario x 2 scenarios). If IRON-004 is not selected, close the question. If selected, proceed with full eval.

Alternative considered: running all eval runs upfront without matcher verification. Rejected because unnecessary if matcher doesn't select IRON-004 for 015.

## Consequences

Saves up to 6 eval runs (~30 min) if matcher doesn't select IRON-004 for 015. Risk: matcher behavior may differ between LLM and domain-tag fallback paths — must test both. If the question closes early, the phase completes faster with fewer tasks needing full execution.
