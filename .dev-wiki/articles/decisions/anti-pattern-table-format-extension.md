---
title: "Anti-pattern table format extension"
aliases: [anti-pattern-tables, structured-anti-pattern-format]
category: decisions
tags: [heuristics, schema, anti-patterns, knowledge-wiki]
parents: [phase-46-anti-pattern-tables-heuristic-capture]
created: 2026-05-27
updated: 2026-05-27
source: implementation
confidence: high
---

## Context

The existing heuristic article format (SCHEMA.md) defines a single-paragraph Anti-pattern section — one named pattern with a failure explanation. Phase 45 revealed that IRON-004 caused a regression on scenario 018 because a single anti-pattern paragraph lacked the specificity to capture multiple failure modes with their detection signals. Enriching anti-pattern sections with structured tables enables more precise failure-mode documentation and supports future automated detection.

## Decision

Extend the existing `## Anti-pattern` section in SCHEMA.md with a structured table format: columns are `Failure Mode | Detection Signal | Why It Fails`, with 3-5 rows per heuristic. The `## Anti-pattern` H2 header is preserved for wiki-query compatibility. When a heuristic has no observed anti-patterns beyond the primary one, a "no observed anti-patterns beyond primary" marker row is used. Alternatives considered: separate anti-pattern catalog file (rejected — keeps content with the heuristic it belongs to), free-form bullet list (rejected — detection signals need structured format for future automation).

## Consequences

All 5 IRON RULES and future heuristics will carry anti-pattern tables. The SCHEMA.md format definition grows by ~10-15 lines. Context injection payload for IRON RULES increases moderately (each table adds ~5-8 lines per rule). The structured format enables future tooling to extract detection signals programmatically. Existing heuristics (HEU-001 through HEU-010) are not required to adopt tables immediately — they can be enriched incrementally.
