# Conditional Injection Analysis — Phase 49

## Result: Negative

Conditional IRON RULES injection (suppress for risk-dominant, inject for others) provides **no measurable improvement** over always-inject. The stochastic interference on scenario 015 observed in Phase 48 LOO traces did not reproduce in this fresh eval round.

## 3-Condition Comparison

| Condition | Mean D | Mean R | Mean A | Notes |
|-----------|--------|--------|--------|-------|
| Baseline (no rules) | 4.72 | 4.15 | 4.07 | 020 stochastic (1/3 wrong) |
| Always-inject | 4.82 | 4.80 | 4.72 | 018 judge error Run 1, 020 stochastic (1/3 wrong) |
| Conditional | 4.82 | 4.80 | 4.72 | Constructed: identical to always-inject |

**Conditional vs always-inject delta: 0.00 across all dimensions and all scenario types.**

This is expected given the construction: conditional = always-inject for non-risk-dominant scenarios (17/20), and the 3 risk-dominant scenarios (011, 015, 017) scored identically in baseline and always-inject.

## Per-Type Attribution (attribution by scenario type)

| Type | Scenarios | Baseline Mean | Always-Inject Mean | Delta |
|------|-----------|---------------|-------------------|-------|
| risk-dominant | 011, 015, 017 | 4.89 | 4.78 | -0.11 |
| capacity-constraint | 010, 013, 016, 018 | 4.50 | 4.58 | +0.08 |
| domain-nuance | 13 scenarios | 4.18 | 4.85 | +0.67 |

Always-inject helps domain-nuance scenarios (+0.67 mean) and is neutral on risk-dominant (-0.11, within variance). The conditional mechanism's premise — that risk-dominant scenarios are hurt by rules — is not supported in this eval round.

## Early Falsification

Passed. Baseline 015 (no rules) = 3/3 correct across all runs. The stochastic error is not inherent model variance — it only appeared with rules in Phase 48 traces.

However, always-inject 015 = 3/3 correct in this round. The stochastic interference from Phase 48 did not reproduce. This is the baseline divergence phenomenon: results differ across eval rounds even with the same prompt structure.

## Held-out Validation (012, 014)

| Scenario | Type | Baseline | Always-Inject | Better Condition |
|----------|------|----------|---------------|-----------------|
| 012 | domain-nuance | 10/15 | 15/15 | always-inject |
| 014 | domain-nuance | 13/15 | 15/15 | always-inject |

Both held-out scenarios are domain-nuance and benefit from IRON RULES injection. The classifier correctly assigns them as non-risk-dominant (→ inject). Held-out validation is consistent but trivially so — both scenarios clearly benefit from rules.

## Why the Negative Result

Three contributing factors:

1. **Stochastic interference non-reproduction**: The Phase 48 LOO traces showed 015 at ~3.67/4.0/3.67 with all rules. This round's always-inject shows 015 at 5/5/5 across all 3 runs. The interference was a single-round artifact, not a stable signal.

2. **Baseline divergence**: Cross-round comparisons remain invalid. The Phase 48 finding (stochastic interference) was real for that round but does not transfer to new rounds. This is a fundamental limitation of the eval methodology.

3. **N=1 differentiating scenario**: Even if the interference had reproduced, conditional injection only helps on the one scenario (015) where it suppresses rules. With 16/20 scenarios at ceiling, the mechanism has near-zero statistical power.

## Length-Sensitivity Alternative Interpretation

The Phase 46 finding (context dilution: 012 dropped from 5/5/5 to 5/4/4 when anti-pattern tables expanded the injection payload) suggests prompt length may be the relevant variable, not scenario type. If interference correlates with prompt token count rather than scenario properties, the right solution is shorter injection text, not type-based gating.

Evidence for this interpretation:
- IRON RULES injection adds ~400 tokens of preamble
- The interference (when it appeared in Phase 48) was scenario-specific but not rule-specific (LOO ablation showed no single rule was responsible)
- Context dilution effects are inherently stochastic (model attention varies across runs)

This interpretation cannot be tested with the current eval design (which varies injection content, not length). A length-sensitivity experiment would require injecting placeholder text of equivalent length.

## Recommendation

The recommendation is clear: **do not adopt conditional injection.** The mechanism adds complexity (taxonomy, classifier, conditional template) without measurable benefit. The stochastic interference that motivated it is not a stable phenomenon.

**Next levers for reasoning eval improvement:**
1. Cross-model judging (break self-grading bias, improve calibration)
2. Harder scenarios (more scenarios with genuine ambiguity, reduce ceiling effect)
3. Length-sensitivity analysis (test whether injection length correlates with interference)
