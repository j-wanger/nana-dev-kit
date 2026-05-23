---
title: Engineering Gap Analysis & Roadmap
created: 2026-05-20
updated: 2026-05-22
status: active
---

# Engineering Gap Analysis & Roadmap

> Goal: make nana-dev-kit a complete end-to-end development automation tool.
> Source: user-authored gap analysis, phases 14-17 followed this as build order.

## Gap Status (as of Phase 22)

### Tier 1: Integration — connect existing pieces

| Gap | Description | Status |
|-----|------------|--------|
| 1.1 | Dev-wiki skills not installed | **CLOSED** Phase 15 |
| 1.2 | Knowledge-wiki skills not installed | **CLOSED** Phase 15 |
| 1.3 | Memory ↔ dev-wiki bridge | **CLOSED** Phase 19 (memory-bridge.md companion, dev-plan auto-stores decisions via memory_store) |
| 1.4 | Session state from memory | **CLOSED** Phase 15 (session-start.sh memory guidance) |
| 1.5 | No PreCompact hook | **CLOSED** Phase 15 |
| 1.6 | No PostCommit hook for dev-wiki | OPEN |

### Tier 2: Enforcement — proven patterns

| Gap | Description | Status |
|-----|------------|--------|
| 2.1 | No spec-enforcement hook | **CLOSED** Phase 16 (enforce-spec.sh) |
| 2.2 | No self-verification loop | **CLOSED** Phase 16 (enforce-loop.sh) |
| 2.3 | No loop/drift detection | **CLOSED** Phase 17 (detect-loop.sh) |
| 2.4 | Stop hook doesn't check debrief | **CLOSED** Phase 16 (enforce-loop.sh) |

### Tier 3: Automation — reduce manual overhead

| Gap | Description | Status |
|-----|------------|--------|
| 3.1 | No auto-debrief at context pressure | **PARTIAL** PreCompact covers worst case |
| 3.2 | Memory consolidation is manual-only | **PARTIAL** nudge in session-start exists |
| 3.3 | No auto-store for spec decisions | **CLOSED** Phase 19 (spec SKILL.md inline memory_store after Step 6) |
| 3.4 | Working-knowledge lifecycle | **CLOSED** Phase 17 (stale-queue pruning) |

### Tier 4: Capability — extend the value chain

| Gap | Description | Status |
|-----|------------|--------|
| 4.1 | Language-agnostic mode | OPEN (wiki-index ships Python) |
| 4.2 | Eval harness for the harness | **CLOSED** Phase 20 (eval-runner.sh, 38 scenarios, binary scoring) |
| 4.3 | Worktree / parallel development | OPEN |
| 4.4 | Wiki ↔ memory bidirectional bridge | **PARTIAL** Phase 19 (memory_search in wiki-query reads, memory_store in dev-plan/spec writes; missing: auto-generation of wiki articles from memory) |

### Unplanned (emerged during execution)

| Item | Description | Status |
|------|------------|--------|
| U.1 | /spec routing — skill not recognized as command | **CLOSED** Phase 18 (mitigated: auto-invocation bypasses user-side routing) |
| U.2 | Spec/dev-plan UX unification | **CLOSED** Phase 18 (spec-auto-invoke.md companion) |
| U.3 | session-start.sh refactoring (~125 lines, 8 concerns) | **CLOSED** Phase 22 (extracted wk-prune.sh + memory-nudge.sh to session-start.d/) |

## Remaining Build Order Candidates

1. ~~**Spec/dev-plan UX** (U.1 + U.2)~~ — **DONE** Phase 18
2. ~~**Memory ↔ wiki bridge** (1.3 + 3.3 + 4.4-light)~~ — **DONE** Phase 19
3. **Language-agnostic core** (4.1) — factor py-* out, create /init router
4. ~~**session-start.sh refactor** (U.3)~~ — **DONE** Phase 22
5. ~~**Version bump v0.4.0**~~ — **DONE** Phase 22
6. ~~**Eval harness** (4.2)~~ — **DONE** Phases 20-21
7. **Worktree/parallel** (4.3) — high effort, high value for larger projects

## What NOT to Build

- Custom protocols (MCP + AGENTS.md is the stack)
- Auto-generated AGENTS.md (ETH Zurich: hurts performance)
- Web UI / dashboard (markdown files are the dashboard)
- Multi-model orchestration (harness is model-agnostic)
- Embedding-based memory as default (FTS5 is sufficient)
