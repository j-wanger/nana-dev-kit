<!-- nana:approved 2026-05-27 -->
# Spec: Phase 48 — Trace Collection & Pattern Analysis

## Objective

Instrument the reasoning eval to collect per-IRON-RULE influence data via targeted leave-one-out ablation runs, then analyze the data to derive selection criteria for conditional heuristic injection.

## Context

Phase 5 of 7 in the cognitive enhancement roadmap. Phases 45-47 established that heuristic content quality is sufficient (IRON RULES + anti-pattern tables improve net scores) but indiscriminate injection causes scenario-specific harm: IRON-004 overrides domain reasoning on 015 (auth rewrite risk), IRON-005 on 020 (force-multiplier prioritization). Self-dialogue (Phase 47) was net negative/neutral — the problem is selection, not critique.

Current eval: 20 scenarios, judge v2 (exemplar-anchored), 3-run protocol, 15 heuristics (10 HEU + 5 IRON). The eval runs via Claude Code subagents. run-eval.py computes stats and comparisons. Results stored as JSON with per-scenario per-dimension scores.

The trace-then-select strategy: this phase collects the data, Phase 49 implements conditional injection using the derived criteria.

## Scope

### In scope
- Trace schema: JSON format for per-heuristic ablation results (scenario × heuristic × run → scores)
- Ablation protocol: leave-one-out runs on differentiating scenarios (012, 014, 015, 018, 020) — remove one IRON RULE at a time, measure per-scenario score delta
- Fresh no-heuristic baseline on differentiating scenarios (identical prompt structure to ablation runs)
- `run-eval.py --ablation` mode: read ablation result files from traces/, validate schema, compute deltas. Ablation runs themselves are orchestrated by the agent via subagents (same as all existing eval runs). run-eval.py stays a pure data utility.
- `run-eval.py --analyze` mode: compute per-heuristic attribution matrix from ablation deltas
- Attribution matrix: per-heuristic × per-scenario classification (helped / hurt / irrelevant) with confidence
- Draft selection criteria document: which heuristics to inject for which scenario types, derived from attribution matrix
- Genuine held-out validation: run leave-one-out ONLY on training scenarios (015, 018, 020). Scenarios 012/014 receive only baseline + full-set runs (no LOO) — genuinely unseen during criteria derivation
- Test assertions for new eval modes and trace schema
- Updated eval/reasoning/README.md with ablation methodology

### Out of scope
- Implementing conditional injection in production (Phase 49)
- Modifying dev-plan SKILL.md or any production skill
- Adding new eval scenarios (existing 20 sufficient)
- Pairwise heuristic interaction analysis (2^15 infeasible — acknowledged as limitation)
- Cross-model judging (separate lever)
- Agent self-reporting / structured response format (confabulation risk too high for causal claims)
- Full ablation matrix on all 20 scenarios (too expensive — 15 × 20 × 3 = 900 runs)

## Approach

Causal attribution via targeted leave-one-out ablation on the scenarios where heuristic interference is known or suspected.

**Phase structure:**
1. Fresh no-heuristic baseline on 5 differentiating scenarios (5 × 3 = 15 runs)
2. Full-set (all 15 heuristics) condition on same 5 scenarios if not already available (5 × 3 = 15 runs)
3. Leave-one-out ablation on TRAINING scenarios only (015, 018, 020): for each of 5 IRON RULES, remove that rule only, run 3 scenarios × 3 runs = 45 runs total. Scenarios 012/014 are genuinely held out from LOO.
4. Analysis: compare leave-one-out scores vs full-set scores — if removing rule X improves scenario Y, rule X hurts scenario Y
5. Classification: for each IRON-rule × training-scenario pair, classify as helped (removal hurts score ≥ 0.5), hurt (removal improves score ≥ 0.5), or irrelevant (delta < 0.5)
6. Derive selection criteria from training classification, validate by predicting 012/014 baseline-to-full-set behavior

**Total eval budget:** ~75 subagent invocations (15 baseline + 15 full-set + 45 ablation). Each invocation = 1 agent + 1 judge subagent.

**Why IRON RULES only (not all 15):** IRON RULES are the known source of interference (IRON-004 on 015, IRON-005 on 020). HEU-001–010 are domain-specific with narrow triggers — less likely to cause cross-domain interference. If IRON RULE ablation reveals unexpected HEU interactions, expand in a follow-up.

## Constraints (CRITICAL)

- Ablation runs MUST use identical prompt structure to the existing eval conditions (same judge v2, same agent prompt template minus the ablated rule). Changing prompt structure invalidates comparability.
  Prevents: instrumentation artifacts masking true heuristic effects.

