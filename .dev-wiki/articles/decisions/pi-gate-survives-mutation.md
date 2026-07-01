---
title: "Pi host gate survives persistence + session mutation (Ph119 A1 verdict)"
aliases: [pi-gate-survives-mutation, a1-gate-survival-verdict, ph119-a1, gate-survives-persistent-session]
category: decisions
tags: [pi-agent, pi-sdk, gui-harness, host-gate, persistent-session, gate-survival, phase-119, checkpoint-verdict]
parents: [phase-119-pi-ux-felt-quality-ecosystem]
created: 2026-07-01
updated: 2026-07-01
source: debrief
confidence: high
---

## Context

Phase 119 rebuilt nana's per-turn EPHEMERAL Pi session (built + `dispose()`d inside every `sendPrompt`) into ONE PERSISTENT build-once/reuse-across-turns session. The make-or-break, and the phase's hard T1 CHECKPOINT: nana's un-bypassable host gate ([[engine-adapter-in-process-gate]]) is wired into the Pi session at `pi.on('tool_call')`, so a persistent session had to keep the gate un-bypassable across turn boundaries AND across every session-mutating call (`setModel`/`cycleModel`/`compact`/`setAutoCompactionEnabled`/`setThinkingLevel`). The A1 assumption (ledger Ph119, cost HIGH, deferred don't-know) was: does Pi v0.80.2 re-run the loader's `extensionFactories` on a mutation — which would drop or re-register the gate hook — or does the hook survive? If it detaches on a mutation, that surface must be DEFERRED; if the gate can't survive a persistent turn-2, the foundation STOPs rather than swap the session out from under the gate.

## Decision

**VERDICT: the gate SURVIVES persistence + every mutation — DEFER NOTHING.** T2 (`compact`), T4 (`setModel`/`cycleModel`), T5 (`setThinkingLevel`) were all cleared to build. Three independent converging sources:

1. **Compiled-SDK read (authoritative).** `@earendil-works/pi-coding-agent@0.80.2`: `AgentSession` installs `agent.beforeToolCall` ONCE in the ctor (`_installAgentToolHooks`, `agent-session.js:177-205`); the callback reads `this._extensionRunner` AT CALL TIME. `_extensionRunner` is reassigned in exactly one method — `_buildRuntime` (`:1933`) — reachable ONLY from the ctor (`:142`) and `reload()` (`:1955`). None of `setModel` (`:1105`) / `cycleModel` (`:1124`) / `compact` (`:1274`) / `setAutoCompactionEnabled` (`:1639`) / `setThinkingLevel` (`:1182`) call `_buildRuntime`/`reload`/`dispose` — they mutate plain fields and emit through the EXISTING runner. `compact`'s `_disconnect`/`_reconnectToAgent` (`:460`/`:470`) touch only the low-level `agent.subscribe(_handleAgentEvent)` listener, NOT `beforeToolCall` and NOT the public `AgentSession.subscribe` list.
2. **Pi docs / CHANGELOG (independent of the JS).** Extensions persist across model change (`ctx.model` became a getter, not a snapshot); `session_compact` hooks fire to still-bound extensions; new-session/switch emits `session_shutdown` → reloads+rebinds extensions → `session_start`.
3. **LIVE empirical.** The persistent session blocked a real `rm` on TURN 2 of the same session (provider-roundtrip, ~4s) — proves turn-boundary persistence holds the gate against a real model.

Resolves ledger A1 (deferred don't-know → **held**, gate survives). Alternative REJECTED: swap the session out from under the gate on mutation (would detach it — the worst outcome). Full report: `.dev-wiki/phase-119/checkpoint-a1-gate-survival.md`; memory `mem_s32XtbBONCiP`.

## Consequences

- The persistent build-once session is SAFE; `new-conversation` = dispose+rebuild re-attaches the gate via a fresh loader-factory run.
- The LIVE proof covers turn-to-turn persistence; per-mutation survival rests on sources 1+2 (compiled-JS + docs), so each mutating surface (T2/T4/T5) ships its OWN gate-survives-after live check (the C3 discipline), plus the maintainer live-drive.
- The un-bypassable-gate invariant ([[engine-adapter-in-process-gate]], Ph108/112) is preserved through the persistence rebuild — the host-gate policy stayed byte-unchanged.
- An adversarial gate-bypass review (6 load-bearing claims re-checked against the diff) found ZERO defects: C1 sinks read `this.currentTurn` at call time, mutating surfaces mutate in place (never dispose/rebuild), `broker.rejectAll()` resolves held calls as DENIED on reset.
