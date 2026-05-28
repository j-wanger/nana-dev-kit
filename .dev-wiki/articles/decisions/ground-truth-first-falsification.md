---
title: "Ground-Truth-First Falsification"
aliases: [ground-truth-first, matcher-falsification-order]
category: decisions
tags: [eval, heuristic, falsification, methodology]
parents: [phase-51-prompt-type-hooks]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

Building a heuristic-to-scenario trigger matcher requires knowing whether the concept is viable before investing in the implementation. If most scenarios have 0 relevant heuristics, selective injection is trivially degenerate.

## Decision

Create the manual heuristic-scenario ground-truth mapping first (before building the matcher), then test the matcher against ground truth on 5 scenarios as cheapest falsification. This follows the early-falsification-checkpoint pattern established in Phase 49.

Alternative considered: build the matcher first, validate against human judgment after (rejected — more expensive to discover failure if the mapping itself reveals the concept is degenerate).

## Consequences

- Manual mapping requires domain judgment for 25 scenarios x 15 heuristics, but produces a reusable evaluation artifact
- If ground truth shows sparse coverage (most scenarios have 0 matches), we discover this before building any infrastructure
- Ground truth doubles as the eval oracle for matcher accuracy measurement
