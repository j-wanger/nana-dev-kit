---
title: "Phase 31: Integration Eval + Memory Gating"
aliases: []
category: phases
tags: [eval, enforcement, memory, hooks]
parents: []
created: 2026-05-23
updated: 2026-05-24
source: debrief
status: completed
scope: ["eval/corpus/lifecycle-full-phase-cycle/", "eval/corpus/hook-enforce-memory-*/", "templates/.claude/hooks/enforce-memory.sh", "templates/.claude/hooks/session-start.sh", "install.sh", "tests/test_templates.sh", "tests/test_install.sh"]
entry_criteria: "Phase 30 complete, 181 tests passing, 43/43 eval"
exit_criteria: "lifecycle-full-phase-cycle eval scenario passes, enforce-memory.sh blocks/allows correctly, install.sh registers enforce-memory + creates marker, 3+ enforce-memory eval scenarios pass, all tests + eval 100%"
---

# Phase 31: Integration Eval + Memory Gating

## Objective

Two independent deliverable tracks: (A) Create a lifecycle eval scenario exercising a full 4-step hook chain (session-start, enforce-spec, post-commit, enforce-loop), and (B) Create enforce-memory.sh PreToolUse hook following enforce-spec.sh patterns, with session-start.sh integration, install.sh registration, and eval coverage.

## Scope

Files and modules affected:
- `eval/corpus/lifecycle-full-phase-cycle/` -- 4-step lifecycle scenario
- `eval/corpus/hook-enforce-memory-*/` -- 3-4 enforce-memory eval scenarios
- `templates/.claude/hooks/enforce-memory.sh` -- new PreToolUse enforcement hook
- `templates/.claude/hooks/session-start.sh` -- clear .memory-consulted marker
- `install.sh` -- copy hook, create marker, register in settings.json
- `tests/test_templates.sh` -- enforce-memory assertions
- `tests/test_install.sh` -- hook copy + marker + JSON registration assertions

## Exit Criteria

- [ ] lifecycle-full-phase-cycle eval scenario exists and passes
- [ ] enforce-memory.sh blocks writes without memory consultation, allows after
- [ ] session-start.sh clears .memory-consulted at session start
- [ ] install.sh copies hook, creates ~/.claude/enforce-memory marker, registers PreToolUse in settings.json
- [ ] 3+ enforce-memory eval scenarios pass
- [ ] make test && make eval 100%

## Approach

Track A (Task 1): Lifecycle scenario with 4 steps exercising session-start, enforce-spec (allow), post-commit (detect), enforce-loop (pass) in sequence.

Track B (Tasks 2-5): enforce-memory.sh follows enforce-spec.sh patterns verbatim: jq fail-open guard, CI bypass, opt-in marker check, JSON parse file_path, path allowlist, gate check (.claude/.memory-consulted), enforcement.log event writing with 500-line cap, [nana:enforce-memory] stderr. session-start.sh clears the gate marker. install.sh auto-creates the opt-in marker (default-on for compliance-domain users).

## Constraints

- enforce-memory.sh must follow enforce-spec.sh structure verbatim (jq guard, CI bypass, marker check, path allowlist, enforcement.log)
- Path conventions: opt-in marker ~/.claude/enforce-memory (home-relative), gate marker .claude/.memory-consulted (CWD-relative)
- install.sh registration is global ~/.claude/settings.json only (not templates/.claude/settings.json)

## Notes

- 3 decisions: memory-enforcement-auto-create, trust-based-memory-gate, settings-registration-global-only
- Tasks ordered by dependency: 1 (independent), 2 (independent), 3 (depends 2), 4 (depends 2), 5 (depends 1-4)
