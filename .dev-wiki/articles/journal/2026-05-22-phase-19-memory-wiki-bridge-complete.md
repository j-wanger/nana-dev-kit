---
title: "Phase 19: Memory-Wiki Bridge — complete"
aliases: []
category: journal
tags: [memory, wiki, bridge, mcp, dev-plan, spec, wiki-query]
parents: [phase-19-memory-wiki-bridge]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 19: Memory-Wiki Bridge — complete

## What Happened
- Created memory-bridge.md companion file (39 lines) in dev-plan skill dir defining the store protocol: category="custom", tags=["bridge-decision"], content format, budget guard via memory_stats, fail-open semantics.
- Added 3-line pointer in dev-plan SKILL.md after Step 8a (artifact-writer return) referencing the companion. SKILL.md grew from 338 to 341 lines (within 350 ceiling).
- Added inline memory_store block to spec SKILL.md after Step 6 (persist). 4 lines, SKILL.md at 128 lines.
- Added memory_search integration to wiki-query SKILL.md Step 1 with "Memory Results" section in analyst context. 5 lines, SKILL.md at 243 lines.
- Spec initially rejected (4/10) due to invalid category="decision" and broken budget check via empty-query memory_search. Revised spec scored 8/10 after switching to category="custom" and memory_stats.
- No install.sh changes needed — cp -r auto-distributes new companion files in existing skill dirs.
- Added 8 test assertions in test_templates.sh covering all 3 channels.

## Decisions Made
- [[memory-bridge-category-custom|Use category=custom with bridge-decision tag]] — high confidence (created during planning, confidence upgraded)
- [[memory-bridge-budget-guard-stats|Use memory_stats for budget guard]] — high confidence (created during planning, confidence upgraded)
- [[memory-bridge-inline-orchestrator|Bridge runs inline in orchestrator]] — high confidence (created during planning, confidence upgraded)

## Problems Solved
- Spec rejection due to invalid category="decision": Category enum only has fact/preference/correction/entity/custom. Fixed by using category="custom" with tags for semantic filtering.
- Budget check failure: empty-query memory_search returns 0 after FTS sanitization. Fixed by using memory_stats tool instead.
- MCP tool access in subagents: Agent subagents cannot call MCP tools. Fixed by running bridge inline in orchestrator after subagent returns.

## Open Questions
- None remaining. Both planning-phase blockers (memory_stats API shape, wiki-query analyst prompt) resolved during implementation.

## Artifacts Changed
- `templates/.claude/skills/dev-plan/memory-bridge.md` (new -- 39 lines, memory-store protocol companion)
- `templates/.claude/skills/dev-plan/SKILL.md` (+3 lines to 341 -- pointer to memory-bridge.md)
- `templates/.claude/skills/spec/SKILL.md` (+4 lines to 128 -- inline memory_store after Step 6)
- `templates/.claude/skills/wiki-query/SKILL.md` (+5 lines to 243 -- memory_search + Memory Results)
- `tests/test_templates.sh` (+8 assertions for memory bridge channels)

## Health Delta
- Tests: 120 -> 128. Budget: 245/300. Soul: 59/60. SKILL.md: dev-plan 341, spec 128, wiki-query 243 (all under 350).

## Gate Compliance
All 4 standard gates present: spec 8/10 (revised from 4/10), approach 8/10, plan-review 8/10, tasks yes. No SKIPPED gates.

## Activation Quality
4/4 entries referenced (100% hit rate). No dead entries.

## Related
- [[phase-19-memory-wiki-bridge|Phase 19: Memory-Wiki Bridge]] -- parent phase
- [[roadmap-gap-analysis|Roadmap]] -- closes Gap 1.3 (knowledge retrieval), Gap 3.3 (write path), Gap 4.4 (passive capture)

## Soft Observations / Phase N+1 Candidates
- memory-harvest companion (dev-debrief) references "lesson" and "constraint" categories not in the Category enum -- pre-existing bug, separate fix needed | suggest: fix memory-harvest.md to use category="custom" with tags | evidence: Category enum inspection during spec revision
- wiki-query analyst prompt may need explicit mention of memory results for effective synthesis -- worth validating in practice before adding complexity | suggest: observe bridge usage in next 2-3 sessions before modifying analyst prompt | evidence: wiki-query SKILL.md Step 1 integration
