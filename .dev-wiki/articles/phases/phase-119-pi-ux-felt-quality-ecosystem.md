---
title: "Phase 119: Pi-UX felt-quality + ecosystem slice (Tier 1 + Tier 3)"
aliases: [phase-119, pi-ux-felt-quality, pi-ecosystem-slice, tier1-tier3-pi, pi-persistent-session]
category: phases
tags: [gui-harness, pi-agent, persistent-session, felt-quality, context-meter, compaction, model-picker, thinking-level, prompt-templates, host-gate, phase-119]
parents: [pi-gui-setup-improvements]
created: 2026-07-01
updated: 2026-07-01
source: plan
status: active
scope: ["app/src/engine/pi/**", "app/src/gate/**", "app/src/host/**", "app/src/context/**", "app/src/ui/**", "app/src/control/spend.ts", "app/src/engine/types.ts", "app/src/engine/adapter.ts", "app/src/memory/mcp-memory.ts", ".claude/rules/active-phase.md", "specs/phase-119-*.md"]
entry_criteria: "Research finding [[pi-gui-setup-improvements]] (medium) delivered 2026-07-01; the T1 felt-quality slice named a Phase-N+1 candidate. Ph118 CLOSED 2026-07-01 (delivery accepted, USER OVERRIDE — the built + twice-reviewed instrument accepted as the deliverable; the live T9 run deferred to a follow-on, blocker = no ANTHROPIC_API_KEY). Independent of that deferred live-run track. Direction gate: ledger Ph119 all_accept:false (A2 accept; A1/A3/A4 deferred don't-know)."
exit_criteria: "vitest green (cd app && npm test) + npm run build (tsc --noEmit && vite build) + (cd src-tauri && cargo check) exit 0; the host gate byte-unchanged + UN-BYPASSABLE across persistence + every session-mutation (T1 VERIFICATION CHECKPOINT proves it, STOP if it can't); the T1 setModel/compact survival verdict recorded (STOP or DEFER the affected surface); Ph115 restore stays DISPLAY-ONLY + a 'model context reset' marker (no-bypass = ZERO engine sends); AGENTS.md injected exactly once (host-sole-injector + noContextFiles:true); host-orchestrated memory retrieval injects to context with NO model-facing memory tool registered; a maintainer live-drive (turn-2 denial visible, interrupt-then-continue, restart divergence). Mechanics-only tests; felt-quality on maintainer judgment (Ph59/80 carve-out, [[felt-quality-surface]])."
---

# Phase 119: Pi-UX felt-quality + ecosystem slice (Tier 1 + Tier 3)

## Objective

