---
title: "Codebase Snapshot 2026-05-31 (Phase 75 complete)"
aliases: []
category: status
tags: [snapshot, phase-75]
parents: [phase-75-delivery-commit-verification]
created: 2026-05-31
updated: 2026-05-31
source: debrief
---

# Codebase Snapshot — 2026-05-31

## Metrics

| Metric | Value |
|--------|-------|
| Version | 0.5.0 |
| Skill .md files (templates) | 114 |
| Hook .sh files (templates) | 21 |
| Test scripts | 19 (`make test`, UNCHANGED — extended `test_harden.sh`, no new script) |
| Eval scenarios | 52 (`make eval` 100%, UNCHANGED) |
| Decision articles | 162 |
| Phase articles | 75 (all completed; Phase 75 delivery gate pending commit-verify) |

## Module Structure

Unchanged from prior snapshots (see `_ARCHITECTURE.md`). This session touched only:
- `templates/.claude/hooks/session-start.sh` — NEW fail-open divergence-detector branch (sibling to crash-recovery): fires `[nana:recovery]` when active-phase.md shows `- [x] Delivery accepted` for Phase N but `git log` has 0 commits matching `phase[ _-]?N\b`. The PRIMARY fix.
- `templates/.claude/skills/dev-debrief/{delivery-flow.md,executor-prompt.md,SKILL.md}` — D3 commit self-assert + gate-after-commit ordering (executor writes the delivery gate UNCHECKED; D3 flips it post-verified-commit). The SECONDARY fix.
- `tests/test_harden.sh` — +4 RED-first detector firing tests (harden 17/17).
- `.dev-wiki/articles/decisions/delivery-commit-verification.md` (finalized medium→high, accepted).
- `.dev-wiki/articles/phases/phase-75-delivery-commit-verification.md` (NEW). `specs/phase-75-delivery-commit-verification.md` (spec, nana:approved).

## Test Status

- `make test`: 19 scripts green (UNCHANGED — `test_harden.sh` extended to 17 tests; no new make-test script).
- Firing-coverage: 21/21 (no denominator churn — session-start was already counted).
- `make eval`: 52/52 (100%, UNCHANGED).
- `eval/` git-diff-clean. No non-target regression.

## Recent Commits

```
9c70a70 Phase 74 — Harden the Consuming-Project Scaffold Path (+ debrief)
04c63f7 Phase 73 debrief — Cross-Session Substrate (thin handoff): pivot to substrate-construction
52df97e Phase 72 debrief — finalize: index.md, phase-72 article, state + working-knowledge reconcile
ca86d4b Phase 72 — Compaction-Recovery Subtraction: remove dead .session-anchor machinery
74dbde6 Phase 71 debrief — finalize: journal, state, phase→completed, delivery accepted
```

(Phase 75 commit pending — the orchestrator runs the delivery flow / commit + push separately. The delivery gate flips to `[x]` only after the commit verifies — this phase's own fix: gate-state follows git-state.)

## Notes

- Phase 75 is the 2nd dogfood→harden fix surfaced by the edge-screener consuming project (after Phase 74). The dogfood→harden loop is producing real kit fixes.
- Soft observation (2nd instance): the kit's own `/dev-debrief` runs the INSTALLED `~/.claude/skills/dev-debrief/`, so the `templates/` fix is not live for the kit's own debrief until install.sh re-syncs — strengthens the installed-copy-drift-guard candidate.
- `_ARCHITECTURE.md` file inventory predates several phases; broader inventory flagged for a `/dev-scan` refresh.
