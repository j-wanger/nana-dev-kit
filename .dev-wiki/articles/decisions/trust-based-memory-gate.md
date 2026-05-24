---
title: "Trust-based memory gate"
aliases: [memory-gate-trust-based, memory-consulted-marker]
category: decisions
tags: [enforcement, memory, hooks]
parents: [phase-31-integration-eval-memory-gating]
created: 2026-05-23
updated: 2026-05-24
source: debrief
confidence: medium
status: active
---

## Context

enforce-memory.sh needs to know whether the agent has consulted memory before writing code. Two approaches: (1) PostToolUse hook auto-detects MCP memory_search calls, or (2) agent touches a gate marker file after calling memory_search.

## Decision

Trust-based gate: the agent touches .claude/.memory-consulted after calling memory_search. No PostToolUse auto-detection. The hook stderr message provides guidance on what to do when blocked. This is simpler and avoids the complexity of intercepting MCP tool calls at the hook layer.

## Consequences

- Simpler implementation: hook checks file existence, not MCP call interception.
- Relies on agent compliance (touching marker after memory_search), not mechanical enforcement.
- Hook stderr guides the agent on how to unblock itself.
- session-start.sh clears .memory-consulted at session start to force re-consultation each session.
- If the agent is modified to skip the marker, enforcement is bypassed. Acceptable for the current trust model.
