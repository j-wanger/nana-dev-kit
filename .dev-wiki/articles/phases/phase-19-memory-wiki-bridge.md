---
title: "Phase 19: Memory-Wiki Bridge"
aliases: []
category: phases
tags: [memory, wiki, bridge, mcp, fail-open]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/dev-plan/memory-bridge.md", "templates/.claude/skills/spec/SKILL.md", "templates/.claude/skills/wiki-query/SKILL.md", "tests/test_templates.sh"]
entry_criteria: "Phase 18 complete, spec approved"
exit_criteria: "memory-bridge.md exists, SKILL.md references it, spec SKILL.md has memory_store, wiki-query SKILL.md has memory_search, tests pass"
---

# Phase 19: Memory-Wiki Bridge

## Objective

Bridge memory (MCP memory_store/memory_search) and wiki (markdown articles) so that decisions from dev-plan and spec auto-persist to memory, and wiki-query includes memory results when answering questions.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/SKILL.md` — 2-3 line pointer after Step 8a
- `templates/.claude/skills/dev-plan/memory-bridge.md` — new companion file (~30-40 lines)
- `templates/.claude/skills/spec/SKILL.md` — 3-5 line memory-store block after Step 6
- `templates/.claude/skills/wiki-query/SKILL.md` — memory_search integration in Step 1
- `tests/test_templates.sh` — cross-reference assertions

## Exit Criteria

- [ ] `test -f templates/.claude/skills/dev-plan/memory-bridge.md`
- [ ] `grep -q 'memory-bridge\.md' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]`
- [ ] `grep -q 'memory_store' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -q 'memory_search\|Memory Results' templates/.claude/skills/wiki-query/SKILL.md`
- [ ] `grep -q 'memory.bridge\|memory-bridge' tests/test_templates.sh`
- [ ] `make test`

## Constraints

- dev-plan SKILL.md at 338 lines — companion file required, not inline. Prevents ceiling breach.
- All memory entries use category="custom" with tags=["bridge-decision"]. No vendored code changes.
- Budget guard uses memory_stats (not empty-query memory_search). Prevents zero-result bugs.
- All channels fail-open. Memory bridge is additive, never blocking.
- Dedup relies on memory_store built-in near-duplicate detection. No manual search-then-update.

## Checkpoints

- After Channel 1 (dev-plan companion) is drafted: report line count
- After all three channels implemented (before tests): report total lines added

## Assumptions

- memory_store and memory_search MCP tools available during skill execution. If false: all channels fail-open silently.
- memory_stats returns total_active count. If false: fallback to memory_search count.
- wiki-query SKILL.md has sufficient headroom for inline integration. If false: extract to companion.

## Tasks

4 tasks (1M 3S), all completed. See tasks.md Phase 19 section.

## Decisions

- [[memory-bridge-category-custom]] -- high confidence, use category=custom with tags
- [[memory-bridge-budget-guard-stats]] -- high confidence, use memory_stats for budget guard
- [[memory-bridge-inline-orchestrator]] -- high confidence, bridge runs inline in orchestrator

## Completion

All 4 tasks done, all 7 exit criteria met. Phase READY FOR COMPLETION. Journal: [[2026-05-22-phase-19-memory-wiki-bridge-complete]].

## Notes

Spec at specs/phase-19-memory-wiki-bridge.md (approved 8/10, revised from 4/10). Three independent channels. No install.sh changes needed (cp -r auto-distributes companion files in existing skill dirs).
