---
id: IRON-002
trigger: "proposing a new component, tool, abstraction, or system"
domain: architecture
source_phase: multi
confidence: absolute
helpful: 0
harmful: 0
status: iron
---

# IRON RULE: Check What Exists Before Building

## When this applies
Any decision to build something new — a function, a tool, a library, a system, an abstraction. Before writing any new code, check whether the functionality already exists in the codebase, in a dependency, or in a standard library.

## Always
- Search the codebase for existing implementations before writing a new one
- Check if a dependency already provides the functionality
- Look for standard library solutions before adding third-party dependencies
- Ask: "why doesn't this already exist?" — the answer often reveals constraints you haven't considered

## Never
- Build a new abstraction without checking if one already exists nearby
- Assume that because you haven't seen it, it doesn't exist
- Justify a new implementation by claiming the existing one is "not quite right" without articulating the specific gap
- Create a wrapper around a wrapper

## Why
Duplicate implementations are the most common source of unnecessary complexity. They create maintenance burden (two things to update), inconsistency (they inevitably diverge), and confusion (which one should I use?). The impulse to build fresh is strong because building is more satisfying than reading, but reading first prevents the most common class of unnecessary work.

## Anti-pattern
"I need a helper for X, let me write one" → The codebase already has a helper for X in a different module. Now there are two, with slightly different behavior, and no one knows which to use. Future developers find the first one they encounter and use it, creating silent inconsistencies.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Writing a custom parser when a standard library exists | `import re` or manual string splitting for a format with a stdlib parser (`json`, `csv`, `configparser`, `urllib.parse`) | Custom parsers handle the happy path but miss edge cases the stdlib handles — quoting, escaping, Unicode, empty fields |
| Vendoring a library to add one feature that already exists in a dependency | New entry in requirements.txt or package.json where an existing dependency's API covers the need | Adds supply chain surface, version conflicts, and maintenance burden for functionality already available |
| "Not quite right" justification without articulating the gap | PR description says "existing solution doesn't meet our needs" without naming the specific missing capability | The gap is often cosmetic or fixable with a small patch to the existing code — building new is more satisfying but costs 10x the maintenance |

## Source
nana-soul.md "Before any recommendation: check if there's existing code, prior art, or documented decisions that constrain the choice." Reinforced by HEU-004 (vendor boundary) and working-knowledge entries on duplication avoidance.
