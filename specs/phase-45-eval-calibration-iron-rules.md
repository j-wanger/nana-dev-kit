<!-- nana:approved 2026-05-26 -->
# Spec: Eval Calibration & IRON RULES

## Objective

Break the reasoning eval ceiling (5/5 saturation) with harder scenarios and recalibrated scoring, then introduce IRON RULES as the first structured reasoning improvement and measure their delta against the new baseline.

## Context

Phase 44 established the reasoning eval pipeline (eval/reasoning/) with 10 decision scenarios and LLM-as-judge scoring (3 dimensions, 1-5 each). All scenarios score 5/5 across 3 runs with 0 variance — the eval cannot distinguish reasoning quality levels. Two causes: (1) scenarios have clear right answers that any capable model gets right, (2) same-model-family grading inflates scores (self-grading bias). The cognitive enhancement plan (Phases 44-50+) requires a working eval to measure each subsequent feature's impact. IRON RULES are the next reasoning feature — hard-and-fast rules an agent should never violate during decisions. This phase bundles eval calibration (measurement infrastructure) with IRON RULES (first feature), strictly sequenced: calibrate first, then measure.

## Scope

### In scope
- 10 new harder reasoning scenarios (ambiguous tradeoffs, multi-stakeholder, no-single-right-answer)
- Recalibrated judge prompt with stricter rubric anchoring
- Calibration acceptance criterion (non-saturation check)
- IRON RULES format definition and 5-8 seed rules
- IRON RULES injection mechanism for eval measurement
- Delta measurement: new baseline vs. with-IRON-RULES
- Per-scenario score reporting (not just averages)

### Out of scope
- Anti-pattern tables (future phase per cognitive enhancement plan)
- Cross-model judging (deferred — address if calibration alone fails)
- Heuristic evolution/scoring (Phase 50)
- IRON RULES runtime injection into session-start (future — this phase is eval-only measurement)
- Changes to existing 10 scenarios (preserve for backward comparison)

## Approach

**Calibration Acceptance Criterion (referenced throughout):** Mean score across all 20 scenarios < 4.5 AND at least 3 scenarios have per-scenario mean < 4.0 across 3 runs. This threshold ensures the eval can differentiate reasoning quality levels, not merely that one score dipped below ceiling.

**Part A — Eval Calibration (do first, commit results before Part B):**
Write 10 new scenarios at difficulty levels medium (4) and hard (6). Hard scenarios have genuine tradeoffs where reasonable people disagree — the "expert answer" is a position, not a fact. Recalibrate the judge prompt with stricter rubric anchors (e.g., "5 requires naming the specific tradeoff AND explaining why alternatives fail"). Run 3 calibration runs. If calibration acceptance criterion passes, commit new baseline.

**Part B — IRON RULES (only after Part A passes):**
Define IRON RULES format as heuristic articles with `status: iron` and `confidence: absolute`. Update SCHEMA.md status enum to include `iron`. Write 5-8 seed rules mined from soul, working-knowledge, and decision history — these are unconditional rules, not situational heuristics. Each IRON RULE must have all 6 required sections from SCHEMA.md.

**IRON RULES injection mechanism:** Concatenate all IRON-*.md content into a single context block. Prepend this block to each scenario's `context` field before submitting to the agent subagent. The judge sees the agent's response but NOT the IRON RULES injection — it scores reasoning quality, not rule-following. Store the injection approach in results metadata for reproducibility.

Run eval with IRON RULES injected. Report per-scenario delta against the Part A baseline.

## Constraints (CRITICAL)

