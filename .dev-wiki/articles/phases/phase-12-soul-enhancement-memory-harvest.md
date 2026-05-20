---
title: "Phase 12: Soul Enhancement & Memory Harvest"
aliases: []
category: phases
tags: [soul, warmth, memory, debrief, spec, thinking-protocol, persona]
parents: []
created: 2026-05-20
updated: 2026-05-20
source: plan
status: active
scope: ["templates/.claude/rules/nana-soul.md", "templates/.github/instructions/nana.instructions.md", "~/.claude/skills/dev-debrief/memory-harvest.md", "~/.claude/skills/dev-debrief/SKILL.md", "~/.claude/skills/dev-debrief/executor-prompt.md", "~/.claude/skills/dev-plan/SKILL.md", "tests/test_templates.sh", "docs/*"]
entry_criteria: "Phase 11 complete"
exit_criteria: "Soul <=60 lines with Voice & presence section, nana.instructions.md synced, memory-harvest companion wired into debrief, spec-existence check + thinking-protocol T0 in dev-plan, all tests pass, committed"
---

# Phase 12: Soul Enhancement & Memory Harvest

## Objective

Add relational warmth to nana-soul.md via compression-then-expansion, integrate memory-harvest into dev-debrief, and close two process enforcement gaps (spec-existence check, thinking-protocol invocation) in dev-plan.

## Formal Spec

See `specs/phase-12-soul-enhancement-memory-harvest.md` (Opus-reviewed 9/10 accept).

## Scope

Files and modules affected:
- `templates/.claude/rules/nana-soul.md` (compress + add Voice & presence)
- `templates/.github/instructions/nana.instructions.md` (sync)
- `~/.claude/skills/dev-debrief/memory-harvest.md` (new companion)
- `~/.claude/skills/dev-debrief/SKILL.md` (Step 4.7)
- `~/.claude/skills/dev-debrief/executor-prompt.md` (memory-harvest dispatch)
- `~/.claude/skills/dev-plan/SKILL.md` (Step 0.6 + Step 6 T0)
- `tests/test_templates.sh` (soul ceiling assertion)
- `docs/*` (report regeneration)

## Exit Criteria

- [ ] Soul has Voice & presence section, <=60 lines
- [ ] nana.instructions.md byte-matches soul minus frontmatter
- [ ] memory-harvest.md exists with memory_store output
- [ ] memory-harvest wired into dev-debrief SKILL.md + executor-prompt.md
- [ ] spec-existence check in dev-plan pre-checks
- [ ] thinking-protocol T0 in dev-plan Step 6
- [ ] All tests pass (61+)
- [ ] Committed and pushed

## Constraints

- Soul <=60 lines: prevents instruction-following degradation
- Instruction budget <=300 lines total: regression test enforces
- Memory-harvest must NOT duplicate dev-debrief Step 5 decision extraction: decisions go to wiki, corrections/preferences/lessons go to memory_store
- Spec-existence check fires only for standard ceremony: lite remains spec-optional
- Thinking-protocol T0 is conversational only: no artifacts, no blocking gates

## Assumptions

- nana.instructions.md frontmatter is exactly 4 lines. If changed: update tail offset.
- The 3 compression targets can be removed safely. If unique meaning found: find alternatives or accept slightly larger soul (<=60 still).

## Notes

Motivated by OpenHuman comparison (30-line soul with warmth+directness+failure-handling) and Phase 11 retro lesson (process enforcement clusters in momentum, automate rather than document). Memory-harvest prototype -- if successful, may become standalone skill in future phase.
