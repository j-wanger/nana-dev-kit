<!-- nana:approved 2026-05-27 -->
# Spec: Conditional Heuristic Injection — Scenario-Type Classification

## Objective

Add scenario-type metadata to the 20-scenario reasoning eval corpus and implement conditional IRON RULES injection — inject all rules for non-risk-dominant scenarios, suppress all rules for risk-dominant scenarios — then validate whether conditional injection outperforms always-inject.

## Context

Phase 48 LOO ablation showed scenario 015 interference is stochastic (~1/3 of runs), not attributable to any specific IRON RULE. Per-rule selection is not viable. The accepted direction is all-or-nothing injection by scenario type (decision: [[stochastic-heuristic-interference]], [[scenario-type-selection-criteria]]). Training scenarios: 015 (risk-dominant), 018 (capacity-constraint), 020 (domain-nuance). Held-out: 012, 014. 4/5 training scenarios at ceiling (5/5/5) in both conditions — only 015 shows any differentiation signal. Self-grading bias (same model family for agent and judge) inflates absolute scores but relative comparisons remain valid.

## Scope

### In scope
- Scenario-type taxonomy definition (risk-dominant, capacity-constraint, domain-nuance) with assignment criteria
- `scenario_type` field added to all 20 scenario JSON files
- Conditional injection prompt template (`eval/reasoning/conditional-injection.md`) with scenario_type gate logic for eval subagents
- `--conditional` analysis mode in run-eval.py for comparing conditional vs always-inject vs no-inject results
- 3-condition eval (run via subagents): always-inject vs conditional vs no-inject (3 runs each) on all 20 scenarios
- Both-condition runs on held-out scenarios (012, 014) regardless of classifier output, to measure classifier correctness
- Attribution analysis: does conditional injection improve 015 without regressing others?

### Out of scope
- Runtime LLM-based scenario classifier (premature given N=1 training signal)
- New scenario authoring or corpus expansion
- Cross-model judging (separate roadmap item)
- Modifications to IRON RULES content
- Production integration into dev-plan reasoning flow

## Approach

Metadata-based classification (type field on scenario JSON), not runtime inference. The "classifier" is a lookup table defined at scenario authoring time.

**Eval execution** is done via Claude Code subagents (not run-eval.py, which is a post-hoc data utility). Conditional injection is implemented as a new prompt template (`conditional-injection.md`) that instructs the eval subagent to check the scenario's `scenario_type` field: if `risk-dominant`, skip the IRON RULES prefix; otherwise, prepend `iron-rules-injection-v2.md` as currently done.

**Analysis** uses `run-eval.py --conditional` (new mode) to load all 3 condition result files and produce a comparison table (delta + variance per scenario per dimension, same format as `--compare`).

The 3 conditions: (1) always-inject (existing `with-iron-rules/`), (2) conditional (new `with-conditional/`), (3) no-inject (existing `baseline/`). Held-out scenarios (012, 014) get BOTH inject and no-inject runs regardless of type assignment to verify classification correctness.

## Constraints (CRITICAL)

- Type taxonomy must be defined BEFORE assigning types to scenarios: write the criteria for each type (what makes a scenario "risk-dominant"?), then classify. Assigning first and deriving criteria after is post-hoc rationalization. Prevents: overfitting taxonomy to known outcomes.
- 3-run protocol required for all conditions: single-run results are insufficient given the stochastic interference (~1/3 runs). Use existing delta >= 0.5, variance < 0.5 classification thresholds. Prevents: false positive/negative from run variance.
- Run both conditions on held-out scenarios: the classifier's value is measured by whether it picks the better condition, not by whether the condition it picks scores well in isolation. Prevents: unfalsifiable type assignment.
- Non-target scenario regression check: for non-risk-dominant scenarios, the conditional injection template must produce identical prompt assembly to always-inject (both prepend iron-rules-injection-v2.md). Verify by manual inspection of the conditional-injection.md template logic — the gate should only suppress rules when `scenario_type == "risk-dominant"`, defaulting to inject otherwise. Prevents: prompt assembly bugs corrupting unrelated scenarios.
- Design for negative result: if conditional injection does not measurably improve on always-inject (delta < 0.5 on 015, or regressions elsewhere), the phase produces a documented negative result, not a forced-positive classifier. Prevents: sunk cost bias.

## Deliverables

1. `eval/reasoning/scenario-type-taxonomy.md` — type definitions + assignment criteria + classification of all 20 scenarios with rationale
2. Updated 20 scenario JSON files in `eval/reasoning/corpus/` with `scenario_type` field
3. `eval/reasoning/conditional-injection.md` — prompt template with scenario_type gate for eval subagents
4. Updated `eval/reasoning/run-eval.py` with `--conditional` analysis mode (loads 3 condition dirs, produces comparison table)
5. `eval/reasoning/with-conditional/results.json` — conditional eval results (same schema as `with-iron-rules/results.json`, with `condition: "conditional"` field)
6. `eval/reasoning/traces/conditional-analysis.md` — analysis document with attribution, held-out validation, and recommendation

## Exit Criteria (machine-checkable)

- [ ] `python3 -c "import json; from pathlib import Path; types=[json.load(open(f))['scenario_type'] for f in sorted(Path('eval/reasoning/corpus').glob('*.json'))]; valid={'risk-dominant','capacity-constraint','domain-nuance'}; assert all(t in valid for t in types), f'invalid types: {set(types)-valid}'; assert len(types)==20"`
- [ ] `test -f eval/reasoning/scenario-type-taxonomy.md`
- [ ] `test -f eval/reasoning/conditional-injection.md`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q conditional`
- [ ] `test -f eval/reasoning/with-conditional/results.json`
- [ ] `test -f eval/reasoning/traces/conditional-analysis.md`
- [ ] `make test && make eval`

## Checkpoints

- After taxonomy definition (before type assignment): review type criteria. If criteria cannot distinguish 015 from 018/020 on paper, STOP — taxonomy is insufficient.
- After type assignment to all 20 scenarios: verify at least 2 scenarios per type (if any type has 0-1 scenarios, the taxonomy is too fine-grained). If all training scenarios map to the same type, report this as a finding and abort classifier — it degenerates to always-inject or never-inject.
- After first conditional eval run: if 012 and 014 both score 5/5/5 in BOTH conditions (inject and no-inject), note held-out validation is inconclusive due to ceiling effect. Continue but flag in analysis.

## Assumptions

- Scenario-type taxonomy (risk-dominant, capacity-constraint, domain-nuance) captures the relevant dimension for injection effects. If false: taxonomy needs revision or expansion — try an alternative axis (e.g., scenario ambiguity level, or number of competing valid answers).
- Stochastic interference on 015 is model variance, not judge variance. If false: the "improvement" from suppressing rules is actually just measurement noise. Mitigation: 3-run protocol + existing variance threshold.
- The 20-scenario corpus has sufficient type diversity for meaningful evaluation. If false: results are valid but not generalizable — note as limitation, do not over-claim.
- Judge v2 is calibrated consistently across scenario types. If false: classifier may learn judge bias rather than injection effects. Mitigation: compare per-scenario judge variance across conditions.
