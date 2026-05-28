# Phase 51 Analysis: Selective Injection Matching Coverage

## Summary

Built heuristic-informed runtime judging infrastructure: trigger-based matcher, plan-adapted judge prompt, SKILL.md Step 6.5 integration, and `--selective` eval mode. Ground-truth mapping covers 25 scenarios × 15 heuristics.

## Matching Accuracy Assessment

Manual ground-truth mapping of 25 eval scenarios to 15 heuristics (10 HEU + 5 IRON):
- **21/25 scenarios (84%)** have at least 1 relevant heuristic
- **4 scenarios (16%)** have no matching heuristic: monorepo migration (011), CAP theorem (019), capacity-multiplier (020), team topology (023)
- Average: 1.3 matches per scenario (range: 0-3)

All 15 heuristics are used at least once. IRON RULES are more broadly applicable (IRON-004 matches 6 scenarios) while HEU heuristics are more specialized (most match 1-2 scenarios). This aligns with the IRON RULES design intent — universal rules vs domain-specific heuristics.

## Coverage Distribution

| Match Count | Scenarios | Percentage |
|-------------|-----------|------------|
| 0 matches   | 4         | 16%        |
| 1 match     | 10        | 40%        |
| 2 matches   | 10        | 40%        |
| 3 matches   | 1         | 4%         |

The distribution is healthy — no scenarios match all heuristics (the "all-15-match" edge case does not occur), and most scenarios match 1-2 heuristics, staying well under the 3-match cap and 1200-character budget.

## Selective vs Blanket Comparison

| Metric | Blanket (all IRON RULES) | Selective (trigger-matched) |
|--------|--------------------------|----------------------------|
| Avg heuristics/scenario | 5.0 | 1.3 |
| Injection content | IRON RULES only | Mixed HEU + IRON |
| Coverage | 100% (every scenario gets 5 rules) | 84% (4 scenarios get nothing) |
| Context budget | ~2500 chars (all 5 rules) | ~500 chars avg (well under 1200 cap) |

Key differences:
1. **Context reduction**: Selective injection uses ~74% less context per scenario than blanket injection
2. **HEU access**: 10 scenarios get HEU-specific heuristics that blanket injection completely misses (blanket only injects IRON RULES, never HEUs)
3. **No-injection scenarios**: 4 scenarios correctly get 0 heuristics (no relevant trigger matches) — blanket would inject 5 irrelevant IRON RULES into these

## Checkpoint Outcomes

### Checkpoint 1: Matcher Falsification (Task 2)
Not applicable — ground-truth is manually created, no LLM matcher tested yet. LLM matcher testing deferred to runtime (first real dev-plan invocation with wiki/heuristics/ present). The ground truth validates that selective injection is non-degenerate (84% coverage, not 0% or 100%).

### Checkpoint 2: Selective vs Blanket Delta
No inference-based eval was run this phase (would require ~150 subagent invocations). The comparison above is structural — what would be injected, not what scores would result. Key structural finding: selective injection gives HEU access (10 scenarios get domain-specific heuristics that blanket misses). Whether this improves scores requires a future eval run.

### Checkpoint 3: Step 6.5 Integration Dry-Run
Integration added to SKILL.md Step 6.5 as item 6 (after existing approach reviewer, item 5). Fail-open design: skip silently if wiki missing, no matches, or timeout. SKILL.md at 316/350 lines. The integration will fire on the first dev-plan invocation where wiki/heuristics/ exists.

## Known Limitation: Harmful Match Detection

Scenario 018 (feature-flag-debt) matches IRON-004 by trigger ("choosing between approaches where one is simpler"), but IRON-004 is known to MISLEAD on this scenario (Phase 45: pushes toward incremental cleanup when expert recommends dedicated sprint). Trigger matching alone cannot detect harmful matches — this requires the helpful/harmful counter system (Phase 7: heuristic evolution).

## Infrastructure Value

Even without inference eval results, this phase delivers:
1. **Ground-truth dataset**: 25-scenario × 15-heuristic relevance mapping, reusable for future eval experiments
2. **Matcher protocol**: Trigger-based matching with LLM primary + domain-tag fallback
3. **Judge prompt**: Plan-adapted from judge v2 with approach-prose exemplars
4. **Integration point**: Step 6.5 item 6, additive to existing approach reviewer
5. **Eval mode**: `--selective` provides coverage analysis for any ground-truth mapping
