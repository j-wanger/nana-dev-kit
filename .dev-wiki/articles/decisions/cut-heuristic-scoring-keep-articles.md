---
title: "Cut the heuristic SCORING machinery, keep the 17 articles"
aliases: ["cut-heuristic-scoring-keep-articles", "cut-heuristic-machinery"]
category: decisions
tags: [subtraction-test, deadweight, heuristics, cognitive-enhancement, walk-upstream, test-fixtures]
parents: [phase-64-cut-heuristic-scoring-machinery-self-dialogue, phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phase 63 classified the Cognitive Enhancement scoring loop (matcher → judge → counter-update → lifecycle → dashboard, Phases 44-52) DEADWEIGHT by affirmative evidence: 18 counters at `helpful:0/harmful:0`, `git log -S 'helpful: 1'` empty across ~13 phases — it has never recorded a single firing. The subtraction test says cut it. But the 17 `wiki/heuristics/*.md` articles the loop was built to score are NOT deadweight: they are asserted by `test_templates.sh`/`test_companions.sh` (live fixtures) AND are the input corpus for the separate `eval/reasoning` injection experiment. A naive "delete the heuristic subsystem" cut would take the knowledge with the machinery.

## Decision

Cut the never-fired scoring MACHINERY, keep the knowledge-fixtures. Removed: the 5 dev-plan companions that run the loop (`heuristic-matcher.md`, `heuristic-judge-prompt.md`, `heuristic-counter-update.md`, `heuristic-lifecycle.md`) plus dev-plan Step 13 sub-items 6-7 (judge dispatch + counter write); `scripts/heuristic-dashboard.py`; `tests/test_heuristic_evolution.sh`; AND — walking UPSTREAM — the dev-debrief `heuristic-capture.md` (Step 7), the *producer* that writes counters and proposes heuristics. Removing only the dev-plan consumer (judge dispatch) while leaving the dev-debrief producer would orphan the counter-write path. Kept: the 17 articles + `wiki/heuristics/SCHEMA.md`, including their vestigial `helpful/harmful/status` frontmatter (changing it breaks the article-format assertions). Alternative rejected: delete the whole `wiki/heuristics/` tree — that destroys live test fixtures and the eval-reasoning corpus for zero benefit.

## Consequences

The cut is a coherent subtraction, not a half-removal: no orphaned counters, dashboard, tests, or judge dispatch, and no dangling references to deleted basenames. The articles and the eval/reasoning experiment are untouched and still pass. Walk-upstream generalizes: when cutting a feedback loop, remove both the consumer and the producer end, not just the visible dispatch. The cut frees the dev-plan/dev-debrief step surface, which is why self-dialogue is batched here ([[batch-self-dialogue-with-heuristic-renumber]]). The Cognitive Enhancement roadmap (7/7 phases, Phases 44-52) is now retired machinery; only the seed knowledge survives as fixtures.
