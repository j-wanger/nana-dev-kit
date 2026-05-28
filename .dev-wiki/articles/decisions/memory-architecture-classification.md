---
title: "Memory Architecture Classification"
aliases: [memory-layers, activation-modes]
category: decisions
tags: [memory-architecture, activation-modes, cognitive-activation]
parents: [phase-56-cognitive-activation-memory-design]
created: 2026-05-28
updated: 2026-05-28
source: plan
confidence: high
status: accepted
---

## Context

Phase 42's effectiveness experiment tested whether the harness improves outcomes. Engineering hooks (auto-ruff, scan-secrets, audit-log) fired automatically and worked. Cognitive tools (knowledge wiki, heuristic library, decision articles) are voluntary skills and never fired. The agent's natural behavior is to start coding — voluntary invocation doesn't happen.

The harness has 5 memory/knowledge layers that evolved organically across 55 phases. No unified classification existed. This decision establishes activation modes for each layer with rationale traceable to experiment evidence.

## Decision

Three activation modes, ordered by reliability:

- **Mandatory**: content loaded into agent context automatically via `.claude/rules/` files. Agent sees it without choosing to. Always present after compaction. Most reliable — cannot be unwired.
- **Automatic**: content retrieved as a side effect of a skill the agent invokes for another reason. No separate invocation needed, but requires the parent skill to run. Reliable when the skill fires; silent when it doesn't.
- **Voluntary**: agent must explicitly choose to invoke. Experiment evidence: agents skip voluntary tools. Least reliable for cognitive tasks.

### Layer Classification

| Layer | Path | Mode | Rationale |
|-------|------|------|-----------|
| Working knowledge | `.claude/rules/working-knowledge.md` | **Mandatory** | Rules file, always in context. Cross-phase facts survive compaction. Proven reliable across 55 phases — never failed to surface. |
| Active knowledge | `.claude/rules/active-knowledge.md` | **Mandatory** | Rules file written by dev-plan Step 8f-bis from wiki articles. Phase-specific context always present during implementation. Cleared between phases. |
| Dev wiki | `.dev-wiki/` | **Automatic** | Session-start.sh reads `_CURRENT_STATE.md` (mandatory via hook). Dev-plan reads extensively (automatic within skill). Hooks enforce lifecycle (enforce-spec, enforce-loop). Mixed: mandatory for state, automatic for planning. |
| Knowledge wiki | `wiki/` | **Automatic** (upgraded from voluntary) | Dev-plan Step 2 reads wiki articles as part of planning flow. Spec Domain Research Questions prompt wiki consultation. Heuristic matcher runs at Step 6.5. All automatic within existing skills — no separate invocation. Gap: skills must actually run, and wiki must have content. |
| MCP memory | `.memory/memory.db` | **Voluntary** (with nudges) | memory_search/memory_store are MCP tools requiring explicit calls. Soul.md says "at session start, call memory_search" but no hook enforces it. Session-start emits a suggested query. Stays voluntary: memory is cross-project and cross-session — forced injection would be noisy. Nudges are sufficient. |

### Why not add hooks for the knowledge wiki?

The experiment showed mandatory > voluntary, but the working mandatory mechanisms in the harness are `.claude/rules/` files, not hooks. Adding hooks for cognitive injection risks the same unwiring anti-pattern that caused Category 1 failures (enforce-spec.sh on disk but unregistered, three instances across project history). The knowledge wiki's content already flows into `.claude/rules/active-knowledge.md` via dev-plan — that's the mandatory path. The gap is that the wiki needs content and the empty state needs handling, not that the activation mechanism is wrong.

### Activation gaps this classification reveals

1. **Knowledge wiki empty state**: when wiki has zero domain articles, automatic activation returns nothing. Dev-plan Step 2 advises "continue without wiki knowledge" — too weak. Needs upgrade to a stronger recommendation.
2. **Wiki seeding trigger**: nana-init creates wiki structure but doesn't recommend content seeding. New projects start with empty cognitive infrastructure.
3. **Cognitive readiness diagnostic**: session-start reports status but doesn't recommend specific actions. Needs upgrade from labels to actionable guidance.

## Consequences

- Knowledge wiki stays at 0 hooks in modules.json. Activation is through skill-based automatic retrieval, not hook-based mandatory injection.
- The mandatory path for wiki content is: wiki articles → dev-plan Step 8f-bis → active-knowledge.md (rules file). This path requires dev-plan to run.
- Empty-wiki state must be handled explicitly at dev-plan Step 2 and nana-init Step 4/5 — advisory messages are insufficient.
- MCP memory remains voluntary with nudges. No hook-based memory injection planned.
- Future content additions to the knowledge wiki automatically surface through existing dev-plan and spec flows — no new wiring needed.
