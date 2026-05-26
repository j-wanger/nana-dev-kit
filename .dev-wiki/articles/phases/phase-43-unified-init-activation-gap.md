---
title: "Phase 43: Unified Init & Activation Gap"
aliases: [phase-43-unified-init-activation-gap]
category: phases
tags: [init, onboarding, activation, rename, developer-experience]
parents: []
created: 2026-05-26
updated: 2026-05-26
source: plan
status: completed
scope: ["templates/.claude/skills/init/*", "templates/.claude/skills/nana-init/*", "modules.json", "install.sh", "templates/.claude/skills/MANIFEST", "README.md", "tests/test_install.sh", "tests/test_templates.sh", ".dev-wiki/_ARCHITECTURE.md"]
entry_criteria: "Phase 42 completed (7/7 tasks done)"
exit_criteria: "/nana-init replaces /init, bootstraps language scaffold + dev-wiki + optional knowledge wiki, all tests + eval pass"
---

# Phase 43: Unified Init & Activation Gap

## Objective

Rename /init to /nana-init (resolving name collision with Claude Code's built-in /init) and expand it from a 44-line language router into an ~80-120 line multi-stage orchestrator that bootstraps the full Nana experience: language scaffold, dev-wiki lifecycle, optional knowledge wiki.

## Scope

Files and modules affected:
- `templates/.claude/skills/init/` -> `templates/.claude/skills/nana-init/`
- `modules.json` (core skills array: "init" -> "nana-init")
- `install.sh` (echo/dry-run display strings)
- `templates/.claude/skills/MANIFEST` (path + description)
- `README.md` (getting started section)
- `.dev-wiki/_ARCHITECTURE.md` (directory layout line)
- `tests/test_install.sh` (install assertions)
- `tests/test_templates.sh` (template assertions)

## Exit Criteria

- [x] /init skill directory renamed to /nana-init
- [x] All cross-references updated (modules.json, install.sh, MANIFEST, README, _ARCHITECTURE.md)
- [x] Tests updated and passing (make test) -- ~306 tests pass
- [x] /nana-init SKILL.md orchestrates: language scaffold + dev-wiki + optional knowledge wiki
- [x] SKILL.md <= 120 lines (86 lines), delegates via Skill() dispatch
- [x] make eval passes with 100% score -- 50/50

**READY FOR COMPLETION** -- all 5 tasks done, all 6 exit criteria verified.

## Constraints

- No logic duplication: nana-init delegates all real work to py-init/ts-init/dev-init/wiki-init via Skill() dispatch
- SKILL.md must stay <= 120 lines (well under the 350-line complex orchestration ceiling)
- Each orchestration step (language, dev-wiki, knowledge wiki) must be independently skippable

## Assumptions

- No eval scenarios currently reference init (verified during planning). If false: update eval scenarios as an additional task.
- Claude Code's /init collision is the primary user-reported friction. If false: rename still reduces ambiguity.

## Notes

Two-part phase: (1) atomic rename across all references, (2) expand SKILL.md to multi-stage orchestrator. Tasks ordered to enable a rename checkpoint (make test + make eval) before expansion begins.