Give nana's embedded-Pi GUI real felt-quality on a **persistent cross-turn Pi session**: context%/cost meter + manual `/compact`, runtime model + thinking-level switch, prompt-template/skill palette commands. The root discovery is that nana's Pi session is per-turn EPHEMERAL (built + disposed inside every `sendPrompt`), so every felt-quality item PRESUPPOSES a session that lives across turns. The make-or-break: the un-bypassable host gate must SURVIVE persistence + every session-mutation — T1 is a VERIFICATION CHECKPOINT that proves it (STOP if it can't). Plus SAFE-fallback ecosystem wiring: host-orchestrated memory retrieval + AGENTS.md/context injection (NO carve-out, NO `systemPromptOverride` this phase). Decision [[pi-ux-persistent-session-slice]] (high).

## Scope

Files and modules affected (verified present):
- `app/src/engine/pi/pi-adapter.ts` — persistent-session lifecycle, gate re-attach, compaction, model/thinking, resource loader, hosted maxTokens
- `app/src/host/*` — sidecar entry / engine host (workspace-change respawn rebinds the gate)
- `app/src/gate/*` — host gate (BYTE-UNCHANGED; C1 denial-sink decouple lives at the adapter/queue seam)
- `app/src/engine/{types,adapter}.ts` — ADDITIVE-OPTIONAL context-usage / cost event (no breaking change to the event union)
- `app/src/context/assembly.ts` — SOLE AGENTS.md injector + host-orchestrated memory retrieval
- `app/src/ui/*` — bottom-bar meter, model/thinking chips, palette commands, restore reset-marker
- `app/src/control/spend.ts` — the UNWIRED SpendCeiling (pause-after-exceed)
- `app/src/memory/mcp-memory.ts` — host-side memory client (CLI-over-MCP stance; NOT model-facing)

## Exit Criteria

- [x] T1: persistent session holds ONE Pi session (build-once/reuse; new-conversation = dispose+rebuild with gate re-attached; workspace-change respawn rebinds the gate to the new root); C1 denial-sink decoupled from the per-turn queue; auto-compaction folded in; mechanics a-f green; **A1 verdict = SURVIVES, DEFER NOTHING** ([[pi-gate-survives-mutation]]). `npm test && npm run build && cargo check`.
- [x] T2: context/cost meter (additive-optional event, null-window renders without NaN%) + wired SpendCeiling + manual `/compact` (isBenignCompactError added — raw compact() throws on a too-small session).
- [x] T3: Ph115 restore DISPLAY-ONLY + 'model context reset' marker; no-bypass test asserts ZERO engine sends.
- [x] T4: model switcher (PROCEEDED — T1 verdict cleared it) + local-endpoint capability probe; local default KEPT.
- [x] T5: thinking-level toggle (self-verified; gate-still-intercepts-after-setThinkingLevel).
- [x] T6: nana conventions via `assembly.ts` context seam + AGENTS.md de-dup (noContextFiles:true, host sole injector, rules still injected).
- [x] T7: prompt-templates + skills as palette commands; a template SUBMITS a GATED turn (no-bypass respected).
- [x] T8: host-orchestrated memory retrieval injects to context; NO model-facing memory tool registered; CLI-over-MCP stance documented.
- [x] T9: hosted maxTokens verify → [[hosted-maxtokens-not-a-bug|not a bug]] (a uniform override would be the actual bug); no fix, note recorded.

**Status (2026-07-01 debrief): BUILT + GREEN — all 9 tasks; app/ 456/456 + `npm run build` + `cargo check`; adversarial gate-bypass review 0 defects (2 Low nits fixed inline); host-gate policy byte-unchanged. Phase STAYS ACTIVE — delivery pending the maintainer live-drive (turn-2 denial visible, interrupt-then-continue, restart divergence marker).**

## Constraints (confirmed at plan)

- Host gate BYTE-UNCHANGED + UN-BYPASSABLE across persistence + every mutation — T1 checkpoint proves it; if the gate detaches on a mutation, DEFER that surface; if it can't survive a persistent turn-2, STOP+report (do NOT swap the session out from under the gate).
- C1: decouple the gate denial-sink from the per-turn EventQueue (swap a per-turn queue REFERENCE each turn, don't capture a constant). Compaction is a correctness dependency of the foundation.
- SAFE fallbacks this phase — host-orchestrated memory (A3 down-scope), AGENTS.md/context injection (A4 down-scope); NO memory carve-out, NO systemPromptOverride. Local $0 default KEPT.
- Ph115 restore stays DISPLAY-ONLY; crash-isolation regression named (new-conversation = the recovery).

## Checkpoints

- After T1: STOP + report (the A1 gate-survival verification) BEFORE building any mutating surface (T2/T4/T5).

## Assumptions

- A2 (accept): Ph115 restore stays display-only + a 'model context reset' marker is acceptable UX. If false: gated engine-replay or a different memory model.
- A1/A3/A4 (deferred don't-knows, revisit-open): A1 gate-survives-mutation resolves at the T1 checkpoint; A3 memory carve-out safety deferred (host-orchestrated built); A4 Pi-default-prompt load-bearing deferred (AGENTS.md injection built).

## Notes

Rides umbrella spec `specs/gui-harness-architecture.md` (Ph108-115 precedent) + spec `specs/phase-119-pi-ux-felt-quality-slice.md` (nana:approved). Toolchain: vitest (`npm test`), `npm run build` (tsc --noEmit && vite build), `cargo check` (Rust). Two approach-reviewer + plan-reviewer passes (5/10 → 7/10) folded C1 / C3 / compaction-as-dependency / AGENTS.md de-dup / crash-isolation / workspace-respawn gate-rebind. Pi SDK v0.80.2 named APIs method-level verified at plan.
