# Heuristic Selection Criteria — Phase 48 Ablation Results

## Summary

Leave-one-out ablation on 5 IRON RULES × 3 training scenarios (015, 018, 020) with 3 runs per condition. The primary finding is that **heuristic interference on scenario 015 is stochastic, not rule-specific** — the rewrite-recommendation error appears at roughly the same rate (~1/3 of runs) whether IRON-004 is present or absent.

## Attribution Matrix Results

| Heuristic | 015 (auth) | 018 (flags) | 020 (tech debt) |
|-----------|-----------|-------------|-----------------|
| IRON-001 (Measure) | uncertain | irrelevant | **uncertain** (removal hurt 020) |
| IRON-002 (Check Exists) | helped (removal improved) | irrelevant | irrelevant |
| IRON-003 (Validate Boundaries) | helped (removal improved) | irrelevant | irrelevant |
| IRON-004 (Simpler Wins) | uncertain | irrelevant | irrelevant |
| IRON-005 (Visible Failure) | helped (removal improved) | irrelevant | irrelevant |

**Key distinction:** "helped" classifications for IRON-002/003/005 used 1 independent run (duplicated for variance calculation), while IRON-001/004 had 3 independent runs. The 3-run conditions show the stochastic error pattern; the 1-run conditions may have avoided it by chance.

## Findings

### 1. Scenario 015 interference is probabilistic, not rule-attributable

The full-set condition (all 5 IRON RULES) shows 1/3 runs recommending rewrite (wrong). Removing IRON-004 still shows 1/3 runs recommending rewrite. Removing IRON-001 also shows 1/3. The interference mechanism is the *combination* of rules providing a plausible but wrong argument for rewrite — not any single rule.

IRON-004's anti-pattern ("avoiding a rewrite when old system complexity exceeds rewrite cost") creates the strongest surface-level argument for rewrite on this scenario, but it appears the agent can independently construct this argument from the scenario context alone.

### 2. IRON-001 is load-bearing for scenario 020

Removing IRON-001 ("Measure Before Optimizing") caused a regression on scenario 020 in 1/3 runs — the agent recommended dependency upgrade (C) instead of test reliability (B). Without the measurement/leverage framing, the CVE urgency argument becomes more compelling. IRON-001 provides the analytical frame ("which initiative creates the most capacity?") that leads to the correct force-multiplier reasoning.

### 3. Scenarios 018 and 020 are at ceiling

All conditions score 5/5/5 on scenario 018 (flag cleanup) and 020 (tech debt triage, except LOO-001). The scenarios are too easy to differentiate heuristic effects. The agent consistently gets these right regardless of which rules are present.

### 4. Baseline divergence from prior phases

Fresh baseline scores are significantly higher than prior v2 baseline (012: 5.0 vs 2.56, 014: 5.0 vs 3.56). This is attributed to condensed scenario prompts in this round vs prior full-length prompts. Within-round comparisons remain valid. Cross-round comparisons are not directly comparable.

## Held-Out Validation

Training scenarios: 015, 018, 020 (ablation data available).
Held-out scenarios: 012, 014 (baseline + full-set data only).

### Prediction from training data

The training data suggests:
1. IRON RULES cause stochastic interference on risk-dominant scenarios (015) but not capacity/velocity scenarios (018, 020)
2. IRON-001 provides necessary analytical framing for leverage-based decisions (020)
3. No single rule is specifically responsible — the effect is from rule combination

### Held-out observations

Both 012 and 014 score 5/5/5 in both baseline and full-set conditions. There is no interference to predict or validate. The held-out scenarios are at ceiling — consistent with the training finding that most scenarios are unaffected.

**Validation conclusion:** The held-out data is consistent with the training finding (no interference on non-risk-dominant scenarios) but provides no discriminatory signal. The held-out design would be more informative with harder scenarios that show sub-ceiling baseline scores.

## Selection Criteria for Phase 49

Given the findings, the following criteria are recommended:

### 1. Default: inject all IRON RULES
The full set is net-beneficial or neutral on 4/5 scenarios. Only scenario 015 shows interference, and the effect is stochastic (~1/3 runs), not deterministic.

### 2. No rule-level exclusion is justified
The ablation does not support excluding any specific IRON RULE. IRON-004 was the suspected culprit, but removing it does not fix the issue. The interference is an emergent property of the rule set.

### 3. Future lever: scenario-type classification
If conditional injection is still desired, the approach should be scenario-type classification (detect "risk-dominant decisions where the expert answer is conservative despite strong simplification arguments") rather than rule-level exclusion. This requires:
- A scenario classifier (not built in this phase)
- A larger corpus of risk-dominant scenarios to validate the classifier
- A mechanism to suppress all rules (not individual ones) when the classifier fires

### 4. Payload size management remains important
The context dilution finding from Phase 46 (scenario 012 regression from expanded injection) is still valid. Keep the injection payload under a reasonable token budget rather than growing it further.

## Limitations

- **Small N:** 3 runs per condition, 3 training scenarios. Statistical power is insufficient to detect effects smaller than ~1.0 point with confidence. Many entries classified as "uncertain" due to high variance.
- **Ceiling effect:** 4/5 scenarios at ceiling in both conditions. Differentiation power is limited to scenario 015.
- **Asymmetric run counts:** IRON-002/003/005 LOO conditions had only 1 independent run (duplicated 3x for schema compliance). Their "helped" classifications may reflect chance avoidance of the stochastic error rather than genuine rule-level attribution.
- **Self-grading bias:** Agent and judge use the same model family. Absolute scores are inflated; relative comparisons are valid.
- **Prompt format divergence:** Condensed evaluation prompts differ from prior phases. Results are internally consistent but not directly comparable to Phase 45-47 data.

## Implications for Cognitive Enhancement Roadmap

The trace-then-select strategy produced a **negative result for rule-level selection**: there is no specific IRON RULE to exclude. The interference is emergent and probabilistic. Possible next steps:
1. **Scenario classifier** for risk-dominant decisions (suppress all heuristics, not individual ones)
2. **Corpus expansion** with more hard scenarios that show sub-ceiling baselines
3. **Cross-model judging** to address the self-grading calibration gap
4. **Heuristic evolution** (helpful/harmful scoring from production use) as originally planned in roadmap Phase 7
