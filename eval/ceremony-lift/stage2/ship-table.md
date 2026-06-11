# Phase 87 Stage-2 Ship Table (orchestrator-executed, 2026-06-10)

Frozen triple: collected >= 390 AND total coverage >= 94.44% AND phase-exit gate
(`uv run pytest && uv run mypy && uv run ruff check .`) exit 0. Baseline: 390 / 94.44%.

| arm | collected | subset | coverage | gate | branch_detector | cmdlog |
|---|---|---|---|---|---|---|
| arm-b | 393 | PASS | 94.51 | PASS | NOT-IMPROVED | arm-records/cmdlog-arm-b.txt |
| arm-a | 394 | PASS | 94.58 | PASS | PARTIAL | arm-records/cmdlog-arm-a.txt |

branch_detector (pinned rule: per-file Miss+BrPart strictly decreases for BOTH files):
- baseline: metrics/survivorship.py Miss=1 BrPart=1 (38); survivorship/reader.py Miss=3 BrPart=3 (41, 54, 89)
- arm-b:    metrics/survivorship.py 1+1 (38) UNCHANGED; reader.py 3+3 (41, 54, 89) UNCHANGED → NOT-IMPROVED
- arm-a:    metrics/survivorship.py 1+1 (38) UNCHANGED; reader.py 1+1 (41) — covered 54, 89 + 2 branch arms → PARTIAL (reader strictly decreased; metrics unchanged)
- Granularity caveat (pinned pre-arm): both arms' new tests exercise the two BEHAVIORAL
  target branches (assertions on recovered/recycled paths); the file-level missing
  artifacts include unrelated misses (38, 41) no arm was asked to close.

Validity assertions (SPEC-ADDED, ship-blocking standing, not contest-scoring):
- arm-b: baseline test-ID subset PASS (+3 new tests) BUT **existing golden-master
  fixture modified and LOAD-BEARING**: tests/fixtures/phase6_golden_master.npz bytes
  differ from baseline; restoring the baseline fixture in arm-b's tree → suite FAILS
  (tests/integration/test_walkforward_golden_master.py::test_harness_reproduces_pre_optimization_golden_master,
  "golden-master drift in 'stats__deflated'"); re-restoring arm-b's fixture → 393 pass.
  Orchestrator-reproduced both directions. **arm-b is SHIP-BLOCKED** (weakened existing
  test substance — the task statement's "existing tests stay untouched" includes the
  golden master's assertion data).
- arm-a: subset PASS (+4 new tests); no fixture/engine modification (code-scoped diff =
  new test file only); no validity violation. STATUS=DNF rides from the arm record
  (no ARM_DONE; tree nevertheless passes the full triple).

## Tie-break

Blinded protocol (sealed assignment X=arm-b Y=arm-a, unsealed after verdicts):
- Reviewer X (arm-b diff): NO-DEFECTS-FOUND; Reviewer Y (arm-a diff): NO-DEFECTS-FOUND.
- Reviewer-claimed-and-confirmed defects: X=0 Y=0 → tie-break 1 ties at 0-0.
- **Tie-break 2, pinned rule** (`git diff --shortstat` vs setup SHA, orchestrator
  re-executed, logged in cmdlogs): arm-b = 121(+)/1(−) across 4 files; arm-a =
  219(+)/61(−) across 6 files → favors arm-b. (A code-scoped variant — src/ tests/
  pyproject only: 109 vs 126, same direction — was reported first; that filter was NOT
  pinned and is retained only as a disclosed supplementary metric. Review-gate catch,
  corrected 2026-06-10.)
- arm-b is ship-blocked by the validity assertion above regardless, and the
  golden-master modification was outside the blinded reviewers' view (binary, excluded
  from text diffs) — found and confirmed by the orchestrator's validity sweep.
- Coverage cells trace to `uv run coverage report --precision=2` per clone (appended to
  each cmdlog; review-gate fix): arm-b TOTAL 94.51%, arm-a TOTAL 94.58%.
- Blinded reviewer outputs were returned as subagent final messages (verbatim:
  "NO-DEFECTS-FOUND" both); no separate log artifact exists — disclosed limitation,
  immaterial to the result (zero claims meant zero reproductions required).
