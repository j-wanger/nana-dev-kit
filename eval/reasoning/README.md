# Reasoning Quality Evaluation

Measures AI agent reasoning quality on software engineering decisions using LLM-as-judge scoring.

## Methodology

Each scenario presents a decision the agent must make, with:
- **context**: Project state and available information
- **question**: The specific decision to make
- **expert_answer**: What the expert actually decided
- **expert_reasoning**: The reasoning behind the decision
- **anti_pattern**: The common wrong approach

The agent reasons about each decision (without seeing the expert answer). A separate judge then scores the agent's response against the expert answer on 3 dimensions (1-5 each):
1. **Decision quality**: Did the agent reach the right conclusion?
2. **Reasoning quality**: Did the agent consider the right tradeoffs?
3. **Anti-pattern avoidance**: Did the agent avoid known failure modes?

## Running the Eval

### Subagent mode (primary — runs within Claude Code)

The eval is orchestrated by Claude Code using Agent subagents:

1. **Agent subagent** (Sonnet, clean context): Reads scenarios (context + question only), reasons about each, returns structured JSON recommendations
2. **Judge subagent** (Sonnet, clean context): Receives agent responses + expert answers, scores each on 3 dimensions, returns structured JSON scores
3. **Orchestrator** (this session): Aggregates scores, computes stats, writes results JSON

For variance checking, run 3 independent agent+judge pairs. Each pair has independent context (no cross-contamination between runs).

**Self-grading note**: Agent and judge use the same model family. This inflates absolute scores but doesn't affect relative comparisons (baseline vs treatment), since the bias is constant across conditions.

### Stats utility

```bash
# Compute stats from results
python3 eval/reasoning/run-eval.py --stats eval/reasoning/baseline/results.json

# Compare baseline vs treatment
python3 eval/reasoning/run-eval.py --compare eval/reasoning/baseline/results.json eval/reasoning/with-heuristics/results.json

# List scenarios
python3 eval/reasoning/run-eval.py --list
```

## Corpus

10 decision scenarios in `corpus/`, covering:
- Database/storage selection
- Error handling strategies
- Testing philosophy
- Dependency management
- Process/ceremony design
- Cross-domain migration
- Failure detection/recovery
- Performance constraints
- Deduplication at scale

## Comparison Protocol

1. Run baseline (no heuristics, 3 runs)
2. Add one variable (e.g., IRON RULES, heuristics, self-dialogue)
3. Run with variable (3 runs)
4. Compare averages — improvement ≥ 0.5 points is meaningful
5. Check variance < 0.5 per dimension (consistency)
