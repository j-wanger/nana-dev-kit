---
title: "Phase 26: Memory & Harness Hardening"
aliases: []
category: phases
tags: [memory, harness, supersede, crash-recovery, testing]
parents: []
created: 2026-05-23
updated: 2026-05-23
source: plan
status: active
scope: ["templates/.claude/skills/dev-plan/memory-bridge.md", "templates/.claude/skills/dev-debrief/memory-harvest.md", "templates/.claude/hooks/session-start.sh", "tests/test_templates.sh", "README.md", "eval/corpus/hook-session-start-*/"]
entry_criteria: "Phase 25 complete, 159 tests passing, 41/41 eval"
exit_criteria: "memory-bridge + harvest have supersede logic, session-start crash recovery, cross-skill ref test, README Windows note, 2 eval scenarios, all tests pass, eval 100%"
---

# Phase 26: Memory & Harness Hardening

## Objective

Add memory supersession (auto-cleanup of stale bridge decisions and harvest corrections), session-start crash recovery detection, cross-skill reference validation test, and README Windows note.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/memory-bridge.md` -- auto-supersede step
- `templates/.claude/skills/dev-debrief/memory-harvest.md` -- correction supersede
- `templates/.claude/hooks/session-start.sh` -- crash recovery block
- `tests/test_templates.sh` -- cross-skill reference validation
- `README.md` -- Windows/WSL note
- `eval/corpus/hook-session-start-*/` -- 2 crash recovery eval scenarios

## Exit Criteria

- [ ] memory-bridge.md has ceiling 500, memory_forget, superseded_by
- [ ] memory-harvest.md has ceiling 500, memory_forget
- [ ] session-start.sh has [recovery] output with dual-condition crash detection
- [ ] test_templates.sh has cross-skill reference validation function
- [ ] README.md mentions WSL/Windows
- [ ] 2+ crash recovery eval scenarios pass
- [ ] All existing tests pass, eval 100%

## Constraints

- Do not modify vendor memory_server/ code: prevents upstream breakage
- memory_forget with superseded_by only, no memory_prune: wrong trust level for bridge/harvest entries
- Crash recovery is advisory only (exit 0): prevents workflow disruption from false positives

## Assumptions

- memory_forget MCP tool accepts superseded_by parameter. If false: document as known limitation, skip supersession chain.
- stat -f (macOS) and stat -c (Linux) both available. If false: use only one platform variant with graceful skip.

## Notes

4 workstreams: memory-bridge supersede, memory-harvest supersede, session-start crash recovery, cross-skill ref + README. Task 6 depends on Task 3. Budget: 245/300 lines instruction budget.
