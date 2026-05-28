<!-- nana:approved 2026-05-27 -->
# Spec: Open Questions — IRON-004 Scoping, Meta-Decision Heuristic, MCP Memory

## Objective

Investigate and resolve three open questions: (1) IRON-004's interaction with deadline-constrained scenarios (015), (2) the capacity-multiplier reasoning gap on scenario 020 via a new heuristic, (3) MCP memory server data loss root cause.

## Context

Phase 52 completed the 7-phase cognitive enhancement roadmap. Three open questions remain from _CURRENT_STATE.md, selected by the user for Phase 53:

**IRON-004 scoping (scenario 015):** IRON-004 ("simpler system wins") has a known interaction with scenario 015 (auth rewrite vs refactor under 8-week security deadline). The expert answer IS the incremental refactor — so IRON-004 pushes toward the correct output, but the concern is it does so via "simplicity" rather than deadline-aware incremental reasoning. Phase 46 added a "lifecycle complexity" Never clause that fixed scenario 018 (feature flag debt), but 015's interaction persists. The ground-truth mapping (eval/reasoning/selective/ground-truth.json) maps 015 to IRON-005 only, not IRON-004. IRON-004 is the most broadly applicable rule (6/25 scenarios).

**Meta-decision / capacity-multiplier (scenario 020):** Scenario 020 (tech debt triage) consistently fails — 8/9 runs choose dependency upgrade (most urgent/visible) instead of test reliability (the capacity multiplier that unblocks all future work). Ground-truth mapping shows `relevant: []` for scenario 020 — no existing heuristic covers this pattern. The 3-heuristic injection cap (max 3 per invocation, 1200-char combined) means any new heuristic competes for slots.

**MCP memory data loss:** At Phase 50 start, memory_search returned 0 entries despite population in prior phases. The vendored memory server (memory_server/) uses SQLite with project-scoped (.memory/memory.db relative to CWD) and global (~/.memory/global.db) databases. CWD is ~/.claude per settings.json. Phase 34 fixed a prior CWD misconfiguration. No investigation has been done.

## Scope

### In scope
- IRON-004 analysis: 3 eval runs per scenario on 015 and 018 to establish current baseline, identify whether the issue is trigger overbreadth or rule content, propose and test a fix if warranted
- New HEU-011 heuristic article for capacity-multiplier reasoning: draft, ground-truth mapping against all 25 scenarios, eval verification
- MCP memory investigation: root cause diagnosis, DB file verification, fix if it's a configuration issue
- Updated ground-truth.json with new heuristic mappings
- Tests for new heuristic article format compliance
- Updated SCHEMA.md if new patterns emerge

