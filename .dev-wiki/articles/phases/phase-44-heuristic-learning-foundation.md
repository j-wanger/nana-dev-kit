---
title: "Phase 44: Heuristic Learning System — Foundation"
status: not-started
created: 2026-05-26
updated: 2026-05-26
ceremony: standard
scope:
  - wiki/
  - wiki/heuristics/
  - templates/.claude/hooks/session-start.sh
  - eval/reasoning/
exit_criteria:
  - wiki/schema.md exists with heuristic category
  - wiki/heuristics/SCHEMA.md defines structured heuristic format
  - 10 seed heuristics in wiki/heuristics/HEU-*.md
  - session-start emits [nana:heuristics] count
  - eval/reasoning/ has runner, judge, 10 scenarios
  - baseline scores in eval/reasoning/baseline/results.json
  - make test passes, make eval 100%
---

# Phase 44: Heuristic Learning System — Foundation

## Objective

Build the heuristic store — the new persistence layer for transferable reasoning patterns. Seed it with 10 heuristics mined from 43 phases of development history. Establish a baseline reasoning eval to measure improvement in subsequent phases.

## Approach

Three sub-goals from the Cognitive Enhancement Plan:

**41a — Heuristic Schema & Storage:** Initialize knowledge wiki via /wiki-init with "heuristic" as a first-class article category. Define structured format in SCHEMA.md (trigger, domain, always/never, anti-pattern). Write 10 seed heuristics from decision articles, working-knowledge, and git history.

**41b — Session-Start Integration:** Add heuristic count display and retrieval guidance to session-start.sh. Direct agents to search heuristics before approach formulation.

**41c — Baseline Reasoning Eval:** Create eval/reasoning/ with 10 decision scenarios from nana-dev-kit history, LLM-as-judge prompt (3 dimensions: decision quality, reasoning quality, anti-pattern avoidance), and baseline run without heuristics.

## Key Decisions

- Heuristics are knowledge-wiki articles with `category: heuristic` frontmatter — reuses existing wiki infrastructure
- Reasoning eval is a separate Python runner (Anthropic SDK) — non-deterministic, can't be in `make eval`
- Seed heuristics focus on transferability — must apply beyond dev harness projects

## Dependencies

- /wiki-init (prerequisite — no knowledge wiki exists)
- Anthropic SDK (for eval runner)

## Risks

- Heuristics mined from a single project type may not transfer
- LLM-as-judge variance could exceed threshold
- Wiki-init adds interactive scope to an otherwise automated phase
