---
title: "Phase 113: Felt-Quality Build (command palette / axis 3 + UX quick-wins)"
aliases: [phase-113, felt-quality-build, command-palette, axis-3]
category: phases
tags: [gui, surface, felt-quality, command-palette, axis-3, keyboard-shortcuts, assistant-ui, tauri, dogfood]
parents: [phase-109-felt-quality-surface, phase-110-dogfood-ux-pass]
created: 2026-06-27
updated: 2026-06-27
source: plan
status: active
scope: ["app/src/ui/**", "app/src/App.tsx", "app/src/styles.css", "app/src/host/engine-host.ts", "app/tests/**"]
entry_criteria: "Phase 112 delivered + accepted (OS-sandbox bash fs isolation; commit 7b63ce8; app suite 274 green; tsc + npm run build + cargo check exit 0). The GUI harness has axes 1/2/4/5 felt (gate-confirm / one-action revert / streaming chat with tool visibility / instant artifact preview). Axis 3 (every action reachable by button, shortcut, or palette search) is the lone DEFERRED felt-quality axis — deferred since Ph109 (A5) 'until dogfood proves weekly use.' A deliberate pivot back to felt-quality from the Ph108-112 security-hardening run."
exit_criteria: "Cmd+K opens a custom command palette that filters by query and dispatches the EXISTING action surface (stop/approve/deny/revert/focus-composer/new-conversation) by search + keyboard shortcut, approve/deny present ONLY when a gate is held; a pure node-testable command registry is the durable core; a no-bypass invariant test asserts the engine-host HostInbound union is UNCHANGED or grew by EXACTLY ONE benign non-gate `reset` (no gate/approval type added/altered); bare-Enter never auto-approves a held destructive gate; single-key shortcuts never fire while the composer (textarea/contenteditable) is focused; command titles render inert; inert-render/CSP/gate-confirm NO regression; full app suite green + npm run build + cargo check exit 0; + a focused adversarial pre-commit review's confirmed findings fixed. Mechanics tested only (Ph59/80 carve-out — felt-quality + the live window-drive ship on maintainer judgment)."
---

# Phase 113: Felt-Quality Build (command palette / axis 3 + UX quick-wins)

## Objective

Advance the felt joy + sense-of-control north star with a felt-quality build phase — a deliberate pivot back to felt-quality after the Ph108-112 security-hardening run. Named candidate: the **command palette** (the deferred "axis 3" felt-quality axis — "every action is reachable by button, shortcut, or palette search"). Plus UX quick-wins surfaced by dogfooding.

## Scope