### Out of scope
- Modifying the judge prompt or matcher prompt (structural changes to the eval pipeline)
- Adding new eval scenarios (the 25-scenario corpus is stable)
- Modifying other IRON RULES beyond IRON-004
- Rebuilding or replacing the memory server (fix the config/path issue, don't rewrite)
- Haiku judge inter-run variance (not selected for this phase)
- Heuristic counter-update or lifecycle transitions (Phase 52 infrastructure, not exercised here)
- Fixing memory server code bugs if corruption is in vendored code (document and escalate)

## Approach

Three sequential investigations with independent success criteria. Order: MCP memory first (orthogonal, quick diagnostic), then IRON-004 (analysis before new heuristic), then HEU-011 (builds on IRON-004 findings).

**Investigation 1: MCP Memory Diagnosis (time-box: 30 minutes).** Before any investigation, back up existing DB files (*.db, *.db-wal, *.db-shm) from ~/.memory/ and ~/.claude/.memory/ to a timestamped backup directory. Check: (a) which DB file the server actually opens by examining CWD config in settings.json and config.py path resolution, (b) whether entries exist in global.db vs project-scoped .memory/memory.db (scope mismatch), (c) SQLite WAL state (uncommitted transactions in .db-wal via `sqlite3 <db> 'PRAGMA wal_checkpoint;'`). Outcome: root cause identified and documented. Fix applied if it's a configuration issue. If root cause is not identifiable within 30 minutes, document findings so far and proceed to Investigation 2.

**Investigation 2: IRON-004 Scenario 015 Analysis.** Run 3 eval runs per scenario on scenarios 015 and 018 (6 runs total) to establish current means. Analyze whether IRON-004 is actively harming 015 reasoning or whether the "right answer for wrong reasons" concern is theoretical. If IRON-004 is measurably harmful on 015 (mean < 4.0 on any dimension), draft a scoping amendment to the When/Never sections and re-eval. Any fix must preserve the Phase 46 lifecycle-complexity clause (018 regression guard). Run cross-IRON conflict check per Phase 45 methodology after any edit. If IRON-004 is NOT measurably harmful on 015, document the finding and close the open question.

**Investigation 3: HEU-011 Capacity-Multiplier Heuristic.** Draft a new heuristic article (HEU-011) following SCHEMA.md format (wiki/heuristics/SCHEMA.md). Trigger must be narrow: "choosing between multiple initiatives where one is a prerequisite or enabler for the others." Map against all 25 scenarios in ground-truth.json — reject if trigger matches more than 5 scenarios (trigger too broad, same problem as IRON-004). Verify IRON-001 ("measure before optimizing") doesn't already cover this — ground-truth shows 020 has `relevant: []`, confirming it's a genuine blind spot. Run 3 eval runs per scenario on scenario 020 with HEU-011 injected to measure delta. Check for regression on 3-5 adjacent scenarios where HEU-011 trigger might partially match.

## Constraints (CRITICAL)

- **IRON-004 dual-scenario regression guard:** Any modification to IRON-004 must be eval-verified on BOTH scenarios 015 AND 018 in the same fresh eval round (cross-round baselines are invalid per established methodology). A fix that improves 015 mean by ≥0.5 but drops 018 mean by ≥0.5 is rejected. 3 runs per scenario, delta ≥0.5 with variance <0.5 is meaningful. Prevents: regressing the Phase 46 fix while addressing a new concern.
- **New heuristic trigger breadth cap:** HEU-011 must match ≤5 of 25 scenarios in ground-truth mapping. IRON-004 at 6/25 is the upper bound of acceptable breadth — broader triggers cause surface-reading failures. Prevents: a new heuristic that triggers everywhere and dilutes context.
- **DB backup before memory investigation:** Copy all *.db, *.db-wal, *.db-shm files from ~/.memory/ and ~/.claude/.memory/ to a timestamped backup directory before any SQLite queries or fixes. Prevents: accidental data loss during diagnosis (WAL files contain uncommitted transactions).
- **Cross-IRON conflict check after any edit:** After modifying IRON-004, run clause-by-clause comparison against IRON-001 through IRON-005 per Phase 45 methodology. IRON-001 ("measure before optimizing") is adjacent to capacity-multiplier territory — ensure no contradictory guidance. Prevents: two IRON rules giving opposing advice on the same scenario.
- **Eval isolation:** IRON-004 investigation and HEU-011 investigation use separate eval runs, not combined. Testing both changes simultaneously confounds attribution. Prevents: misattributing improvement to the wrong change.
- **Counter-update isolation:** Eval runs use run-eval.py which does not invoke Step 6.5 or the counter-update companion. This is existing behavior. If verification reveals run-eval.py does invoke counter updates, document the finding and proceed without fixing — counter isolation is a Phase 52 concern, not this phase's scope.

## Deliverables

1. MCP memory diagnosis document (`.dev-wiki/articles/decisions/mcp-memory-diagnosis.md`) — root cause with structured sections (## Root Cause, ## Evidence, ## Resolution)
2. IRON-004 analysis results — eval data for scenarios 015/018, finding (harmful/not harmful/inconclusive), any fix applied to `wiki/heuristics/IRON-004-simpler-system-wins.md`
3. `wiki/heuristics/HEU-011-capacity-multiplier.md` — new heuristic article following SCHEMA.md format (~30-40 lines)
4. Updated `eval/reasoning/selective/ground-truth.json` — HEU-011 mappings added
5. Updated `tests/test_heuristic_evolution.sh` — new heuristic format compliance assertions
6. Investigation summary in `.dev-wiki/articles/decisions/phase-53-investigation-findings.md` — consolidated results across all 3 investigations, referencing IRON-004 scenario 015 analysis and HEU-011 eval delta

## Exit Criteria (machine-checkable)

- [ ] `test -f .dev-wiki/articles/decisions/mcp-memory-diagnosis.md && grep -q '## Root Cause' .dev-wiki/articles/decisions/mcp-memory-diagnosis.md`
- [ ] `test -f wiki/heuristics/HEU-011-capacity-multiplier.md && grep -q 'id: HEU-011' wiki/heuristics/HEU-011-capacity-multiplier.md`
- [ ] `grep -q 'HEU-011' eval/reasoning/selective/ground-truth.json`
- [ ] `python3 scripts/heuristic-dashboard.py 2>/dev/null | grep -q 'HEU-011'`
- [ ] `bash tests/test_heuristic_evolution.sh`
- [ ] `test -f .dev-wiki/articles/decisions/phase-53-investigation-findings.md && grep -qi 'IRON-004' .dev-wiki/articles/decisions/phase-53-investigation-findings.md && grep -qi '015' .dev-wiki/articles/decisions/phase-53-investigation-findings.md`
- [ ] `make test && make eval`

## Checkpoints

- After MCP memory diagnosis: report root cause finding before proceeding. If diagnosis reveals that prior eval baselines (Phases 50-52) ran with corrupted memory state, flag this — it could invalidate comparison numbers used for IRON-004 analysis.
- After IRON-004 baseline eval (3 runs per scenario on 015+018): report means and variance. If 015 mean ≥ 4.0 across all dimensions, the open question may be theoretical — present finding and ask whether to proceed with a fix or close the question.
- After HEU-011 draft + ground-truth mapping: report trigger match count. If >5 scenarios, revise trigger before eval.
- After HEU-011 eval: report delta on scenario 020 and regression check on adjacent scenarios.

## Assumptions

- The eval infrastructure (run-eval.py, judge prompts, scenario corpus) works correctly from the Phase 52 state. If false: debug eval infrastructure before investigating open questions.
- IRON-004 is still in the format established by Phase 46 (with the lifecycle-complexity Never clause intact at wiki/heuristics/IRON-004-simpler-system-wins.md). If false: read current state and adjust analysis plan.
- MCP memory server configuration in ~/.claude/settings.json still has CWD: ~/.claude per the Phase 34 fix. If false: the CWD misconfiguration IS the root cause — fix and re-verify.
- The reasoning eval .venv at eval/reasoning/.venv has working dependencies (anthropic SDK). If false: recreate venv with `pip install anthropic` before running evals.
- New heuristic (HEU-011) follows the same article format as HEU-001 through HEU-010: YAML frontmatter with id/trigger/domain/source_phase/confidence/helpful/harmful/status, plus 6 markdown sections (When this applies, Always, Never, Why, Anti-pattern, Source). If false: read wiki/heuristics/SCHEMA.md for current format before drafting.
- MCP memory data loss is a configuration or path resolution issue, not SQLite data corruption. If root cause is vendored server code bug or SQLite corruption: document finding, do not attempt to fix vendored code (divergence risk), escalate to user.
