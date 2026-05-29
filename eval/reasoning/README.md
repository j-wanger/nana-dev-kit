# Reasoning Quality Evaluation

Measures AI agent reasoning quality on software engineering decisions using LLM-as-judge scoring.

> **Status: calibration tool only (demoted Phase 65).** Per the Phase-63 eval-validity verdict
> ([[eval-validity-verdict]]), this LLM-as-judge eval is **blind-by-construction** at the n it runs: its
> composite deltas (Phase 58/59/61: 0.00 / −0.40 / −0.67) sit *inside* their own run-to-run spread, so it
> cannot distinguish a useful feature from a worthless one. It is retained for **judge-calibration research**
> (rubric/exemplar tuning, the ablation method below) and is **never used to gate features or shipping** —
> it is run only on explicit invocation, never by `make eval` or `make test`. The trusted contract gate is the
> deterministic binary corpus (`make eval`); the non-blind, observed-action substrate is Phase 65's enforcement
> firing log (its scorer lands in Phase 66). Run-on-demand for calibration only.

## Methodology

Each scenario presents a decision the agent must make, with:
- **context**: Project state and available information
- **question**: The specific decision to make
- **expert_answer**: What the expert actually decided
- **expert_reasoning**: The reasoning behind the decision
- **anti_pattern**: The common wrong approach
- **difficulty**: `medium` or `hard` (v2 scenarios only)

The agent reasons about each decision (without seeing the expert answer). A separate judge then scores the agent's response against the expert answer on 3 dimensions (1-5 each):
1. **Decision quality**: Did the agent reach the right conclusion?
2. **Reasoning quality**: Did the agent consider the right tradeoffs?
3. **Anti-pattern avoidance**: Did the agent avoid known failure modes?

## Judge Versions

- **v1** (`judges/reasoning-judge.md`): Descriptive rubric only. Used for v1 baseline. Produced 5/5 ceiling (all scenarios) due to self-grading bias + easy scenarios.
- **v2** (`judges/reasoning-judge-v2.md`): Exemplar-based anchoring with concrete response examples at score levels 3 and 5. Stricter calibration rules (naming right answer without WHY caps at 3). Breaks the ceiling: 19.4% of scores below 5.

## Running the Eval

### Subagent mode (primary — runs within Claude Code)

The eval is orchestrated by Claude Code using Agent subagents:

1. **Agent subagent** (Sonnet, clean context): Reads scenarios (context + question only), reasons about each, returns structured JSON recommendations
2. **Judge subagent** (Sonnet, clean context): Receives agent responses + expert answers, scores each on 3 dimensions, returns structured JSON scores
3. **Orchestrator** (this session): Aggregates scores, computes stats, writes results JSON

For variance checking, run 3 independent agent+judge pairs. Each pair has independent context (no cross-contamination between runs).

**Self-grading note**: Agent and judge use the same model family. This inflates absolute scores but doesn't affect relative comparisons (baseline vs treatment), since the bias is constant across conditions.

### IRON RULES injection

To measure IRON RULES impact, prepend condensed IRON RULES (Always/Never for each rule) to the agent's system prompt. The judge does NOT see the IRON RULES — it scores reasoning quality, not rule-following. Store injection method in results metadata.

### Stats utility

```bash
# Compute stats from results
python3 eval/reasoning/run-eval.py --stats eval/reasoning/baseline/results-v2.json

# Compare baseline vs treatment
python3 eval/reasoning/run-eval.py --compare eval/reasoning/baseline/results-v2.json eval/reasoning/with-iron-rules/results.json

# List scenarios
python3 eval/reasoning/run-eval.py --list
```

## Corpus

20 decision scenarios in `corpus/`:

**Original (001-010):** Clear right answers, used for v1 baseline.
- Database/storage, error handling, testing philosophy, dependency management, process/ceremony, cross-domain migration, failure detection, performance constraints, deduplication

**Harder (011-020, Phase 45):** Genuine tradeoffs, 4 medium + 6 hard.
- Migration timing, API backward compatibility, CI prioritization, library dependency pinning, rewrite vs refactor, build vs buy, schema migration, feature flag debt, consistency vs availability, tech debt triage

## Results

| Condition | Mean | % Below 5 | Key Findings |
|-----------|------|-----------|--------------|
| v1 baseline (10 scenarios) | 5.0 | 0% | Ceiling effect — all 5/5 |
| v2 baseline (20 scenarios) | 4.68 | 19.4% | Ceiling broken on 3 scenarios (012, 014, 018) |
| v2 + IRON RULES | 4.73 | ~15% | 012 improved +8, 014 improved +3, 018 regressed -6. Net +5 on differentiating scenarios |
| v2 + IRON RULES + anti-pattern tables | 4.83 | ~10% | 018 fixed (+2.67, lifecycle complexity clause). 012 regressed -0.67 (context dilution from expanded payload). Net improvement vs IRON RULES alone |
| v2 + self-dialogue inline (A) | ~4.10 | ~35% | **NET NEGATIVE.** 015 regressed -3.33 (IRON-004 overcorrection: flipped refactor→rewrite). 020 regressed -3.0 (IRON-005: CVEs over force-multiplier). No scenario improved. |
| v2 + self-dialogue subagent (B) | ~4.30 | ~20% | Net neutral. 015 prevented catastrophic flip (subagent isolation: -1.0 vs inline -3.33). 020 still wrong (-2.56, IRON RULES bias). No improvements over baseline. |

