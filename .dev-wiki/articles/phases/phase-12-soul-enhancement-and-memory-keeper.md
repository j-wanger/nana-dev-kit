---
title: "Phase 12: Soul Enhancement & Memory Keeper"
aliases: [phase-12]
category: phases
tags: [soul, persona, memory-keeper, warmth, failure-handling]
parents: []
created: 2026-05-20
updated: 2026-05-20
source: plan
status: not-started
scope: ["templates/.claude/rules/nana-soul.md", "templates/.github/instructions/nana.instructions.md", "templates/.claude/skills/memory-keeper/*", "install.sh", "tests/test_install.sh", "tests/test_templates.sh"]
entry_criteria: "Phase 11 complete"
exit_criteria: "Soul has warmth/voice/failure-handling layer within 60-line budget; memory-keeper skill prototype exists and is installable; all tests pass; instruction budget <= 300 lines"
---

# Phase 12: Soul Enhancement & Memory Keeper

## Objective

Add a warmth/voice/failure-handling layer to nana-soul.md (modeled on OpenHuman's persona density) and prototype a memory-keeper skill that extracts institutional knowledge from conversation context before session ends.

## Scope

Files and modules affected:
- `templates/.claude/rules/nana-soul.md` — add persona density (warmth, failure recovery, voice)
- `templates/.github/instructions/nana.instructions.md` — sync with soul changes
- `templates/.claude/skills/memory-keeper/` — new skill for knowledge extraction
- `install.sh` — add memory-keeper skill to copy list
- `tests/test_install.sh` — assert memory-keeper skill copied
- `tests/test_templates.sh` — assert soul content + budget regression

## Exit Criteria

- [ ] nana-soul.md has warmth/voice/failure-handling content within 60-line budget
- [ ] nana.instructions.md synced with soul
- [ ] memory-keeper skill exists with SKILL.md
- [ ] install.sh copies memory-keeper skill
- [ ] All tests pass, instruction budget <= 300 lines

## Constraints

- Soul must stay <= 60 lines (currently 52, so ~8 lines of net headroom). Every new line must earn its place. Prevents: bloat that degrades instruction-following.
- Instruction budget must stay <= 300 lines total (currently 229/300, so 71 lines headroom). Prevents: context window pressure.
- Soul content must pass the Rust litmus test (universal, not project-specific). Prevents: soul/AGENTS.md boundary erosion.
- nana.instructions.md must remain a byte-exact copy of nana-soul.md (minus frontmatter). Prevents: split-brain across agent surfaces.
- Memory-keeper is a prototype — start minimal, don't over-engineer. Prevents: scope creep in first iteration.

## Checkpoints

- After soul edits: verify line count <= 60, run budget test, confirm Rust litmus passes for all new content
- After memory-keeper SKILL.md: review before writing install.sh changes
- If instruction budget exceeds 285/300: STOP and discuss trimming strategy

## Assumptions

- OpenHuman-style persona density can be achieved in ~10-15 new lines while removing or compressing equivalent existing content. If false: prioritize failure-handling and warmth, defer voice tuning.
- Memory-keeper can operate as a session-end skill invoked manually (no hook automation in prototype). If false: reduce to a prompt template rather than full skill.
- The soul's current 6-section structure can absorb persona additions without a new section. If false: consider merging sections to free structural space.

## Notes

- OpenHuman achieves warmth, directness, failure handling, and user-register matching in ~30 lines. Target similar persona density.
- Phase has two independent workstreams: soul enhancement and memory-keeper prototype. Soul is higher priority.
- Memory-keeper relates to existing memory_store/memory_search MCP tools but operates at a higher level: scanning conversation for knowledge worth persisting.
