# Active Phase Context

Phase: 53 - Open Questions: IRON-004 Scoping, Meta-Decision Expansion, MCP Memory
Status: ACTIVE (0/6 tasks done)
Objective: Resolve 3 open questions: diagnose MCP memory data loss, verify IRON-004 selective injection resolves scenario 015 concern, draft + eval HEU-011 capacity-multiplier for scenario 020 gap.
Scope: .dev-wiki/articles/decisions/**, wiki/heuristics/**, eval/reasoning/**, tests/test_heuristic_evolution.sh, scripts/heuristic-dashboard.py

Key constraints:
- Fresh-runs methodology: all eval conditions in same round
- HEU-011 trigger breadth cap: <=5 scenario matches
- Dual-scenario regression guard for IRON-004 (015 vs 018)
- Verification-first: run matcher check on 015 before committing to eval runs

Exit criteria:
- 3 investigation findings documented (MCP memory, IRON-004, HEU-011)
- HEU-011 drafted, ground-truth mapped, eval'd with regression check
- make test && make eval pass

Gates: [x] direction=approved [ ] delivery=pending
