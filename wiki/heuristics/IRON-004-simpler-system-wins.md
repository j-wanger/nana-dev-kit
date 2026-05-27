---
id: IRON-004
trigger: "choosing between two approaches where one is simpler"
domain: architecture
source_phase: multi
confidence: absolute
helpful: 0
harmful: 0
status: iron
---

# IRON RULE: The Simpler System Wins Unless Proven Otherwise

## When this applies
Any design decision where two or more approaches achieve the same goal with different levels of complexity. This includes choosing between architectures, libraries, patterns, abstractions, and implementation strategies.

## Always
- Default to the simpler approach and require the complex approach to justify its additional complexity
- Apply the subtraction test: remove each component and ask what breaks — if nothing breaks, remove it
- Count the moving parts: fewer moving parts means fewer failure modes
- Prefer solutions that are easy to understand, debug, and replace

## Never
- Choose the complex approach because it handles hypothetical future requirements
- Add abstractions, frameworks, or indirection layers without a concrete current need
- Justify complexity with "we might need it later" — build for today, refactor when the need materializes
- Equate sophistication with quality
- Confuse "less effort now" with "simpler system" — measure simplicity by total lifecycle complexity, not upfront cost. A cleanup that removes 80% of moving parts is the simpler path even if it costs more upfront

## Why
Complexity is a cost paid on every interaction with the system — reading, debugging, modifying, explaining, onboarding. Simple systems fail in simple, diagnosable ways. Complex systems fail in emergent, hard-to-reproduce ways. The compounding cost of complexity means that a slightly less capable but simpler system usually delivers more total value over its lifetime than a more capable but complex one. The burden of proof should always be on the complex approach to justify itself.

## Anti-pattern
"Let's build an abstraction layer so we can swap implementations later" → The abstraction adds indirection, splits logic across files, and makes debugging harder. The implementation is never swapped. The abstraction persists as permanent complexity tax that every developer pays when reading or modifying the code.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| incremental cleanup of compounding debt | Rationale contains "clean up a few each sprint" for a problem where inaction makes it worse each cycle | incremental cleanup competes with feature work for prioritization — feature work always wins because it is visible. After 3 sprints the problem is larger, not smaller |
| Premature generalization via config | Config file growing past 500 lines or config options outnumbering code paths | Configuration is deferred complexity — every option is a code branch the developer must understand but cannot see in the source |
| Avoiding a rewrite when the old system's complexity exceeds the rewrite cost | "Too risky to rewrite" for a system where every change triggers 3+ unrelated test failures | The old system's accumulated complexity has already exceeded the rewrite budget — continuing to patch it pays the complexity tax on every future change |

## Source
nana-soul.md "Simpler systems that work over clever systems that might." Reinforced across 44 phases: ceremony reduction (Phase 5→37), install.sh simplification (Phase 40), 2-gate model over 4-gate (Phase 37).
