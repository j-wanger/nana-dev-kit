# Phase 119 · T1 VERIFICATION CHECKPOINT — A1 gate-survival verdict

Date: 2026-07-01 · Task: T1 (persistent-session foundation) · Status: **BUILT + GREEN, awaiting maintainer live-drive**

## The A1 question (deferred don't-know, cost high)
Does a **persistent** Pi session keep the host gate **un-bypassable across turns AND every session-mutation** — i.e. does Pi v0.80.2 re-run the loader's `extensionFactories` (which would re-register or DROP the `tool_call` gate hook) on `setModel` / `cycleModel` / `compact` / `setAutoCompactionEnabled` / `setThinkingLevel`, or does the hook survive?

## VERDICT: **SURVIVES — every mutation keeps the gate attached. DEFER NOTHING.**
T2 (`compact`), T4 (`setModel`/`cycleModel`), T5 (`setThinkingLevel`) are all cleared to build. No surface is deferred on gate-detachment grounds.

## Evidence (three independent sources, converging)

**1. Compiled-SDK read (authoritative, quoted code).** `@earendil-works/pi-coding-agent@0.80.2`:
- `dist/core/agent-session.js:177-205` — `_installAgentToolHooks()` installs `agent.beforeToolCall` **once** in the `AgentSession` ctor; the callback reads `this._extensionRunner` **at call time**. Its own comment: *"Install tool hooks once on the Agent instance. The callbacks read `this._extensionRunner` at execution time, so extension reload swaps in the new runner without reinstalling hooks."*
- `this._extensionRunner` is reassigned in exactly ONE method — `_buildRuntime` (`agent-session.js:1933`), reachable ONLY from the ctor (`:142`) and `reload()` (`:1955`).
- `setModel` (`:1105`), `cycleModel` (`:1124`), `compact` (`:1274`), `setAutoCompactionEnabled` (`:1639`), `setThinkingLevel` (`:1182`) mutate plain fields (`agent.state.model` / `.thinkingLevel` / `.messages`) + write session/settings, then emit through the **existing** runner. None call `_buildRuntime`/`reload`/`dispose`/`new ExtensionRunner`.
- `compact`'s `_disconnectFromAgent`/`_reconnectToAgent` (`:460`/`:470`) touch only the low-level `agent.subscribe(_handleAgentEvent)` listener (`_unsubscribeAgent`) — NOT `beforeToolCall` and NOT the public `AgentSession.subscribe` list.
- The only ways to drop the hook are `reload()` (which re-registers it from the loader factories anyway) and `dispose()` (teardown).

**2. Pi's own docs / CHANGELOG (independent of the JS).**
- `docs/extensions.md:414` — new-session/switch emits `session_shutdown` → **reloads and rebinds extensions** → `session_start`. So new-conversation re-attaches the gate via the loader factories.
- `docs/extensions.md:701` + `CHANGELOG:2945/2935` — model changes fire `model_select`/`thinking_level_select` hooks *to still-bound extensions*; `ctx.model` became a getter "instead of a snapshot." Extensions **persist across `setModel`**.
- `session_before_compact` / `session_compact` hooks fire to bound extensions ⇒ extensions **persist across `compact`**.

**3. LIVE empirical (this session, local Qwen3.6-35B via llama.cpp).**
- `tests/e2e/provider-roundtrip.test.ts` — "the persistent session holds the gate on TURN 2 — a real rm is still blocked (Ph119 T1)": one adapter, benign turn 1, then a real `rm -f sentinel.txt` on **turn 2 of the same persistent session** → the gate still intercepted, the sentinel survived. PASS (~4s). Proves the **turn-boundary persistence** holds the gate against a real model.

### Honest scoping of the evidence
The LIVE proof covers **turn-to-turn persistence** (the foundation). The **per-mutation** survival (setModel/compact/setThinkingLevel) rests on sources **1 + 2** (compiled-JS read + docs) — those methods are NOT yet exposed on the adapter (they are T2/T4/T5), so they aren't exercised live in T1. Each will ship its own gate-survives-after live check at its task + the maintainer live-drive (the C3 discipline). One residual to verify at T2: that `compact()` preserves the **public** `AgentSession.subscribe` UI listener (source 1 says it only disconnects the internal `_unsubscribeAgent`, but T1 does not exercise it live).

