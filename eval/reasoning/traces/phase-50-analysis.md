# Phase 50 Analysis — Eval Advancement

## Experiment 1: Length-Sensitivity

### Result: NEGATIVE — Content matters, not length

Pre-committed threshold: filler delta within 0.3 of IRON RULES delta on >50% of affected scenarios. Result: 0/3 affected dimensions matched (0%). Threshold NOT MET.

### Key Finding

IRON RULES injection (549 words) causes consistent interference on scenario 015 (rewrite-vs-refactor-auth): 3/3 runs flip the recommendation from "incremental refactor" (correct) to "full rewrite" (wrong). IRON-004 ("simpler system wins") overrides domain reasoning — the agent treats a rewrite as the "simpler lifecycle" choice despite the 8-week deadline and 40% test coverage making it higher-risk.

Length-matched filler text (579 words of cooking principles): 0/3 runs show any interference on scenario 015. All 3 filler runs produce the correct "incremental refactor" recommendation.

| Condition | 015 Correct | 020 Correct | Other 18 |
|-----------|------------|------------|----------|
| Baseline (3 runs) | 3/3 | 0/3 | 18/18 |
| IRON RULES (3 runs) | **0/3** | 0/3 | 18/18 |
| Filler (3 runs) | 3/3 | 0/3 | 17/18* |

*Filler run 3 got scenario 011 wrong (stochastic variance, 1/9 runs).

### Methodological Findings

1. **Two-phase eval is essential.** Single-call eval (agent sees expert answer while generating recommendations) produces 20/20 at 5/5/5 — total ceiling. Two-phase eval (agent blind to expert answers, separate judge) produces meaningful differentiation. All prior phases used self-grading that may have had this contamination.

2. **Filler text is actively discarded.** All 3 filler agents explicitly noted the cooking text was irrelevant and disregarded it. The model exercises content-relevance judgment before applying injected text. This means the length-sensitivity experiment doesn't cleanly isolate the length variable — it tests "length of irrelevant text" vs "length of relevant text." A true length control would need domain-relevant but non-interfering text.

3. **Scenario 020 is consistently wrong across all conditions.** The model recommends dependency upgrade (C) instead of test reliability (B) in 8/9 runs. This is a genuine difficulty effect — the "meta-decision" reasoning (B creates capacity for A and C) is not reliably produced.

### Implication

The IRON RULES interference mechanism is: **IRON-004 provides a reasoning shortcut that overrides careful domain analysis on specific scenario types.** When a scenario has genuine ambiguity between "simpler upfront" and "safer incremental," IRON-004 biases toward the rewrite/simplification path. This is content-specific, not an attention/length effect.

## Experiment 2: Cross-Model Judging

### Result: POSITIVE — Haiku judge passes calibration, breaks self-grading ceiling

| Metric | Self-Judge (Sonnet) | Cross-Judge (Haiku) | Target |
|--------|-------------------|-------------------|--------|
| Mean score | 4.72 | 4.07 | < 4.5 |
| % below 5 | 10.0% | 37.8% | >= 15% |
| Calibration | **FAIL** | **PASS** | — |

### Per-Dimension Comparison

| Dimension | Self-Judge Mean | Cross-Judge Mean | Delta |
|-----------|----------------|-----------------|-------|
| Decision | 4.70 | 4.82 | +0.12 |
| Reasoning | 4.80 | 4.10 | **-0.70** |
| Antipattern | 4.65 | 3.30 | **-1.35** |

The cross-model judge differentiates primarily on **antipattern avoidance** (delta -1.35) and **reasoning quality** (delta -0.70). Haiku is stricter about whether the agent *explicitly names* the wrong approach and *weighs tradeoffs against specific constraints*, rather than just reaching the correct conclusion.

### Concern: Inter-Run Variance

| Run | Haiku Mean | % Below 5 |
|-----|-----------|-----------|
| 1 | 4.85 | 6.7% |
| 2 | 2.97 | 68.3% |
| 3 | 4.40 | 38.3% |

