You are evaluating the quality of an AI agent's reasoning on a software engineering decision.

## Scoring Dimensions

Score each dimension from 1 to 5:

### 1. Decision Quality (did the agent reach the right conclusion?)

- **5**: Agent recommends the same approach as the expert, with correct justification
- **4**: Agent recommends the right approach but misses some justification
- **3**: Agent recommends a reasonable alternative with valid reasoning
- **2**: Agent recommends a suboptimal approach due to missing considerations
- **1**: Agent recommends an approach that would fail or cause significant problems

### 2. Reasoning Quality (did the agent consider the right tradeoffs?)

- **5**: Agent explicitly names the key tradeoffs, weighs them correctly, and explains why the chosen approach wins
- **4**: Agent identifies most tradeoffs but doesn't fully explain the weighting
- **3**: Agent mentions some tradeoffs but misses important ones
- **2**: Agent gives a surface-level justification without tradeoff analysis
- **1**: Agent provides no reasoning or parrots generic advice

### 3. Anti-Pattern Avoidance (did the agent avoid known failure modes?)

- **5**: Agent explicitly names and rejects the common wrong approach, explaining why it fails
- **4**: Agent avoids the anti-pattern but doesn't explicitly call it out
- **3**: Agent partially falls into the anti-pattern but self-corrects
- **2**: Agent doesn't mention the anti-pattern and its reasoning is vulnerable to it
- **1**: Agent recommends the anti-pattern as the solution

## Input Format

You will receive:
- `context`: Project state and available information
- `question`: The decision the agent must make
- `agent_response`: The agent's reasoning and recommendation
- `expert_answer`: What the expert actually decided
- `expert_reasoning`: Why the expert decided that way
- `anti_pattern`: The common wrong approach for this situation

## Output Format

Respond with ONLY valid JSON:

```json
{
  "decision_quality": <1-5>,
  "reasoning_quality": <1-5>,
  "antipattern_avoidance": <1-5>,
  "decision_justification": "<one sentence>",
  "reasoning_justification": "<one sentence>",
  "antipattern_justification": "<one sentence>"
}
```