## What T1 built
- `app/src/engine/pi/pi-adapter.ts` — the per-turn-ephemeral session (built + `dispose()`d inside every `sendPrompt`) is now **build-once / reuse-across-turns**. New: `PiSessionHandle` / `PiSessionBuildArgs` / `PiSessionBuilder` seam, `ensureSession` (build-once + in-flight guard + `setAutoCompactionEnabled(true)` folded in as the correctness dependency), `buildDefaultSession` (embeds Pi; the extract that build / new-conversation both reuse), `newConversation` (dispose+rebuild → gate re-attaches), `dispose`.
- **C1 decouple** — the gate denial-sink and the subscribe callback both push to `this.currentTurn`, read **at call time** and swapped each turn. A denial on turn N reaches turn N's stream even though the hook was wired once at build.
- **Workspace-change** stays a sidecar respawn; the fail-closed gate is resolved at call time bound to `this.workspaceRoot` (a respawn = a new adapter for the new root → gate rebinds).
- `app/src/engine/adapter.ts` — optional `newConversation?()` on `EngineAdapter`.
- `app/src/host/engine-host.ts` — `new-conversation` inbound (rejects held gate awaits, then resets the session). Guard `tests/host/palette-no-bypass.test.ts` updated: it is a benign non-gate member (the `gateLike` guard still enforces "no new gate channel").
- Tests: `tests/adapters/pi-persistent-session.test.ts` (7 mechanics, fake-session injected) + the live turn-2 gate-survival test.

## Exit-gate status
`cd app && npm test` → **382 passed / 55 files** (incl. all live gate tests) · `npm run build` (tsc + vite) → green · `cd src-tauri && cargo check` → green.

## Maintainer live-drive (vitest-invisible; still outstanding)
1. Turn-2 denial **visible in the UI** (mechanics + the live rm-block are proven; UI surfacing is the drive).
2. Interrupt-then-continue on the same window (hard-interrupt a turn, then continue — the session stays usable).
3. Restart divergence marker (a restored thread against a fresh engine shows "model context reset" — that marker is T3).

## Decision
Proceed to T2–T8 (T9 verify). No surface deferred. The next mutating surfaces (T2 compact, T4 setModel, T5 setThinkingLevel) each ship a "gate-still-intercepts-after-X" check per the C3 discipline.

---

## Delivery addendum (2026-07-01, after autonomous T2→T9)

All 9 tasks BUILT + GREEN: `cd app && npm test` **456/456** (61 files, incl. all live gate tests) · `npm run build` · `cargo check`.

**Adversarial gate-bypass review** (subagent, 6 load-bearing claims re-checked against the diff): **ZERO defects — no gate bypass, no detached gate, no broken invariant.** All CONFIRMED-SAFE with file:line evidence: (1) C1 sinks read `this.currentTurn` at call time; (2) mutating surfaces mutate in place, never dispose/rebuild; (3) no new un-gated path — the new inbounds mutate config/read state, `submitPrompt` flows through `engine.sendPrompt`; (4) `newConversation` re-runs the loader factory (gate re-registers); (5) fail-open memory is context-only, can't skip the gate or wedge a turn; (6) AGENTS.md injected once, conventions are context-only. It also confirmed `broker.rejectAll()` resolves held calls as **denied** on reset (no ungated execution) and the host-gate policy is byte-unchanged.

**2 Low nits fixed inline** (+ tests): (1) a mid-turn `/compact` (or model/thinking switch) could nuke a running turn — Pi's `compact()` aborts the in-flight op, and the host didn't try/catch the mutation calls → a rejection would broadcast a top-level error to all turns. Fixed: `EngineHost.runMutation` try/catch + those three commands disabled while `isRunning`. (2) the memory retriever's "fail-open on timeout" was unenforced (relied on a 15s connect cap) → added a 5s retrieval timeout + a 4s connect cap in main.ts.

**Accepted residuals** (very-low / display-only / fail-safe): concurrent-`prompt` event misroute is prevented by the UI `isRunning` guard (not a bypass); spend/meter show `$0.00` after a reset while the monotonic ceiling holds the prior cumulative (fail-safe direction); `useSessionControls` eagerly builds the session at surface mount (benign — the gate attaches on build).

**Outstanding (maintainer):** the delivery gate + a live-drive of the three vitest-invisible behaviors — turn-2 denial visible in the UI, interrupt-then-continue, restart divergence marker.