Run 2 was dramatically stricter than runs 1 and 3. This high variance (Haiku mean ranges from 2.97 to 4.85) is a concern for reliability. Contributing factor: run 2's agent recommendations were abbreviated (1-2 sentences vs 3-5 in other runs), so Haiku penalized the lack of explicit reasoning — this is partly a recommendation-length effect in the judging phase.

### Implication

Cross-model judging with Haiku produces better calibration than Sonnet self-grading, but the inter-run variance needs attention. The Haiku judge is sensitive to recommendation length/detail, which introduces a confound if agent response quality varies across conditions.

## Experiment 3: Harder Scenarios

### Corpus Expansion

5 new scenarios added (021-025), all difficulty: hard, with genuine multi-stakeholder ambiguity:

| ID | Scenario | Type | Key Ambiguity |
|----|----------|------|---------------|
| 021 | Microservice extraction timing | risk-dominant | Sequential dependency between two infrastructure changes |
| 022 | Incident response vs prevention | capacity-constraint | Correlated vs independent incident analysis |
| 023 | Team topology bottleneck | domain-nuance | Root cause (shared DB) vs symptoms (team size) |
| 024 | Vendor lock-in vs velocity | capacity-constraint | Marginal lock-in at 85% commitment vs hard deadline |
| 025 | Test coverage mandate | domain-nuance | Metric (80% overall) vs goal (audit compliance on critical paths) |

### Judge Variance Check

All 5 scenarios pass with zero variance across 3 runs (fixed mediocre response scored identically each time). Scores range from 1/1/1 (recommends anti-pattern) to 3/2/3 (accidentally correct, weak reasoning), confirming the scenarios are "agent-hard" not "judge-hard."

### Eval Results

All 5 new scenarios produce correct answers in 15/15 baseline runs (3 runs × 5 scenarios). With self-grading, all score 5/5/5 — the ceiling does NOT decrease with harder scenarios alone.

| Metric | Original 20 | Full 25 |
|--------|-------------|---------|
| % at ceiling (self-judge) | 95.0% | 96.0% |
| Below-ceiling scenarios | 020 only | 020 only |

**Finding: "harder" scenarios don't reduce ceiling if the model gets them right.** The ceiling is driven by correct-answer frequency, not scenario difficulty. Ceiling reduction requires EITHER consistently wrong answers (like 020) OR a stricter judge (like Haiku cross-model). The new scenarios' value will be visible only under cross-model judging, where reasoning depth and anti-pattern explicitness are scored more strictly.

## Cross-Experiment Insights

1. **Content-specific interference is the mechanism.** IRON-004 causes scenario 015 to flip consistently (3/3), while length-matched irrelevant text causes zero interference. The next lever is not shorter injection but better-scoped rules (IRON-004's "Never" clause may need scenario-type awareness).

2. **Cross-model judging breaks the ceiling.** Haiku as judge produces 37.8% below-5 scores vs 10% for Sonnet self-grading. The calibration improvement is real but inter-run variance needs further investigation.

3. **Two-phase eval is a prerequisite.** Single-call eval produces 100% ceiling regardless of condition. All future eval runs should use the two-phase protocol (agent blind to expert answers).

4. **Scenario 020 reveals a genuine reasoning gap.** The "meta-decision" pattern (choosing the initiative that creates capacity for other initiatives) is not reliably produced by the model. This suggests a category of harder scenarios that could expand the below-ceiling percentage.

## Recommendations for Next Phase

1. **Adopt two-phase eval as standard protocol.** Update eval infrastructure to enforce agent/judge separation.
2. **Use Haiku cross-model judge for calibration checks** but address inter-run variance (possibly by averaging across 5+ judge runs instead of 3).
3. **Investigate IRON-004 scoping.** The "simpler system wins" heuristic needs a qualifier for deadline-constrained scenarios where incremental is safer despite being "more complex."
4. **Expand "meta-decision" scenarios.** Scenario 020's consistent failure across conditions suggests this is a genuine difficulty type that could produce more below-ceiling scores.
