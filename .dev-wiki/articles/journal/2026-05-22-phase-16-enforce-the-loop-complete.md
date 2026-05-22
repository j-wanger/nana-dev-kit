---
title: "Phase 16: Enforce the Loop — complete"
aliases: []
category: journal
tags: [hooks, enforcement, lifecycle, distribution, testing]
parents: [phase-16-enforce-the-loop]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 16: Enforce the Loop — complete

## What Happened
- Built two enforcement hooks: enforce-spec.sh (PreToolUse, 58 lines) blocks implementation writes without an approved spec; enforce-loop.sh (Stop, 85 lines) verifies file-existence deliverables at session end
- Hooks install globally to ~/.claude/hooks/ with per-project opt-in via .claude/enforce marker. install.sh gained hooks module + JSON merge for settings.json hooks registration
- session-start.sh reports enforcement status (active/inactive)
- 15 new tests: 10 fixture-based enforcement tests (test_enforce.sh) + 5 install assertions

## Decisions Made
- [[global-hooks-project-opt-in|Global hooks with project-level opt-in]] -- confidence upgraded medium -> high (validated in implementation)
- [[lightweight-deliverable-check-stop|Lightweight deliverable check at Stop]] -- confidence upgraded medium -> high (approach reviewer caught real latency/false-positive risk)
- [[python-json-parsing-hooks|Python JSON parsing in hooks]] -- confidence upgraded medium -> high (consistent with existing hooks, within 100ms budget)

## Problems Solved
- HOME vs CWD in test subshells: $(setup_fixture) doesn't export HOME to parent shell. Fixed by using inline `HOME=... command` instead of export in subshell
- Spec reviewer scored 7/10 initially — "current session" task ambiguity and missing blocking exit criterion were real issues; revised spec before implementation

## Open Questions
- /spec routing: skill listed in available skills but not recognized as command. Persisted across 3 phases now. (raised 2026-05-21, carried forward)

## Artifacts Changed
- `templates/.claude/hooks/enforce-spec.sh` (new — PreToolUse spec enforcement, 58 lines)
- `templates/.claude/hooks/enforce-loop.sh` (new — Stop deliverable check, 85 lines)
- `templates/.claude/hooks/session-start.sh` (enforcement status reporting)
- `install.sh` (hooks module, enforce marker, JSON merge for hooks registration)
- `tests/test_enforce.sh` (new — 10 fixture-based enforcement tests)
- `tests/test_install.sh` (5 new enforcement assertions, 43 total)
- `Makefile` (test_enforce.sh target added)

## Health Delta
- Tests: 92 -> 107 (+15)
- Budget: 245/300 (unchanged)
- Soul: 59/60 (unchanged)

## Related
- [[phase-16-enforce-the-loop|Phase 16: Enforce the Loop]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- Approach reviewer descoping suggestion (full success-field re-execution -> file-existence only) was high-value — caught real latency/false-positive risk before implementation | suggest: review gate for approach descoping has proven ROI | evidence: this journal
- Subshell variable propagation is a recurring test-authoring gotcha — consider documenting in test helpers | suggest: test-authoring guide or helpers.sh comment | evidence: this journal
