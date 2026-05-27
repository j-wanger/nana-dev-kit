---
domain: cognitive-patterns-for-ai-development
description: Cognitive patterns for AI-assisted development
---

# Wiki Schema: cognitive-patterns

## Domain Context

This wiki captures cognitive patterns that improve AI-assisted development outcomes. The primary audience is AI agents consuming these patterns for reasoning during sessions, with developer oversight for curation and correction. Articles emphasize practical examples and trade-offs over abstract descriptions, ensuring patterns are immediately actionable rather than theoretical.

## Custom Tags

- `heuristic` -- A reusable reasoning shortcut with defined trigger conditions
- `reasoning-pattern` -- A structured approach to a class of problems
- `anti-pattern` -- A common failure mode with concrete symptoms and fixes
- `decision-framework` -- A repeatable process for choosing between alternatives
- `cognitive-bias` -- A systematic reasoning error that affects AI or human judgment
- `transferable` -- Pattern applies across domains, not limited to one tech stack

## Hierarchy Roots

- `heuristics` -- Trigger-based reasoning shortcuts (follow SCHEMA.md format in wiki/heuristics/)
- `reasoning-patterns` -- Structured approaches to recurring problem classes
- `anti-patterns` -- Documented failure modes with symptoms, causes, and remedies
- `decision-frameworks` -- Repeatable processes for evaluating trade-offs and choosing actions

## Conventions

1. Heuristic articles MUST follow the structured format defined in `wiki/heuristics/SCHEMA.md` (trigger / always / never / anti-pattern sections).
2. ALL articles MUST include at least one concrete example (code snippet, scenario, or before/after comparison). Articles with only abstract descriptions are rejected.
3. Heuristic articles MUST include the `heuristic` tag in their frontmatter tags array.

## Staleness Rules

- Default staleness threshold: 365 days
- Articles with `transferable` tag: 730 days (stable cross-domain patterns decay slower)

## Proposed Changes

<!-- Record schema change proposals here before applying them. -->
