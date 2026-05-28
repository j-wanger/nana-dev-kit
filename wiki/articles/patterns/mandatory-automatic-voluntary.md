---
title: Mandatory-Automatic-Voluntary Activation Spectrum
tags: [reasoning-pattern, transferable, activation-architecture]
created: 2026-05-28
updated: 2026-05-28
source: phase-56-memory-architecture-classification
---

# Mandatory-Automatic-Voluntary Activation Spectrum

## Pattern

Agent tools and knowledge sources have three activation modes. The mode determines reliability — the likelihood the tool actually fires in practice.

- **Mandatory**: content loaded into agent context automatically (e.g., rules files, always-present configuration). Agent sees it without choosing to. Cannot be unwired. Most reliable.
- **Automatic**: content retrieved as a side effect of a skill invoked for another reason. No separate invocation needed, but requires the parent skill to run. Reliable when the skill fires; silent when it doesn't.
- **Voluntary**: agent must explicitly choose to invoke. Least reliable — agents skip voluntary tools in favor of starting work immediately.

## Evidence

Phase 42 effectiveness experiment: engineering hooks (mandatory/automatic via PostToolUse) worked perfectly. Cognitive tools (voluntary skills) never fired. The agent's natural behavior is to start coding, not to consult knowledge sources.

The reliable mechanisms in the harness are `.claude/rules/` files (always loaded, survive compaction) and hooks (fire on events). Voluntary skills require the agent to have been trained or prompted to invoke them — and even with soul-level instructions ("at session start, call memory_search"), compliance is inconsistent.

## When to apply

Designing any agent harness, tool suite, or plugin system where some behaviors must reliably occur:
- Code quality tools → mandatory (hooks that fire on every write)
- Domain knowledge retrieval → automatic (embedded in planning skill flows)
- Exploratory research → voluntary (agent decides when useful)

## Trade-offs

- **Mandatory for everything**: ceremony inflation, context dilution, agent can't prioritize
- **Voluntary for everything**: important tools never fire, agent takes the shortest path
- **Right classification**: match activation mode to cost-of-missing. High cost → mandatory. Low cost → voluntary.
