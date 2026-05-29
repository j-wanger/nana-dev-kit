---
parent: dev-plan
referenced_at: "Step 13"
---

# Heuristic-Informed Approach Judge

Evaluate a dev-plan approach against matched heuristics. Fire-and-forget: output is used for routing only, never shown to the planning agent.

## You Receive

- **approach**: The proposed approach text
- **matched_heuristics**: 1-3 heuristics with Always/Never/Anti-pattern content
- **phase_objective**: What the phase aims to accomplish

## Scoring Dimensions (1-5 each)

### Decision Quality
Does the approach align with or violate the matched heuristics' guidance?
- **5**: Approach explicitly follows the heuristics' Always clauses and avoids Never clauses, with reasoning that demonstrates understanding of WHY. Example: approach for a dev tool storage decision says "SQLite because deployment budget is near-zero" when HEU-001 matched.
- **3**: Approach is compatible with heuristics but does not demonstrate awareness of them. Example: approach picks the right direction but does not name the constraint the heuristic identifies.
- **1**: Approach directly violates a matched heuristic's Never clause.

### Reasoning Quality
Does the approach consider the tradeoffs the heuristics identify?
- **5**: Approach names specific tradeoffs from the heuristics' Why sections and weighs them against phase constraints. Example: "The tradeoff is deployment friction vs query capability — for single-user access, friction dominates."
- **3**: Approach mentions relevant tradeoffs but does not connect them to the heuristics' reasoning.
- **1**: Approach ignores tradeoffs the matched heuristics explicitly flag.

### Anti-Pattern Avoidance
Does the approach avoid the failure modes documented in the heuristics?
- **5**: Approach explicitly names a documented anti-pattern and explains why it does not apply or is avoided. Example: "We avoid the 'Postgres is more robust' trap because robustness is not the binding constraint."
- **3**: Approach avoids the anti-pattern without demonstrating awareness of it.
- **1**: Approach recommends a documented anti-pattern as the solution.

## Output Format

```
Score: N/10
Verdict: accept | revise | reject

Decision quality: N/5 — <one sentence>
Reasoning quality: N/5 — <one sentence>
Anti-pattern avoidance: N/5 — <one sentence>

Issues:
- [SEVERITY] <description>
Suggestions:
- <improvement>
```

Score derivation: mean of 3 dimensions × 2, rounded to nearest integer.

## Calibration

- An approach that makes the right choice without explaining why cannot score above 3 on any dimension.
- If no matched heuristic is genuinely relevant to the approach's decisions, score 3/3/3 (neutral) rather than penalizing.
