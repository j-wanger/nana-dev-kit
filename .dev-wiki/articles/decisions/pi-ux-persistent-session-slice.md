---
title: "Pi-UX persistent-session foundation + Tier 1/3 slice (Ph119)"
aliases: [pi-ux-persistent-session-slice, persistent-pi-session, pi-felt-quality-slice, ph119-decision]
category: decisions
tags: [pi-agent, gui-harness, persistent-session, host-gate, felt-quality, phase-119]
parents: [phase-119-pi-ux-felt-quality-ecosystem]
created: 2026-07-01
updated: 2026-07-01
source: plan
confidence: high
outcome: "BUILT + adversarially-reviewed clean (2026-07-01) — all 9 tasks GREEN; delivery pending the maintainer live-drive. A1 resolved held ([[pi-gate-survives-mutation]])."
---

## Context

The 2026-07-01 research spike [[pi-gui-setup-improvements]] produced a tiered improvement list for nana's OWN embedded-Pi GUI. The reviewer proposed splitting the work; the maintainer chose all-in (Tier 1 + Tier 3 in ONE phase). The root discovery that shapes the whole phase: nana's Pi session is **per-turn EPHEMERAL** — `pi-adapter.ts` builds a fresh `createAgentSession` + `SessionManager.inMemory` INSIDE every `sendPrompt` and `dispose()`s it in the `finally`; there is no `this.session`. So the finding's headline "inMemory never compacts" is really "the session never lives long enough to accumulate anything to compact." Every felt-quality item (context/cost meter, compaction, runtime model/thinking switch) PRESUPPOSES a session that lives across turns. The make-or-break risk: nana's un-bypassable host gate ([[engine-adapter-in-process-gate]]) is wired into that per-turn session, so a persistent session must keep the gate un-bypassable across persistence AND every session-mutating call.

## Decision

Incorporate the finding's Tier 1 + Tier 3 in ONE phase on a **PERSISTENT-SESSION foundation**. T1 rebuilds `pi-adapter.ts` to hold ONE persistent Pi session (build-once, reuse across turns; new-conversation = dispose+rebuild with the gate re-attached; workspace-change stays a sidecar respawn that REBINDS the gate to the new `workspaceRoot`) and is a **VERIFICATION CHECKPOINT** that proves the gate survives persistence + mutation — STOP if it can't. Two approach-reviewer + one plan-reviewer pass (5/10 → 7/10) folded: **C1** decouple the gate denial-sink from the per-turn EventQueue (swap a per-turn queue REFERENCE each turn, don't capture a constant); **C3** every session-mutating call ships a gate-survives-after test; **compaction** folded into the foundation as a correctness dependency (`setAutoCompactionEnabled`); **de-dup the double AGENTS.md** via `noContextFiles:true` on Pi's `DefaultResourceLoader` + `assembly.ts` as the SOLE injector; **crash-isolation** named as a regression (new-conversation = the recovery); **workspace-change respawn** must rebind the gate to the new root.

Gate resolutions (ledger Ph119 `all_accept:false`): **A2 accept** — keep Ph115 restore DISPLAY-ONLY + add a "model context reset" marker ([[conversation-memory-persistence]]). **A1/A3/A4 DEFERRED don't-knows** (revisit-open): A1 (gate-survives-mutation) resolves at the T1 checkpoint; A3 down-scoped to HOST-ORCHESTRATED memory (no model-facing MCP carve-out this phase); A4 down-scoped to AGENTS.md/context injection (no `systemPromptOverride` this phase).

Alternatives / DON'Ts: the reviewer's split (rejected — maintainer chose all-in); a model-facing memory carve-out + `systemPromptOverride` (deferred, verified-first later); the T2 items gate-hero / file-timeline / branching (later).

## Consequences

- T1 is a hard checkpoint before ANY mutating surface — if Pi v0.80.2 detaches the gate on `setModel`/`compact` (re-runs `extensionFactories`), that surface is DEFERRED; if the gate can't survive a persistent turn-2, the foundation STOPs+reports rather than swapping the session out from under the gate.
- T4 (model switcher) is GATED on T1's setModel-survival verdict; T5 (thinking toggle) is self-verified (`setThinkingLevel` is synchronous, not a T1 dependency).
- Memory stays host-orchestrated and the system prompt stays untouched this phase — the un-bypassable-gate invariant is never widened to cover a new model-facing tool surface.
- Local `$0` default is kept; felt-quality ships on maintainer judgment at the delivery gate (Ph59/80 carve-out, [[felt-quality-surface]]).
- Rides [[pi-default-engine]] (Pi is the default daily engine) and the umbrella spec `specs/gui-harness-architecture.md`.

## Outcome (2026-07-01 debrief)

BUILT + GREEN — all 9 tasks (T1–T9), `cd app && npm test` 456/456 (61 files, incl. live gate tests) + `npm run build` + `cargo check`. The maintainer took the USER-OVERRIDE "continue autonomously T2→T9" at the T1 checkpoint (the A1 verdict was reported first). A1 resolved **held** — the gate survives persistence + every mutation, DEFER NOTHING ([[pi-gate-survives-mutation]]). No surface was deferred. An adversarial gate-bypass review found ZERO defects; 2 Low nits fixed inline (host `runMutation` try/catch so a mid-turn `compact` can't nuke in-flight turns; a 5s memory-retrieval timeout). The host-gate policy stayed byte-unchanged. T9 verified the hosted-`maxTokens` "bug" is [[hosted-maxtokens-not-a-bug|not a bug]]. A3 (model-facing memory carve-out) + A4 (`systemPromptOverride`) remain DEFERRED — the SAFE host-orchestrated / context-injection defaults shipped. **Delivery gate still open** — pending the maintainer live-drive (turn-2 denial visible, interrupt-then-continue, restart divergence marker). Confidence stays high.
