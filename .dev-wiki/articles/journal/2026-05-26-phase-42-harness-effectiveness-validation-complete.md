---
title: "Phase 42: Harness Effectiveness Validation complete"
aliases: []
category: journal
tags: [eval, comparison, effectiveness, swe-bench, subagent, methodology]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-26
updated: 2026-05-26
source: debrief
---

# Phase 42: Harness Effectiveness Validation complete

## What Happened
- Executed all three comparison conditions on a "hard" SWE-bench task (Django ORM aggregate/alias SQL generation).
- Condition A (bare baseline) and B (context injection) ran as parallel subagents; both produced working fixes (~90 lines each) scoring 3/4 on structural acceptance tests.
- Condition C (full harness, manual user session) achieved 4/4 via iterative debugging (~200K+ tokens vs ~120-150K for A/B).
- Initial A/B runs were contaminated with Condition C implementation details (identity matching, 3-tier pruning); caught by user, discarded, clean reruns executed.
- Three independent blind review subagents evaluated all implementations: A wins robustness (8/10), B wins maintainability (8/10), C wins correctness (9/10).
- Acceptance test asymmetry identified as primary confound: C had structural SQL tests during development, A/B did not. Both A/B produce correct results but different SQL shapes.

## Decisions Made
- [[experimental-contamination-protocol|Experimental contamination protocol]] -- clean rerun protocol established after user caught leaked details
- [[swe-bench-comparison-confound|SWE-bench comparison confound]] -- acceptance test asymmetry acknowledged as primary confound
- [[multi-angle-subagent-review|Multi-angle subagent review]] -- 3 independent blind reviewers for complementary quality assessment

## Open Questions
- Does context injection help on tasks where soul/rules content is domain-relevant (not Django ORM)?
- Would giving A/B the acceptance tests (structural SQL checks) close the gap with C?
- Is the token-quality curve (threshold ~95K for clean fix) stable across different SWE-bench tasks?

## Artifacts Changed
- `eval/comparison/results-template.md` (filled with actual results from all three conditions)
- `eval/comparison/results/` (JSON results from executed comparisons)
- `eval/comparison/starters/` (two Python project scaffolds)
- `eval/comparison/tasks/` (frozen task specifications)
- `eval/comparison/scripts/` (setup, metrics, hook wrapper scripts)
- `eval/comparison/methodology.md` (experimental methodology)
- `eval/comparison/run-guide.md` (step-by-step protocol)

## Health Delta
- No changes to nana-dev-kit core code or tests
- Tests: stable at ~303 (make test passes)
- Eval: stable at 50/50 (100%)

### Activation Quality
- 4 entries (eval harness patterns, self-grading bias, three-condition design, Python task choice): 4/4 hit rate (100%)

## Soft Observations / Phase N+1 Candidates
- Token budget dominates quality: at ~120-150K tokens (clean runs), both A and B achieve 3/4. Interactive C at ~200K+ achieves 4/4. The last 25% quality costs ~80K tokens of iterative debugging. Investigate multi-turn subagent execution with checkpointing.
- Context injection improves efficiency not correctness: B used 19% fewer tokens and scored 8/10 maintainability (vs A's 6/10), but same 3/4 acceptance. Soul files may improve code STYLE without improving code CORRECTNESS.
- Mirror-image failure modes: A too aggressive (removes aggregates), B too conservative (keeps aliases). Same boundary confusion as C's first attempt, but C could iterate. Aggregate/alias distinction is a natural difficulty cliff.
- Acceptance test access is the real confound: C had structural SQL tests; A/B only had correctness tests. Both A/B produce CORRECT results with different SQL shapes. The 3/4 vs 4/4 gap is about SQL structure, not result correctness.
- Subagents can solve hard SWE-bench: both clean A and B produced working fixes for a "hard" task in 18-22 minutes, scoring 3/4 on structural tests with 0 pre-existing regressions.

## Duration
~60 min active session (Condition C fix ~45 min, A/B trials + analysis ~15 min)

## Related
- [[phase-42-harness-effectiveness-validation|Phase 42]]
