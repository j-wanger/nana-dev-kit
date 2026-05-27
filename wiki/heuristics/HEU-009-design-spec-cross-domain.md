---
id: HEU-009
trigger: "porting or adapting a solution from one language, framework, or domain to another"
domain: architecture
source_phase: 34
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Design Spec Before Cross-Domain Migration

## When this applies
You're porting an existing solution to a new language, framework, or domain
(e.g., Python scaffold → TypeScript, REST API → GraphQL, monolith → microservices).

## Always
- Write a design spec that maps EVERY assumption from the source to the target
- For each assumption: is it valid in the new domain? What's the equivalent?
- Enumerate the toolchain differences explicitly (build, test, lint, format, CI)
- Identify "invisible" assumptions (file layout conventions, config formats, runtime behavior)

## Never
- Clone the source and search-replace language-specific tokens
- Assume 1:1 mapping between ecosystems (pyproject.toml ≠ package.json)
- Start implementing before auditing assumptions ("we'll figure it out as we go")

## Why
Cross-domain migrations fail when invisible assumptions transfer unchecked.
Python's single config file (pyproject.toml) doesn't map to TypeScript's
two-file model (tsconfig.json + package.json). Python's separate linter and
formatter (ruff) doesn't map to TypeScript's integrated tool (biome). A
design spec surfaces these mismatches before implementation locks them in.

## Anti-pattern
"The languages are similar enough, we can adapt as we go" → This produces
a hybrid that follows neither ecosystem's conventions. The TypeScript
scaffold ends up with Python-style directory layout, or Python idioms
appear in TypeScript code. The design spec forces you to think in the
target domain.

## Source
Phase 34: TypeScript design spec (specs/ts-init-design.md) mapped all
py-init assumptions to TypeScript equivalents before Phase 35 implementation.
Surfaced 8 mismatches that would have caused rework if discovered mid-implementation.