## Self-Dialogue (Phase 47)

Two conditions tested whether structured self-dialogue (devil's advocate with IRON RULE citations) improves reasoning:

**Condition A (inline):** Self-dialogue protocol injected into agent prompt alongside IRON RULES. Agent argues against its own recommendation before presenting final answer. Result: **net negative**. IRON RULES amplification via self-dialogue overrides domain-specific reasoning on nuanced scenarios (015: auth rewrite risk, 020: force-multiplier prioritization).

**Condition B (subagent):** Initial recommendation formed WITHOUT self-dialogue, then a separate devil's advocate subagent generates counterarguments. Result: **net neutral**. Subagent isolation prevented the catastrophic 015 flip (initial recommendation was correct and locked in), but added no improvements. The devil's advocate added hedging and caveats but no new insights.

**Key finding:** Self-dialogue with IRON RULES as ammunition causes overcorrection when rules' surface reading conflicts with domain-specific nuance. The mechanism: IRON-004 ("simpler system wins") pushes toward rewrite on 015, but the expert reasoning is about risk management (auth is highest-risk domain, zero buffer). IRON-005 ("make failure visible") pushes toward CVE fix on 020, but the expert insight is about force-multiplier effects (test reliability improves capacity for ALL future work).

**Implication for roadmap:** Self-dialogue as a reasoning technique does not improve quality. The next lever is not more self-critique — it's better heuristic selection (matching the right rule to the right scenario type). See Phase 48: Trace Collection.

## Anti-Pattern Tables (Phase 46)

Each IRON RULE now has a structured anti-pattern table: `| Failure Mode | Detection Signal | Why It Fails |` (3-5 rows per rule). IRON-004 also received a Never clause fix: "Confuse 'less effort now' with 'simpler system' — measure simplicity by total lifecycle complexity, not upfront cost."

The injection payload (`iron-rules-injection-v2.md`) includes condensed Always/Never + anti-pattern failure modes. Expanded payload trades marginal detail on some scenarios (012: -0.67) for fixing the critical regression on 018 (+2.67).

## IRON RULES

5 unconditional reasoning rules (`wiki/heuristics/IRON-*.md`):
1. **Measure before optimizing** — establish baseline, define "better" measurably
2. **Check existing before building** — search codebase/deps before writing new code
3. **Validate at boundaries, trust internally** — validate once at entry, trust after
4. **Simpler system wins unless proven otherwise** — burden of proof on complexity
5. **Make failure visible, not silent** — surface errors with context, never swallow

## Ablation Analysis (Phase 48)

Leave-one-out ablation on 5 IRON RULES × 3 training scenarios (015, 018, 020) with 3 runs per condition. Genuinely held-out scenarios (012, 014) received only baseline + full-set runs.

### Methodology

```bash
# View ablation deltas (LOO vs full-set)
python3 eval/reasoning/run-eval.py --ablation eval/reasoning/traces/

# Generate attribution matrix
python3 eval/reasoning/run-eval.py --analyze eval/reasoning/traces/
```

Trace data stored in `eval/reasoning/traces/` as schema-validated JSON files. Each file represents one condition (baseline, full-set, or leave-one-out-IRON-NNN).

### Results

| Heuristic | 015 (auth) | 018 (flags) | 020 (tech debt) |
|-----------|-----------|-------------|-----------------|
| IRON-001 | uncertain | irrelevant | uncertain (removal hurt) |
| IRON-002 | helped (removal improved) | irrelevant | irrelevant |
| IRON-003 | helped (removal improved) | irrelevant | irrelevant |
| IRON-004 | uncertain | irrelevant | irrelevant |
| IRON-005 | helped (removal improved) | irrelevant | irrelevant |

**Key finding: NEGATIVE RESULT for rule-level selection.** Heuristic interference on scenario 015 is stochastic (~1/3 of runs recommend rewrite regardless of which rules are present/absent). No single IRON RULE is specifically responsible. The interference is an emergent property of the rule set, not attributable to IRON-004 alone as previously hypothesized.

**IRON-001 is load-bearing for 020:** Removing "Measure Before Optimizing" caused regression on tech debt triage (agent picks CVE urgency over force-multiplier reasoning).

See `eval/reasoning/traces/selection-criteria.md` for full analysis and Phase 49 recommendations.

## Comparison Protocol

1. Run baseline (no context injection, 3 runs)
2. Add one variable (e.g., IRON RULES, heuristics, self-dialogue)
3. Run with variable (3 runs, same judge prompt)
4. Compare per-scenario scores — improvement ≥ 0.5 points is meaningful
5. Check variance < 0.5 per dimension (consistency)
6. Report per-scenario delta, flag any regression > 1.0
