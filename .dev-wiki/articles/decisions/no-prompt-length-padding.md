---
title: "No Prompt-Length Padding for Ablation"
aliases: [no-padding, prompt-length-confound]
category: decisions
tags: [eval, ablation, methodology, confound-control]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
status: accepted
---

# No Prompt-Length Padding for Ablation

## Context

Leave-one-out ablation removes one IRON RULE (~8 lines) per condition. This shortens the prompt, introducing a prompt-length confound: improvements could be from removing content or from shorter prompts. Padding (inserting neutral text to maintain constant length) is one mitigation.

## Decision

No padding. Padding introduces its own confound (neutral text may still affect reasoning). Instead, use scenario 012 as a natural diagnostic: 012 regressed from context dilution in Phase 46 (not from specific rule content). If removing ANY single rule improves 012 uniformly, it's payload-size evidence. If only specific rules improve 012, it's content attribution.

## Consequences

Accepts prompt-length as a known confound. Scenario 012 serves as the diagnostic control — its behavior pattern distinguishes length effects from content effects without artificial padding. This approach is cleaner but relies on 012's sensitivity being a reliable signal.
