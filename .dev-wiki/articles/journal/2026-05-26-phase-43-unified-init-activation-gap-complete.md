---
title: "Phase 43: Unified Init & Activation Gap complete"
aliases: []
category: journal
tags: [init, onboarding, rename, activation-gap, nana-init, orchestrator]
parents: [phase-43-unified-init-activation-gap]
created: 2026-05-26
updated: 2026-05-26
source: debrief
---

# Phase 43: Unified Init & Activation Gap complete

## What Happened
- Renamed /init skill directory to /nana-init to resolve naming collision with Claude Code's built-in /init command
- Updated all cross-references: modules.json, install.sh, README.md, _ARCHITECTURE.md, MANIFEST (5 files)
- Expanded SKILL.md from 44-line language router to 86-line multi-stage orchestrator bootstrapping full Nana experience: language scaffold + dev-wiki + optional knowledge wiki
- All real work delegates to existing skills via Skill() dispatch (py-init/ts-init/dev-init/wiki-init) -- no logic duplication
- Each orchestration step independently skippable based on state detection

## Decisions Made
- [[nana-init-rename-and-expand|Rename /init to /nana-init and expand to multi-stage orchestrator]] -- created at planning, confirmed at delivery

## Artifacts Changed
- `templates/.claude/skills/nana-init/SKILL.md` (renamed from init/, expanded 44 -> 86 lines)
- `modules.json` ("init" -> "nana-init" in core skills)
- `install.sh` (display strings updated)
- `README.md` (getting started section updated)
- `.dev-wiki/_ARCHITECTURE.md` (directory layout line updated)
- `templates/.claude/skills/MANIFEST` (path + description updated)
- `tests/test_install.sh` (assertions updated for nana-init)
- `tests/test_templates.sh` (assertions updated + new expanded SKILL.md checks)

## Related
- [[phase-43-unified-init-activation-gap|Phase 43: Unified Init & Activation Gap]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- Automatic maintenance gap: wiki re-index, auto-debrief, memory consolidation nudge could be automated in session hooks -- future phase candidate for reducing manual invocation burden
- The activation gap pattern (users only get 30% of capabilities until explicitly discovering each subsystem) could apply to other CLI toolkits -- worth capturing as a knowledge wiki article
