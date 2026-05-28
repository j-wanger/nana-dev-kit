---
title: "Length-Sensitivity Experiment Design"
aliases: [length-sensitivity-experiment-design, length-sensitivity-test]
category: decisions
tags: [eval, reasoning, length-sensitivity, confound-control]
parents: [phase-50-eval-advancement]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: medium
---

## Context

Phase 46 observed context dilution (scenario 012 dropped when IRON RULES injection expanded to ~549 words). Phase 49 conditional injection showed zero delta vs always-inject. An open question remained: is the interference driven by prompt length (any ~549 words) or by IRON RULES content specifically?

## Decision

Test length as the independent variable using coherent unrelated text (cooking/gardening domain) matching IRON RULES word count (549 words, range 520-580). Pre-committed threshold: if filler delta is within 0.3 of IRON RULES delta on >50% of affected scenarios (those with IRON RULES delta <= -0.3 vs baseline), conclude length is the driver.

Alternatives rejected:
- **Gibberish text** -- different attention patterns than coherent text; doesn't isolate length vs content fairly.
- **Shorter text** -- doesn't isolate the length variable at the actual injection size.
- **Systematic length gradient** -- too many conditions for one phase; save for follow-up if length is confirmed as driver.

## Consequences

If length is the driver: IRON RULES content is irrelevant for interference scenarios; future work should focus on compression or selective injection by scenario difficulty. If content matters: interference is rule-specific, and per-rule selection remains viable despite Phase 48/49 negative results.