Files and modules likely affected (confirm at /dev-plan):
- `app/src/ui/**` — a new palette component + the action registry it drives; keyboard-shortcut wiring
- `app/src/App.tsx` — mount the palette into `HarnessSurface`; wire it to the existing action surface (gate approve/deny, revert, send/stop)
- `app/src/styles.css` — palette styling (the maintainer's felt-quality call; use the `frontend-design` skill)
- `app/tests/**` — mechanics tests (palette search/select dispatches the right action; inert-render regression)

**Likely OUT (confirm at /dev-plan):** cross-platform OS-sandbox (Linux/Windows — Ph113-OUT carry-forward security item, separate phase); Vercel bash output redaction (security, separate); signed/notarized bundle + A3 keyring residual + rollback; Claude Agent SDK adapter; structured TestResults.

## Exit Criteria

- [ ] A pure, node-testable command registry (`buildCommands(ctx)`) gates approve/deny on `gateHeld`, stop on `isRunning`, revert on `revertiblePaths`, and dispatches `run()` to the matching ctx callback (T1)
- [ ] `useChatRuntime` surfaces `isRunning/stop/newConversation/focusComposer`; new-conversation aborts in-flight + clears messages/artifacts/reverts (host-side reset carries NO gate/approval semantics) (T2)
- [ ] A custom Cmd+K command palette filters by title/keywords, lists only enabled commands, runs on Enter / closes on Esc, and renders command titles INERT (T3)
- [ ] A keyboard shortcut layer dispatches chords + Cmd+K + Esc/Cmd+. = stop; bare-Enter does NOT auto-approve a held destructive gate; single-key shortcuts do NOT fire while a textarea/contenteditable composer is focused (T4)
- [ ] App.tsx wires the palette + shortcuts to REAL commands from live runtime/gate/revert state; the no-bypass invariant asserts the engine-host `HostInbound` union is unchanged or +1 benign non-gate `reset` (no gate/approval type added/altered) (T5)
- [ ] Full app suite green + `npm run build` + `cargo check` exit 0; inert-render/CSP/gate-confirm NO regression; focused adversarial pre-commit review's confirmed findings fixed; residuals documented; active-phase.md → BUILT (T6)
- [ ] Mechanics-only; the felt-quality / joy + control read + the live window-drive are the maintainer's deferred judgment (Ph59/80 carve-out, Ph109-112 precedent)

## Constraints (to confirm at /dev-plan)

- **Owned not adopted (the surface ethos):** Ph109 skipped AI Elements for custom owned components; the palette likely follows (custom vs `cmdk` is an open design question).
- **Preserve inert-render + strict CSP + the gate verdict-loop core.** A felt-quality/UI phase must not weaken the security rails (the standing Ph109-112 invariant). The palette dispatches existing actions; it adds no new privileged channel.
- **Scope guard (spec):** "every additional ported feature must clear a 'used weekly' test." Axis 3 was deferred precisely on this guard — confirm the dogfood signal exists, or treat the palette as the thing that makes the daily loop reach-for-able.

## Checkpoints

- At delivery: the maintainer drives the live window and judges felt-quality / joy + control (the carve-out). NOTE: this live window-drive has been DEFERRED every phase 109-112 — Phase 113 may want it as a real entry signal so the palette is built on dogfood evidence, not ahead of it (the Ph109→110 "components built ahead of the data" trap).

## Assumptions (to surface at /dev-plan direction gate)

- Whether axis 3's "used weekly" precondition is met (the live drive that would surface it has been deferred 4 phases) — or whether the palette IS the bet that makes the loop reach-for-able.
- Palette scope = existing action surface only, vs also navigation/provider-switch/new-session.

## Notes

Umbrella spec: `specs/gui-harness-architecture.md` (nana:approved, Rev 2) — its **Success Vision** enumerates the **five control/joy axes**; axis 3 ("every action is reachable by button, shortcut, or palette search") is the one not yet built. Built on [[felt-quality-surface]] (Ph109, which deferred axis 3 via A5 "until dogfood proves weekly use") and [[tool-call-visibility-thread]] (Ph110). No separate phase spec — rides the umbrella ADR (Ph108-112 precedent). Use the `frontend-design` skill for aesthetic direction.

**Felt-quality axes status (from the spec Success Vision + [[felt-quality-surface]] decision):**
- Axis 1 — preview-and-approve (gate-hold confirm dialog + diff): DONE (Ph109 T3, [[gate-confirm-approve-loop]])
- Axis 2 — one-action rewind (revert → `CheckpointStore.revert`): DONE (Ph109)
- Axis 3 — everything-reachable (button / shortcut / palette search): **DEFERRED → this phase**
- Axis 4 — visible streaming + ambient per-task status (chat + tool-call visibility): DONE (Ph109 + Ph110 enrichment)
- Axis 5 — instant artifact preview (diff/test/terminal panel): DONE (Ph109 + Ph110/111 typed fidelity)

**Mount points (for task drafting):** `App.tsx` `HarnessSurface` (composes Thread + side panels + gate overlay); the action surface lives in `ui/engine-bridge.ts` (`respondGate`, `revert`, `interrupt`/abort via `sendPrompt` signal) + `ui/chat-runtime.ts` (`onNew`/`onCancel`); `Thread.tsx` owns the composer (Send/Stop). No keyboard-shortcut infrastructure exists yet (grep: only `abort` event listeners). `ui/index.ts` is the pure-export barrel.
