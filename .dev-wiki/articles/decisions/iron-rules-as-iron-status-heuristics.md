---
title: "IRON RULES as Iron-Status Heuristics"
aliases: [iron-rules-format, iron-status-heuristics]
category: decisions
tags: [heuristics, iron-rules, schema, knowledge-wiki]
parents: [phase-45-eval-calibration-iron-rules]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

IRON RULES are unconditional, universal reasoning rules that prevent known failure modes — they differ from situational heuristics which have contextual triggers. The question is whether IRON RULES need a separate format or can reuse the existing heuristic article infrastructure.

## Decision

IRON RULES reuse the heuristic article format (6 required sections: When this applies, Always, Never, Why, Anti-pattern, Source) with two distinguishing fields: `status: iron` and `confidence: absolute`. SCHEMA.md status enum is updated to include `iron` alongside existing values (active, deprecated, under-review). Selection criterion for IRON RULES: universal (applies to every decision), unconditional (no exceptions), prevents a known reasoning failure mode. Alternatives considered: separate rules format (rejected — more format proliferation without benefit), rules embedded in soul (rejected — context budget constraint at 59/60 lines).

## Consequences

No new wiki infrastructure needed — IRON RULES are discoverable via the same wiki-query and indexing tools as regular heuristics. The `status: iron` field enables filtering. The "When this applies" section for IRON RULES will be "Always — every decision" rather than a conditional trigger. Cross-referencing against existing heuristics is required to detect conflicts, with precedence clauses added where tension exists.
