---
title: "Phase 57: Hook Consolidation and Enforcement Activation"
aliases: []
category: phases
tags: [hook-registration, enforcement, single-source-of-truth, activation, cascade-failure]
parents: []
created: 2026-05-28
updated: 2026-05-28
source: plan
status: completed
scope: ["modules.json", "scripts/register-settings.py", "templates/.claude/settings.json", "templates/.claude/hooks/enforce-spec.sh", "templates/.claude/hooks/enforce-memory.sh", "templates/.claude/hooks/enforce-loop.sh", "templates/.claude/enforce", "install.sh", "Makefile", "tests/"]
entry_criteria: "Phase 56 completed; C/D experiment root-caused enforcement to never-fired hooks; registry audit confirmed 3 disagreeing sources + global-marker gap"
exit_criteria: "One scope-tagged hook source in modules.json; template generated + drift-tested; marker project-reachable; enforce-spec fires (exit 2) in a fresh scaffold; make test green"
---

## Objective

Make a project's enforcement fully functional from its own scaffold, independent of fragile global `~/.claude` state. Reconcile the three disagreeing hook-registration sources into a single scope-tagged source of truth in `modules.json`, generate the per-project template from it, make the enforce opt-in marker project-reachable, and verify enforce-spec *actually fires* (exit 2) in a freshly-scaffolded project. Fix 1 of the Phase 57+ harness-activation roadmap.

## Scope

- `modules.json` — one canonical scope-tagged `hooks` array (17 project, 1 global); remove per-module + project_local hook lists; preserve markers/extra_dirs/ghost_cleanup
- `scripts/register-settings.py` — scope-aware filtering + regeneration mode
- `templates/.claude/settings.json` — generated artifact (now includes enforcement hooks)
- `templates/.claude/hooks/enforce-{spec,memory,loop}.sh` — project-OR-global marker logic
- `templates/.claude/enforce` — shipped marker
- `install.sh`, `Makefile`, `tests/` — `make template`, drift test, firing test

## Exit Criteria

1. `jq` confirms one scope-tagged hooks array (every entry project|global)
2. Generated template registers enforce-spec/loop/memory
3. `make template` is deterministic and in sync with the committed template (drift test)
4. enforce-spec honors a project marker; marker shipped in template
5. tests/test_settings_template.sh firing test passes (enforce-spec exit 2 in scaffold, empty HOME)
6. make test green

## Constraints

- Backward compatible: existing global registrations + marker keep working (marker logic additive); no destructive global migration (upsert-only)
- Single source of truth: template generated, never hand-edited; drift test in make test
- Fail-open preserved: marker change must not turn a fail-open hook into a blocking one where it previously passed
- Verify firing, not presence: done = scaffold makes enforce-spec exit 2, not file-existence
- Out of scope: flipping the KIT itself to self-enforcement (self-lockout risk); Fixes 2-5

## Checkpoints

- After Task 1: report the project/global scope split before regenerating
- After Task 3: confirm template diffs cleanly and enforcement hooks present before marker work
- After Task 5: confirm enforce-spec exits 2 in empty HOME with only the project marker — if it only fires with the global marker, the marker fix is incomplete (STOP)

## Assumptions

- register-settings.py upsert is deterministic given a fixed hook list/order (needed for drift test)
- Claude Code merges (not overrides) global+project settings hooks
- Shipping an empty `.claude/enforce` in scaffolds is acceptable default-on (inert until `.dev-wiki/` exists)

## Notes

- Third instance of the cascade-failure anti-pattern (MCP CWD, pre-compact orphan, nana-init marker)
- Investigation found a 4th activation axis the handover missed: the enforce marker is global (`$HOME/.claude/enforce`), so per-project registration alone is insufficient
- Sequencing guard: spec + active-phase.md written first (allowlisted) so the kit's live enforce-spec allows this phase's edits to non-allowlisted files (modules.json, scripts/, install.sh, Makefile)
