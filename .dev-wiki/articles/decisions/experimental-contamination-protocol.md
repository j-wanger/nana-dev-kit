---
title: "Experimental contamination protocol"
aliases: [contamination-protocol, clean-rerun]
category: decisions
tags: [eval, comparison, methodology, contamination, clean-room]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-26
updated: 2026-05-26
source: debrief
confidence: high
---

## Context

Initial A/B retry prompts inadvertently leaked Condition C implementation details (identity matching, 3-tier pruning, join cleanup, mask=None). This contamination was caught by the user during review. The leaked information could have inflated A/B scores by providing algorithmic hints that a bare baseline should not have access to.

## Decision

Established clean rerun protocol: subagent prompts include only the task description plus generic structural hints (e.g., "look at the SQL generation"), never specific algorithm details or implementation strategies from prior attempts. Contaminated runs discarded; clean reruns used for all reported results.

## Consequences

- Results are more trustworthy as A/B conditions genuinely operate without implementation knowledge
- Future comparisons must use a contamination checklist before dispatching subagents
- The contamination event itself is documented as methodology improvement evidence
- Slight time cost for reruns, but directional validity is worth more than speed