- Trace schema MUST reference heuristics by ID (IRON-004, HEU-003), include a corpus version field, and fail-open if an ID doesn't match the current corpus.
  Prevents: schema-corpus drift when heuristics are edited or added.

- Classification threshold: delta ≥ 0.5 for "helped" or "hurt" (consistent with existing eval protocol). Variance < 0.5 across 3 runs for the classification to be confident. If variance ≥ 0.5, classify as "uncertain" instead.
  Prevents: noise-driven selection criteria.

- Genuine held-out: run leave-one-out ONLY on training scenarios (015, 018, 020). Scenarios 012/014 receive baseline + full-set only (no LOO). Validate criteria by predicting 012/014 behavior. If criteria produce incorrect predictions on held-out scenarios, they are overfit — document and flag for manual review.
  Prevents: scenario-to-heuristic lookup tables that don't generalize.

- No modifications to production skills or dev-plan. All new code lives in eval/reasoning/.
  Prevents: scope creep into production changes before data supports them.

- Per-dimension attribution required: a heuristic may help on "anti-pattern avoidance" but hurt on "decision quality" for the same scenario. The attribution matrix must be 3D (heuristic × scenario × dimension), not 2D.
  Prevents: aggregate attribution masking dimension-specific effects.

- Ablation results must include scenario 012 to measure context dilution. If removing ANY single IRON RULE improves 012, it's evidence for payload-size-as-confounder rather than rule-content-as-confounder.
  Prevents: false attribution of context dilution to specific rule content.

## Deliverables

1. `eval/reasoning/traces/` directory with ablation results JSON files (schema-validated)
2. `eval/reasoning/trace-schema.json` — JSON schema for ablation trace data
3. `eval/reasoning/run-eval.py` — extended with `--ablation` (read traces, validate, compute deltas) and `--analyze` (attribution matrix) modes. No programmatic subagent launching — ablation runs are agent-orchestrated via Claude Code subagents.
4. `eval/reasoning/traces/attribution-matrix.json` — per-heuristic × per-scenario × per-dimension classification
5. `eval/reasoning/traces/selection-criteria.md` — derived criteria document
6. Updated `eval/reasoning/README.md` — ablation methodology and results
7. Updated `tests/test_templates.sh` — trace schema validation, new eval mode assertions

## Exit Criteria (machine-checkable)

- [ ] `test -d eval/reasoning/traces`
- [ ] `test -f eval/reasoning/trace-schema.json && python3 -c "import json; json.load(open('eval/reasoning/trace-schema.json'))"`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'ablation'`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'analyze'`
- [ ] `test -f eval/reasoning/traces/attribution-matrix.json`
- [ ] `test -f eval/reasoning/traces/selection-criteria.md`
- [ ] `grep -q 'ablation' eval/reasoning/README.md`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'` (regression check — tests hook/skill eval, not reasoning eval)
- [ ] `python3 -c "import json; m=json.load(open('eval/reasoning/traces/attribution-matrix.json')); assert len(m['classifications']) >= 45, f'Expected >=45 entries (5 rules x 3 training scenarios x 3 dims), got {len(m[\"classifications\"])}'"` (attribution matrix completeness — training set only; held-out validated separately)

## Checkpoints

- After trace schema design: review schema handles per-dimension attribution and corpus versioning
- After fresh baseline runs (15 invocations): verify scores are consistent with existing v2 baseline (within variance bounds)
- After first IRON RULE ablation (IRON-004 on scenario 015): verify removal improves score (expected from prior evidence). If not, re-examine prompt structure for instrumentation artifacts
- After full ablation (75 runs): compute attribution matrix before deriving criteria — inspect for unexpected patterns
- After selection criteria derivation: validate on held-out scenarios (012, 014) before documenting

## Assumptions

- Leave-one-out ablation provides sufficient signal for IRON RULE attribution. If false: the heuristics interact in ways that leave-one-out can't detect — document as limitation, note that pairwise testing of top suspect pairs (IRON-004+005 specifically) is the fallback.
- 5 differentiating scenarios are sufficient for criteria derivation + validation. If false: extend to all 20 scenarios with reduced run count (1 run instead of 3) as a screening pass.
- IRON RULES are the primary source of cross-domain interference. If false (HEU rules also cause interference): expand ablation to cover top 3 HEU candidates based on trigger breadth.
- The existing eval subagent methodology produces sufficiently low variance for per-heuristic signal detection. If false (variance ≥ 0.5 on first ablation condition): STOP and surface to user before expanding to 5 runs per condition (~175 total invocations).
