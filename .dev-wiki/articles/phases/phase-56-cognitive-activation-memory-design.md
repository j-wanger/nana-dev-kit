---
title: "Phase 56: Cognitive Activation & Memory Design"
aliases: []
category: phases
tags: [cognitive-activation, memory-architecture, knowledge-wiki, activation-patterns]
parents: []
created: 2026-05-28
updated: 2026-05-28
source: plan
status: completed
scope: ["templates/.claude/hooks/session-start.d/cognitive-readiness.sh", "templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/nana-init/SKILL.md", ".dev-wiki/articles/decisions/", "eval/corpus/", "wiki/", "tests/"]
entry_criteria: "Phase 55 completed, experiment results analyzed, Category 2 gap identified"
exit_criteria: "Memory architecture classified, cognitive readiness enhanced, empty-wiki gate in dev-plan, 2+ eval scenarios, domain articles seeded, make test + make eval 100%"
---

## Objective

Make the cognitive layer (knowledge wiki, heuristics, domain research) activate at natural decision points rather than requiring voluntary invocation. Classify each of 5 memory layers as mandatory/automatic/voluntary with experiment evidence from Phase 42 effectiveness validation.

## Scope

- `templates/.claude/hooks/session-start.d/cognitive-readiness.sh` -- enhanced diagnostic with actionable recommendations
- `templates/.claude/skills/dev-plan/SKILL.md` -- functional empty-wiki handling (upgrade advisory to structured recommendation)
- `templates/.claude/skills/nana-init/SKILL.md` -- wiki-bootstrap nudge post-init
- `.dev-wiki/articles/decisions/` -- memory architecture classification decision
- `eval/corpus/` -- 2 cognitive activation eval scenarios
- `wiki/` -- 5+ domain articles seeded via wiki-bootstrap
- `tests/` -- test assertions for new behavior

## Exit Criteria

1. Memory architecture decision article exists with mandatory/automatic/voluntary classification for all 5 layers
2. Enhanced cognitive-readiness.sh with prioritized actionable recommendations by state
3. Dev-plan SKILL.md has functional empty-wiki handling (structured recommendation, not just advisory)
4. 2+ eval scenarios for cognitive activation (populated and empty states)
5. 5+ domain articles seeded in knowledge wiki
6. make test + make eval 100%

## Constraints

- 1200-char shared injection budget across all cognitive tools
- Mandatory retrieval, not mandatory compliance (reasoning > compliance)
- Fail-open on all cognitive hooks (exit 0 always)
- No ceremony inflation (2-gate model preserved)
- Session-start.sh ≤70 lines (use .d/ extraction pattern)
- Dev-plan SKILL.md ≤350 lines

## Checkpoints

- Task 1 (architecture classification) informs Task 5 (wiki-bootstrap content) and overall activation design
- Task 4 (cognitive readiness enhancement) must complete before Task 6 (eval scenarios)
- All tasks feed into final make test + make eval verification

## Assumptions

- Phase 42 experiment data provides sufficient evidence for activation mode classification
- wiki-bootstrap can seed meaningful domain content from online research
- Cognitive readiness enhancements stay within session-start.d/ extraction pattern

## Notes

- This phase addresses the Category 2 gap identified in Phase 55 debrief: cognitive tools exist but don't activate voluntarily
- The 5 memory layers: MCP memory, working-knowledge, active-knowledge, knowledge-wiki, dev-wiki
- Phase 42 showed cognitive tools don't activate without structural forcing -- this phase designs that forcing
