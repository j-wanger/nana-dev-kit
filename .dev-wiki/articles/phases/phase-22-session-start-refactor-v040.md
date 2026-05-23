---
title: "Phase 22: Session-Start Refactor + v0.4.0 Ship"
aliases: [phase-22-session-start-refactor-v040]
category: phases
tags: [session-start, refactor, modular, scan-secrets, bsd-grep, release, v0.4.0]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: not-started
scope: ["templates/.claude/hooks/session-start.sh", "templates/.claude/hooks/session-start.d/*", "templates/.claude/hooks/scan-secrets.sh", "eval/corpus/hook-scan-secrets-*/*", "install.sh", "VERSION", "tests/test_harden.sh", "tests/test_install.sh", ".dev-wiki/articles/roadmap-gap-analysis.md"]
entry_criteria: "Phase 21 complete, 128 tests passing, 38/38 eval"
exit_criteria: "session-start.sh refactored into sourced modules, scan-secrets.sh BSD grep fixed, gap analysis updated, v0.4.0 tagged"
---

# Phase 22: Session-Start Refactor + v0.4.0 Ship

## Objective

Extract the two heaviest concerns from session-start.sh (working-knowledge pruning and memory consolidation nudge) into sourced modules under session-start.d/, fix the scan-secrets.sh BSD grep bug, update the stale gap analysis, and ship v0.4.0.

## Scope

Files and modules affected:
- `templates/.claude/hooks/session-start.sh` — refactor into thin orchestrator
- `templates/.claude/hooks/session-start.d/` — new directory for sourced modules
- `templates/.claude/hooks/scan-secrets.sh` — BSD grep fix
- `eval/corpus/hook-scan-secrets-*/*` — update eval fixtures if needed
- `.dev-wiki/articles/roadmap-gap-analysis.md` — update gap statuses
- `install.sh` — copy session-start.d/ contents
- `VERSION` — bump to 0.4.0
- `tests/test_harden.sh` — verify refactored modules work
- `tests/test_install.sh` — verify session-start.d/ installed

## Exit Criteria

- [ ] session-start.sh is a thin orchestrator sourcing modules from session-start.d/
- [ ] working-knowledge pruning extracted to session-start.d/working-knowledge-prune.sh
- [ ] memory consolidation nudge extracted to session-start.d/memory-nudge.sh
- [ ] scan-secrets.sh BSD grep \x27 bug fixed
- [ ] roadmap-gap-analysis.md updated with current gap statuses
- [ ] VERSION = 0.4.0
- [ ] All existing tests pass (128+)
- [ ] All eval scenarios pass (38+)

## Constraints

- session-start.d/ modules must be individually testable (bash -n + direct invocation)
- Refactoring must not change observable behavior (same stdout output, same side effects)
- BSD grep fix must work on both macOS BSD grep and GNU grep

## Assumptions

- source/. pattern in session-start.sh works with Claude Code hook execution environment. If false: inline the modules back and use functions instead.
- session-start.d/ directory is reliably available relative to session-start.sh at runtime. If false: use absolute path from SCRIPT_DIR.

## Notes

- session-start.sh is currently 125 lines with 6+ concerns (dev-wiki state, gate check, session state, memory guidance, loop state clear, memory nudge, working-knowledge pruning, enforcement status)
- The BSD grep bug: \x27 is meant to match single quotes but BSD grep doesn't interpret hex escapes in ERE mode
- Gap analysis was last updated after Phase 18; Phases 19-21 closed additional gaps (1.3, 3.3, 4.2 partially)
