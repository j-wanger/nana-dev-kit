---
title: "Phase 27: DX + Ship complete"
aliases: []
category: journal
tags: [dx, ship, readme, version, regression-tests]
parents: [phase-27-dx-ship]
created: 2026-05-23
updated: 2026-05-23
source: debrief
---

# Phase 27: DX + Ship complete

## What Happened
- Fixed 5 stale numbers in README.md: eval scenario count (x2), hook fidelity count, test count, eval count in testing section. All now match actual counts.
- Added 3 dynamic README accuracy regression tests in test_templates.sh: eval scenario count (computed via find), hook fidelity count (computed via find), and test script count. These compute actual counts and compare against README claims, so future drift is caught automatically.
- Polished install.sh summary output to list all 5 global hooks (enforce-spec, enforce-loop, detect-loop, post-commit, pre-compact).
- Bumped VERSION to 0.5.0, tagged v0.5.0, pushed to GitHub.

## Problems Solved
- Static grep counting of test_start calls can't handle loop-based tests (5 missed in the 6-item jq hook loop in test_templates.sh). Worked around by testing eval scenario count and hook fidelity count instead (both statically countable).
- State loader subagent read stale test count from active-phase.md (said 159 vs actual 160 at phase start). Low-impact: the README was updated to the correct runtime-verified count (163 after adding new tests).

## Artifacts Changed
- `README.md` (5 stale numbers fixed)
- `tests/test_templates.sh` (3 new dynamic README accuracy assertions)
- `install.sh` (summary echo lines list all 5 global hooks)
- `VERSION` (0.4.0 -> 0.5.0)

## Related
- [[phase-27-dx-ship|Phase 27: DX + Ship]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- Static grep counting of test_start calls is unreliable for loop-based tests; future test count assertions should use runtime counting or accept the limitation | candidate: test harness improvement | evidence: this session
- State loader subagent can read stale data from active-phase.md; cross-checking against make test output would fix but cost may not justify benefit | candidate: state loader accuracy | evidence: this session
