---
title: Cognitive Enhancement Plan — Heuristic Learning Architecture
confidence: high
source: plan
created: 2026-05-26
updated: 2026-05-26
tags: [architecture, heuristics, eval, reasoning]
---

# Cognitive Enhancement Plan — Heuristic Learning Architecture

## Decision

Adopt a multi-phase cognitive enhancement plan (Phases 44-50+) that builds a heuristic learning system, IRON RULES, self-dialogue, trace collection, and prompt-type hooks — each with its own eval pipeline measuring reasoning quality improvement.

## Rationale

The nana-dev-kit harness automates PROCESS (enforcement, lifecycle, memory) but doesn't improve REASONING. The cognitive enhancement plan adds a reasoning quality layer with measurable evaluation.

Design principles:
1. **Eval before feature** — measure how to improve before building the improvement
2. **Content before infrastructure** — write heuristics before building heuristic servers
3. **One variable at a time** — each phase changes one thing and measures the delta
4. **Use nana-dev-kit's own history as test corpus** — 43 phases of recorded decisions

## Architecture

Heuristics stored as knowledge-wiki articles (wiki/heuristics/) with structured frontmatter:
- id, trigger, domain, source_phase, confidence
- helpful/harmful counters (added in Phase 50 for evolution)
- Sections: When this applies, Always, Never, Why, Anti-pattern, Source

Reasoning eval (eval/reasoning/) as separate LLM-as-judge pipeline:
- 10 decision scenarios from nana-dev-kit history
- 3-dimension scoring: decision quality, reasoning quality, anti-pattern avoidance
- Baseline → +IRON RULES → +self-dialogue → +heuristics comparison

## Alternatives Considered

1. **Extend working-knowledge with heuristic fields** — rejected because heuristics need helpful/harmful evolution scoring (Phase 50) that working-knowledge doesn't support. Working knowledge is project-specific facts; heuristics are transferable reasoning patterns.

2. **ACE Playbook MCP server from day one** — deferred to Phase 49+. Content before infrastructure — prove heuristics help before building a server.

3. **Single monolithic phase** — rejected. One variable at a time ensures each addition is measured for improvement, not noise.

## Consequences

- New `wiki/` directory in nana-dev-kit (knowledge wiki)
- New `eval/reasoning/` eval category (non-deterministic, separate from `make eval`)
- session-start.sh gains heuristic awareness
- Future phases (45-50) build on this foundation sequentially