- **Calibration gates IRON RULES measurement.** If calibration acceptance criterion fails (see Exit Criteria), Part B ships without a measured delta, explicitly documented as "unmeasured." Do not fabricate a delta from a broken instrument.
- **Same judge prompt for both baselines.** The judge prompt used for calibration baseline MUST be identical to the one used for IRON RULES measurement. If the judge changes, the baseline must be re-run.
- **Hard scenarios need defensible reference answers.** "Ambiguous" does not mean "no right answer" — it means "multiple reasonable positions." Each scenario must have a reference answer with explicit reasoning chain. Validate: reference answer stable across 3 judge runs (variance < 0.5).
- **IRON RULES must not conflict with existing heuristics.** Cross-reference each rule against all 10 seed heuristics. If tension exists, the rule must include an explicit precedence clause.
- **Existing 10 scenarios preserved.** New scenarios are additive (011-020). Original baseline remains for backward comparison.
- **Per-scenario reporting required.** Report individual scenario scores, not just dimension averages. A net-positive average that masks a regression on any scenario must be flagged.

## Deliverables

1. `eval/reasoning/corpus/011-*.json` through `020-*.json` — 10 new scenarios (4 medium, 6 hard)
2. `eval/reasoning/judges/reasoning-judge-v2.md` — recalibrated judge prompt with stricter anchors
3. `eval/reasoning/baseline/results-v2.json` — new baseline scores (20 scenarios total)
4. `wiki/heuristics/IRON-*.md` — 5-8 IRON RULES in heuristic format with `status: iron`
5. `eval/reasoning/with-iron-rules/results.json` — delta measurement results
6. `eval/reasoning/README.md` — updated documentation covering v2 eval, IRON RULES, methodology

## Exit Criteria (machine-checkable)

- [ ] `[ $(find eval/reasoning/corpus -name '*.json' | wc -l) -ge 20 ]` — 20+ scenarios exist
- [ ] `test -f eval/reasoning/judges/reasoning-judge-v2.md` — recalibrated judge exists
- [ ] `test -f eval/reasoning/baseline/results-v2.json` — new baseline committed
- [ ] `python3 -c "import json; d=json.load(open('eval/reasoning/baseline/results-v2.json')); scores=[s for r in d['runs'] for e in r for s in e['scores'].values()]; below=sum(1 for s in scores if s<5); assert below>=len(scores)*0.15, f'only {below}/{len(scores)} below ceiling'"` — at least 15% of scores below 5 (non-saturation)
- [ ] `[ $(find wiki/heuristics -name 'IRON-*.md' | wc -l) -ge 5 ]` — 5+ IRON RULES exist
- [ ] `grep -l '^status: iron' wiki/heuristics/IRON-*.md | xargs -I{} grep -c '## Always' {} | grep -v '^0$' | wc -l | grep -qE '^[5-9]'` — all IRON RULES have required sections
- [ ] `grep -q 'iron' wiki/heuristics/SCHEMA.md` — SCHEMA.md updated with iron status
- [ ] `test -f eval/reasoning/with-iron-rules/results.json` — delta measurement exists (even if unmeasured note)
- [ ] `make test` passes
- [ ] `make eval` 100%

## Checkpoints

- After writing 10 new scenarios: review difficulty distribution (4 medium, 6 hard) before running calibration
- After calibration run: check calibration acceptance criterion (mean < 4.5, ≥3 scenarios with per-scenario mean < 4.0). If criterion fails, STOP and report. Consider whether cross-model judging is needed before proceeding to Part B.
- After IRON RULES written: cross-reference against existing 10 heuristics before measuring delta
- If calibration acceptance criterion fails after judge recalibration: deliver Part A findings, document that IRON RULES are "unmeasured," suggest cross-model judging for Phase 46

## Assumptions

- Anthropic SDK available for eval runs (same as Phase 44). If unavailable: document methodology, defer live runs.
- 10 harder scenarios can be written from nana-dev-kit history + adjacent domains. If insufficient source material from project history: use generic software engineering tradeoffs (same transferability test as heuristics).
- Recalibrating the judge prompt alone (without cross-model judging) can break the ceiling. If false: the phase delivers calibrated scenarios + IRON RULES without a delta, and cross-model judging becomes Phase 46 scope.
- IRON RULES can reuse the heuristic article format with a `status: iron` field, requiring SCHEMA.md update to add `iron` to the status enum. If the format proves insufficient: define a minimal separate schema, but avoid duplicating wiki infrastructure.
