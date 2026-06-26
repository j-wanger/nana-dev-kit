---
title: "Second adapter = Vercel AI SDK (substituted for the spec's Claude Agent SDK)"
aliases: [second-adapter-vercel-ai-sdk, vercel-second-adapter, engine-neutrality-proof, claude-sdk-adapter-deferred]
category: decisions
tags: [gui-harness, engine-adapter, vercel-ai-sdk, claude-agent-sdk, engine-neutrality, user-override, phase-108]
parents: [phase-108-gui-harness-v1-thin-slice]
created: 2026-06-26
updated: 2026-06-26
source: debrief
confidence: high
---

## Context

The spec ([[engine-adapter-in-process-gate]]) names the **Claude Agent SDK** as the second `EngineAdapter` — the engine-neutrality proof that one host gate path drives ≥2 engines (Phase 108 T7). But the harness defaults to a LOCAL OpenAI-compatible backend with no Anthropic credential ([[provider-defaults-to-local-model]]), and the Claude Agent SDK is **Anthropic-API-key-only** — it cannot drive the local model. With no API key in hand, the spec's named second adapter could not be exercised this phase.

## Decision

**Substitute the Vercel AI SDK as the second adapter** (maintainer chose via AskUserQuestion 2026-06-26 — a USER OVERRIDE of the spec letter, within the spec's approved engine set). The Vercel AI SDK is the spec's own approved FALLBACK engine and is OpenAI-compatible, so it drives the SAME local model through the SAME gate.

Engine-neutrality was then proven EMPIRICALLY (not just by interface conformance): the local Qwen model, driven via the Vercel AI SDK adapter, emitted a `bash rm`; the SAME `createHostGate` — reused verbatim, wrapped around each tool's `execute` via `createGatedToolExecute`, no gate logic duplicated — DENIED it (sentinel survived + tool-denied fired). Two engines (Pi's `tool_call` hook + Vercel's wrapped-execute), one gate.

## Consequences

- T7's exit criterion (second engine through the identical gate path) is met by the Vercel adapter rather than the Claude one — a deviation from the spec LETTER, honored within the spec's approved engine set, logged as a USER OVERRIDE escape hatch.
- The shared `EventQueue` was extracted to `app/src/engine/event-queue.ts` so both adapters feed one surface event channel.
- **The Claude Agent SDK adapter (the Claude-fidelity path) is DEFERRED** to a follow-up phase (Phase 109 candidate), gated on an Anthropic API key existing. Its `canUseTool`→host-gate mapping is deterministically testable now (live-deferred), so the follow-on is low-risk.
- Confirms the core bet of [[engine-adapter-in-process-gate]]: the gate is written once and reused per-engine — adding the third (Claude) engine costs one adapter, not a gate rewrite.

## Source

AskUserQuestion 2026-06-26 (maintainer override); realized in Phase 108 T7. Related: [[engine-adapter-in-process-gate]], [[provider-defaults-to-local-model]].
