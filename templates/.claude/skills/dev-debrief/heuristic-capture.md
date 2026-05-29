---
parent: dev-debrief
referenced_at: Step 7
---

# Heuristic Capture (Step 7)

Extract transferable reasoning patterns from phase decisions and propose as new heuristic articles. Runs after memory harvest (Step 6), before decision extraction (Step 8).

## Input

Phase decisions from Step 4 conversation analysis — specifically entries tagged as approach choices, tradeoff resolutions, or constraint discoveries.

## Extraction Flow

1. **Scan decisions.** For each decision in the conversation analysis output, extract:
   - The trigger situation (what prompted the decision)
   - The reasoning pattern (how the decision was reached)
   - The anti-pattern (what the wrong approach was and why it seemed right)

2. **Transferability gate.** Apply the 3 quality criteria from `wiki/heuristics/SCHEMA.md`:
   - Trigger specificity (>=3/5): Would an agent recognize this trigger?
   - Transferability (>=3/5): Would this help on a web app, data pipeline, or CLI tool?
   - Actionability (>=3/5): Does the Always/Never give immediate guidance?

   If the pattern fails 2+ criteria, skip it. Log: `"Heuristic candidate '<trigger>' failed transferability (specificity=N, transferability=N, actionability=N)."`

3. **Dedup against existing heuristics.** Search `wiki/heuristics/` for existing articles with overlapping triggers:
   - Extract trigger keywords from the candidate and each existing heuristic's `trigger:` field
   - If 3+ shared trigger keywords with an existing heuristic: merge the insight into that heuristic's anti-pattern table or Why section instead of creating a new article
   - Log: `"Merging into existing [[HEU-NNN]]: <reason>"`

4. **Propose draft.** For each passing candidate, draft the heuristic article using the SCHEMA.md format (all 6 required sections). Present to the user:

   ```
   Proposed heuristic:
   Trigger: <trigger>
   Always: <key bullet>
   Anti-pattern: <name>
   Transferability: specificity=N, transferability=N, actionability=N

   Write to wiki/heuristics/HEU-NNN-<slug>.md? (y/n)
   ```

   **Do NOT auto-commit.** The user must confirm before any write to `wiki/heuristics/`.

5. **Assign ID.** On confirmation, find the highest existing HEU-NNN ID and increment. Write the article with `status: active`, `confidence: medium`, `helpful: 0`, `harmful: 0`.

## Skip Conditions

- **Quick debrief mode:** Skip entirely (insufficient conversation depth for pattern extraction).
- **Zero decisions in phase:** Skip. Log: `"Heuristic capture: no decisions to analyze."`
- **USER OVERRIDE decisions:** Skip override-tagged decisions — overrides are exceptions, not patterns to generalize. Log: `"Skipping USER OVERRIDE decision: <title>"`
- **No wiki/heuristics/ directory:** Skip. Log: `"Heuristic capture: no heuristic store found (wiki/heuristics/ missing)."`

## Budget

- Propose at most 2 heuristics per debrief session (avoid flooding the store with low-quality entries)
- Prefer 0 high-quality heuristics over 2 marginal ones
- If 3+ candidates pass the gate, propose only the 2 with highest combined transferability scores
