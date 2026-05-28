# Cross-Model Judge Protocol

This judge prompt is used when the judge model differs from the agent model. The scoring rubric is identical to reasoning-judge-v2.md — only the execution protocol differs.

## Execution

1. The agent generates recommendations using one model (e.g., Opus)
2. Raw agent responses are stored in the results file under `responses`
3. A separate judge subagent using a DIFFERENT model (e.g., Sonnet) scores each response
4. Results include `agent_model` and `judge_model` metadata fields

## Results Schema Extension

Cross-model results.json adds these fields to the standard schema:

```json
{
  "agent_model": "opus",
  "judge_model": "sonnet",
  "responses": {
    "001-database-choice": {"run_1": "...", "run_2": "...", "run_3": "..."},
    ...
  },
  "runs": [...]
}
```

## Judge Instructions

Use the exact rubric from reasoning-judge-v2.md. The judge receives:
- The agent's recommendation text (from `responses`)
- The scenario's expert_answer, expert_reasoning, and anti_pattern (from corpus)
- The scoring rubric (3 dimensions, 1-5 each, with exemplar anchors)

Score strictly. The cross-model judge should NOT adjust scores based on the agent model — score the reasoning quality of the response text only.

## Calibration Gate

Before using cross-model scores for experiments, verify calibration:
- Mean score < 4.5 across all dimensions
- >= 15% of individual scores below 5
If either criterion fails, the cross-model judge is not calibrated for this corpus.
