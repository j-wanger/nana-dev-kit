---
parent: dev-plan
referenced_at: "Step 6.5"
---

# Heuristic Trigger Matcher

Match relevant heuristics to a phase's decision context. Returns top-3 matches.

## Inputs

- **objective**: Phase objective (1-2 sentences)
- **scope**: File glob patterns for the phase
- **heuristics_dir**: Path to `wiki/heuristics/` (default: `$ROOT/wiki/heuristics/`)

## Strategy: LLM (default)

1. Read all `*.md` files in `heuristics_dir` (skip `SCHEMA.md`).
2. Extract from YAML frontmatter: `id`, `trigger`, `domain`, `status`, `confidence`.
3. Dispatch Agent subagent with this prompt:

```
You are matching heuristic triggers to a phase objective. For each heuristic,
decide if its trigger condition describes a situation present in the objective.

Phase objective: {objective}
Phase scope: {scope}

Heuristics:
{for each: "- {id}: {trigger} (domain: {domain})"}

Return JSON array of matches (max 3), ranked by relevance:
[{"id": "HEU-001", "trigger": "...", "confidence": "high|medium"}]

Return [] if no triggers match. Only include genuine matches — a heuristic
whose trigger describes a different situation is NOT a match.
```

4. Parse JSON response. Cap at 3 matches.

## Strategy: Domain-Tag (fallback)

If LLM strategy fails or `strategy: domain-tag` is set:

1. Extract `domain` tags from all heuristics.
2. Extract keywords from phase objective and scope.
3. Match heuristics whose `domain` tag appears in objective/scope keywords.
4. Rank: `status: iron` first, then by `confidence` descending.
5. Return top 3.

## Content Assembly

For each matched heuristic, extract Always + Never + Anti-pattern sections.
Measure combined character count. If >1200 chars, truncate: drop Anti-pattern
tables first, then Why, then Source — keep Always and Never.

## Skip Conditions

- `heuristics_dir` missing/empty or all articles fail YAML parsing: return `[]`.
- Subagent timeout (>30s): fall back to domain-tag strategy.
