You are evaluating the quality of an AI agent's reasoning on a software engineering decision. Score strictly — a 5 requires exceptional depth, not merely correct direction.

## Scoring Dimensions

Score each dimension from 1 to 5. Use the exemplar anchors below to calibrate.

### 1. Decision Quality (did the agent reach the right conclusion?)

- **5**: Agent recommends the same approach as the expert, with correct justification AND names what specifically makes alternatives worse. Example of a 5: "Use SQLite because the deployment complexity budget is near-zero for dev tools — PostgreSQL adds a server dependency that violates this constraint even though it offers better concurrency, which is irrelevant for single-user access."
- **4**: Agent recommends the right approach with correct but incomplete justification
- **3**: Agent recommends a reasonable alternative with valid reasoning, or the right approach with weak justification. Example of a 3: "SQLite seems like a good fit because it's simpler" — correct direction but no analysis of WHY the constraint structure makes it correct.
- **2**: Agent recommends a suboptimal approach due to missing considerations
- **1**: Agent recommends an approach that would fail or cause significant problems

### 2. Reasoning Quality (did the agent consider the right tradeoffs?)

- **5**: Agent explicitly names the key tradeoffs, weighs them against the specific constraints in the scenario, and explains why the chosen approach wins GIVEN THOSE CONSTRAINTS. Must name at least 2 specific tradeoffs and explain the weighting. Example of a 5: "The tradeoff is deployment friction vs. query capability. For a single-user CLI with hundreds of records, deployment friction dominates because users won't tolerate a database server install, while SQLite's FTS5 covers the search requirement."
- **4**: Agent identifies most tradeoffs but does not fully explain why one side wins
- **3**: Agent mentions some tradeoffs but misses the decisive one, or lists tradeoffs without weighing them. Example of a 3: "There are tradeoffs between simplicity and scalability" — names the dimension but does not explain which matters more in this context or why.
- **2**: Agent gives a surface-level justification without tradeoff analysis
- **1**: Agent provides no reasoning or parrots generic advice

### 3. Anti-Pattern Avoidance (did the agent avoid known failure modes?)

- **5**: Agent explicitly names the common wrong approach, explains the mechanism by which it fails, and connects it to the specific scenario constraints. Example of a 5: "The temptation is to choose PostgreSQL for 'production-grade' robustness, but this solves a problem that doesn't exist here — there are no concurrent writes, no multi-host access, and the dataset fits in a single file."
- **4**: Agent avoids the anti-pattern and shows awareness of why it's wrong, but does not explicitly name it
- **3**: Agent partially falls into the anti-pattern but self-corrects, or avoids it without demonstrating understanding of why. Example of a 3: "I considered PostgreSQL but went with SQLite" — avoided it but did not explain the failure mechanism.
- **2**: Agent does not mention the anti-pattern and its reasoning is vulnerable to it
- **1**: Agent recommends the anti-pattern as the solution

## Scoring Calibration Rules

- A response that merely names the right answer without explaining WHY it is right in this context cannot score above 3 on any dimension.
- A response that lists generic pros/cons without connecting them to the scenario's specific constraints cannot score above 3 on reasoning quality.
- Only award 5 when the response demonstrates analysis you would expect from a senior engineer who has made this exact mistake before.

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
