---
title: "Phase 26: Memory & Harness Hardening complete"
aliases: []
category: journal
tags: [memory, supersede, crash-recovery, cross-skill, eval]
parents: [phase-26-memory-harness-hardening]
created: 2026-05-23
updated: 2026-05-23
source: debrief
---

# Phase 26: Memory & Harness Hardening complete

## What Happened
- Implemented memory supersession at harness layer: memory-bridge.md and memory-harvest.md both gained auto-supersede steps using memory_forget with superseded_by. Ceiling raised 100 to 500. memory_prune rejected (wrong trust level for bridge/harvest entries).
- Added session-start crash recovery with dual-condition detection: commits newer than _CURRENT_STATE.md mtime AND no debrief commit in recent history. Advisory-only [recovery] output. Single condition rejected due to false positive rate during normal workflow.
- Created cross-skill reference validation test function in test_templates.sh. Found and fixed 1 broken reference: eval-harness/eval-patterns.md in implementation-guide.md pointed to nonexistent file, corrected to eval/README.md.
- Added README Windows/WSL2 note in Requirements section.
- Created 2 eval scenarios for crash recovery (hook-session-start-crash-recovery, hook-session-start-no-recovery). eval-runner.sh gained setup.init_git and setup.touch_old support for git-dependent hook testing.
- Closed Gap 4.3 (worktree/parallel) as won't-build: regular subagents cover parallelism needs.

## Decisions Made
- [[memory-supersede-harness-layer|Memory supersede at harness layer]] -- confirmed from planning
- [[crash-recovery-dual-condition|Crash recovery dual condition]] -- confirmed from planning
- [[cross-skill-ref-test-time|Cross-skill reference validation at test time]] -- confirmed from planning
- [[gap-43-wont-build|Worktree/parallel won't-build]] -- new this session

## Problems Solved
- Broken cross-skill reference: implementation-guide.md referenced eval-harness/eval-patterns.md which didn't exist. Fixed to eval/README.md.
- eval-runner.sh needed git repo support for crash recovery scenarios. Added setup.init_git and setup.touch_old manifest fields.

## Artifacts Changed
- `templates/.claude/skills/dev-plan/memory-bridge.md` (auto-supersede step, ceiling 500)
- `templates/.claude/skills/dev-debrief/memory-harvest.md` (correction supersede, ceiling 500)
- `templates/.claude/hooks/session-start.sh` (crash recovery block)
- `tests/test_templates.sh` (cross-skill reference validation function)
- `README.md` (WSL2/Git for Windows in Requirements)
- `scripts/eval-runner.sh` (setup.init_git, setup.touch_old support)
- `eval/corpus/hook-session-start-crash-recovery/` (new scenario)
- `eval/corpus/hook-session-start-no-recovery/` (new scenario)

## Related
- [[phase-26-memory-harness-hardening|Phase 26]] -- parent phase
- [[roadmap-gap-analysis|Roadmap]] -- Gap 4.3 closed, only 4.1 remains OPEN

## Soft Observations / Phase N+1 Candidates
- DX discoverability is the largest unaddressed cluster from multi-angle critique (no /help, no skill listing, mixed error audiences) | candidate: DX discoverability phase | evidence: multi-angle critique audit
- Language-agnostic core (Gap 4.1) is the last OPEN gap in the roadmap | candidate: language-agnostic phase | evidence: [[roadmap-gap-analysis]]
- Multi-angle critique audit: 6/20 findings addressed (Phases 23-25), 2 partial, 8 remaining real opportunities, 4 won't-fix | tracking: ongoing
