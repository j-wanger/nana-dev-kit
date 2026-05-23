---
title: "Phase 23: Bug Fixes + README Rewrite complete"
aliases: [2026-05-22-phase-23-bug-fixes-readme-complete]
category: journal
tags: [bugs, readme, hooks, install, phase-23]
parents: [phase-23-bug-fixes-readme]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 23: Bug Fixes + README Rewrite -- Complete

## Summary

Fixed two orphaned artifacts (pre-compact.sh hook registration, memory-harvest.md API mismatches) and rewrote README.md for v0.4.0. All 6 tasks completed, all exit criteria met.

## Tasks Completed (6/6)

1. [x] Register pre-compact.sh in settings.json (S)
2. [x] Add pre-compact.sh to install.sh dev-wiki module (M)
3. [x] Fix memory-harvest.md API mismatches (S)
4. [x] Rewrite README.md (M)
5. [x] Update tests (S)
6. [x] Commit + push (S)

## Health Delta

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Tests | 133 | 142 | +9 |
| Eval | 38/38 | 38/38 | unchanged |
| VERSION | 0.4.0 | 0.4.0 | unchanged |
| README lines | 59 | 93 | +34 |

New tests: 2 install PreCompact assertions, 5 template memory-harvest+README+PreCompact assertions, 2 Phase 22 carryover.

## Bugs Fixed

1. **pre-compact.sh orphaned registration** -- hook existed in templates/ since Phase 15 but was never registered in settings.json hooks or copied by install.sh. Now in dev-wiki module group with PreCompact event type.
2. **memory-harvest.md API mismatches** -- used invalid categories (lesson/constraint/correction) and non-existent `confidence` param. Rewritten to match memory-bridge.md pattern: category="custom", tags, trust param.

## Decisions

- [[pre-compact-dev-wiki-module]] -- pre-compact.sh belongs in dev-wiki module (not core), depends on .dev-wiki/ files. High confidence.
- [[readme-budget-superseded]] -- README budget increased from ~58 to 90-100 lines, 7-section structure. Supersedes [[readme-concise-format]]. High confidence.

## Soft Observations

1. Structured external review leading to prioritized bug fix phase was highly productive (2 phases in 1 session, 0 blocked tasks).
2. install.sh printed output doesn't mention pre-compact.sh in "Installed:" summary -- cosmetic gap, not blocking.

## Gate Compliance

spec=8/10, approach=8/10, plan-review=n/a (approach reviewer ran inline), tasks=yes. Standard ceremony with plan-review n/a acceptable for low-risk bug fix phase.

## Cross-References

- Spec: `specs/phase-23-bug-fixes-readme.md` (approved 8/10)
- Decisions: [[pre-compact-dev-wiki-module]], [[readme-budget-superseded]]
- Phase article: [[phase-23-bug-fixes-readme]]
- Prior phase: [[2026-05-22-phase-22-session-start-refactor-complete]]
