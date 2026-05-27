---
id: HEU-006
trigger: "designing a review or validation process for artifacts that feed downstream systems"
domain: testing
source_phase: 8
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Two-Tier Review — Structural Then Semantic

## When this applies
Designing a review or validation process for artifacts (specs, configs,
documents, schemas) that will be consumed by downstream processes or users.

## Always
- Tier 0 (structural): Run deterministic checks first — schema validation, required fields present, format correct, links resolve. These are cheap and fast.
- Tier 1 (semantic): Run judgment-based review second — ambiguity detection, completeness assessment, constraint quality. These require more context.
- Run Tier 0 before Tier 1 — don't waste expensive review on structurally invalid artifacts
- Make Tier 0 fully automated and repeatable

## Never
- Skip structural checks because "the reviewer will catch format issues"
- Rely only on structural checks ("all fields present" doesn't mean "all fields useful")
- Combine both tiers into one review step (reviewers waste time on format issues)

## Why
Structural and semantic reviews catch fundamentally different classes of
defects. Structural: missing fields, broken links, wrong format. Semantic:
vague language, incomplete constraints, untestable exit criteria. Neither
subsumes the other. Running them in order (cheap first) saves the expensive
step from wasting cycles on format errors.

## Anti-pattern
"One thorough review covers everything" → Reviewers who check both structure
and semantics simultaneously are slower and less reliable. They either focus
on format (missing semantic issues) or focus on meaning (missing format
issues). Separating tiers improves both.

## Source
Phase 8: /spec skill introduced two-tier review gate — Tier 0 structural
lint (inline, deterministic) + Tier 1 semantic subagent (6 dimensions).
Dogfooding showed that structural-only review missed issues only the
semantic layer caught.
