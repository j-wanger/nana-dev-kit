---
title: "Phase 22: Session-Start Refactor + v0.4.0 Ship"
aliases: [session-start-refactor, v0.4.0]
category: phases
tags: [hooks, refactoring, release]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["templates/.claude/hooks/session-start.sh", "templates/.claude/hooks/session-start.d/*", "templates/.claude/hooks/scan-secrets.sh", "eval/corpus/hook-scan-secrets-pattern/*", ".dev-wiki/articles/roadmap-gap-analysis.md", "tests/test_templates.sh", "VERSION"]
entry_criteria: "Phase 21 complete, 128 tests passing, 38/38 eval"
exit_criteria: "session-start.sh ≤70 lines, 2 sourced modules pass bash -n, scan-secrets \x27 removed, gap analysis updated, make test + make eval 100%, v0.4.0 tagged"
---

# Phase 22: Session-Start Refactor + v0.4.0 Ship

## Objective

Extract working-knowledge pruning and memory nudge from session-start.sh into sourced modules, fix scan-secrets.sh BSD grep bug, update gap analysis with Phase 19-21 closures, bump to v0.4.0 and ship.

## Scope

Files and modules affected:
- `templates/.claude/hooks/session-start.sh` -- orchestrator refactor (~125 -> ~60 lines)
- `templates/.claude/hooks/session-start.d/` -- new directory with wk-prune.sh and memory-nudge.sh
- `templates/.claude/hooks/scan-secrets.sh` -- BSD grep fix (line 19)
- `eval/corpus/hook-scan-secrets-pattern/` -- fixture update (atomic with fix)
- `.dev-wiki/articles/roadmap-gap-analysis.md` -- close gaps verified by Phases 19-21
- `tests/test_templates.sh` -- new assertions for session-start.d/
- `VERSION` -- bump to 0.4.0

## Exit Criteria

- [ ] session-start.sh ≤ 70 lines with 2 source directives
- [ ] session-start.d/wk-prune.sh and memory-nudge.sh pass bash -n
- [ ] scan-secrets.sh has no \x27 pattern
- [ ] Gap analysis has ≥4 CLOSED Phase citations
- [ ] make test passes (128+ tests)
- [ ] make eval 100% (38+ scenarios)
- [ ] VERSION reads 0.4.0, tagged and pushed

## Constraints

- Source (not subprocess) required: wk-prune writes to CWD files -- prevents coupling break
- No install.sh changes: session-start.d/ is template-only, not globally installed
- Eval fixture update must be atomic with scan-secrets fix -- prevents eval regression window

## Assumptions

- test_harden.sh covers session-start behavioral equivalence. If false: add targeted tests before refactor.
- Existing 38 eval scenarios remain stable through hook refactor. If false: investigate broken scenarios individually.

## Notes

- session-start.sh is high-fanout: 10 tests + 4 eval scenarios depend on it
- Working-knowledge pruning uses Python date math and writes to CWD
- Gap 4.4 is PARTIAL not CLOSED: Phase 19 added memory->wiki-query and dev-plan->memory, but full bidirectional bridge is incomplete
