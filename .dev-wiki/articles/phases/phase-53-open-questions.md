---
title: "Phase 53: Open Questions — IRON-004 Scoping, Meta-Decision Expansion, MCP Memory"
aliases: [phase-53-open-questions]
category: phases
tags: [iron-rules, heuristics, mcp-memory, investigation]
parents: []
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: [".dev-wiki/articles/decisions/**", "wiki/heuristics/**", "eval/reasoning/**", "tests/test_heuristic_evolution.sh", "scripts/heuristic-dashboard.py"]
entry_criteria: "Phase 52 complete, open questions documented in _CURRENT_STATE.md"
exit_criteria: "3 investigations documented, HEU-011 drafted + eval'd, make test + make eval pass"
---

# Phase 53: Open Questions — IRON-004 Scoping, Meta-Decision Expansion, MCP Memory

## Objective

Resolve 3 open questions from the cognitive enhancement roadmap: diagnose MCP memory data loss, verify whether IRON-004 selective injection resolves scenario 015 concern, and draft HEU-011 (capacity-multiplier) for scenario 020's persistent reasoning gap.

## Scope

Files and modules affected:
- `.dev-wiki/articles/decisions/` -- investigation findings + MCP diagnosis
- `wiki/heuristics/` -- HEU-011 draft, possible IRON-004 edit
- `eval/reasoning/` -- ground-truth.json update, eval runs
- `tests/test_heuristic_evolution.sh` -- HEU-011 format assertions
- `scripts/heuristic-dashboard.py` -- verify HEU-011 appears

## Exit Criteria

- [ ] MCP memory diagnosis documented with Root Cause / Evidence / Resolution
- [ ] IRON-004 investigation finding documented (either "resolved by selective injection" or eval-backed analysis)
- [ ] HEU-011 drafted in SCHEMA.md format, ground-truth mapped (<=5 matches), cross-IRON conflict checked
- [ ] HEU-011 eval'd on scenario 020 with fresh-runs methodology + regression check
- [ ] Tests pass: test_heuristic_evolution.sh includes HEU-011, dashboard shows HEU-011
- [ ] make test && make eval pass

## Constraints

- Fresh-runs methodology: all eval conditions in same round, cross-round comparisons invalid
- HEU-011 trigger breadth cap: <=5 scenario matches (narrow trigger)
- Dual-scenario regression guard for IRON-004: reject if 015 improves >=0.5 but 018 drops >=0.5
- Counter isolation: counters remain retrospective analytics only

## Checkpoints

- After Task 2 (IRON-004 matcher check): if IRON-004 not selected for 015, report early closure
- After Task 3 (HEU-011 draft): if trigger matches >5 scenarios, narrow before proceeding to eval

## Assumptions

- Ground-truth.json accurately reflects Phase 51 matcher assignments. If not: re-run --selective to verify.
- MCP memory server DB files exist at expected paths. If not: document absence as finding.

## Notes

Three sequential investigations with independent success criteria. Order: MCP memory first (orthogonal, quick diagnostic), then IRON-004 (analysis before new heuristic), then HEU-011 (builds on IRON-004 findings). Decision: verification-first-iron004 (run matcher check before committing to eval runs).
