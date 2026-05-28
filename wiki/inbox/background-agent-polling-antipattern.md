---
title: "Background Agent Polling Loop Anti-Pattern"
tags: [anti-pattern, transferable, agent-orchestration]
source: conversation
tier: private
created: 2026-05-28
---

# Background Agent Polling Loop

## Anti-pattern

When waiting for a background agent (reviewer, state loader, artifact writer) to complete, polling with repeated no-op commands (`echo "waiting"`) wastes tokens, fills context window, and provides no value. The harness sends a notification when the agent completes — polling adds nothing.

## Symptoms

- Dozens of identical `echo "waiting"` calls in the transcript
- Context window consumed by no-op tool calls instead of useful work
- Premature fallback ("reviewer unavailable") triggered by impatience rather than actual failure
- Reviewer findings missed or nearly skipped because the orchestrator proceeded without them

## Evidence

Phase 56 planning session: 40+ echo calls across two reviewer waits. The plan reviewer caught a real bug (Task 2's RED step was broken — exit criterion already passed), but its findings nearly got skipped because the orchestrator used the "reviewer unavailable" fallback prematurely. The artifact writer was dispatched with broken tasks as a result.

## Fix

Trust the notification system. When a background agent is running:
1. Do genuinely independent work if any exists
2. Otherwise, simply wait for the notification
3. Only use the "reviewer unavailable" fallback if the agent actually errors or fails — not because it's taking long
4. Background agents routinely take 1-3 minutes; this is normal, not a timeout signal
