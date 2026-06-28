---
title: "Axis 3: Command Palette + Keyboard Control"
aliases: [axis3-command-palette, command-palette, axis-3, keyboard-control, command-registry]
category: decisions
tags: [gui-harness, command-palette, keyboard-shortcuts, axis-3, felt-quality, joy-control, assistant-ui, tauri, phase-113]
parents: [phase-113-felt-quality-build]
created: 2026-06-27
updated: 2026-06-27
source: plan
confidence: high
---

## Context

The GUI harness has axes 1/2/4/5 of the five north-star control/joy axes felt (gate-confirm / one-action revert / streaming chat with tool-call visibility / instant typed-artifact preview — Ph109-111). Axis 3 — "every action is reachable by button, shortcut, or palette search" (`specs/gui-harness-architecture.md:84`, Success Vision) — is the LONE unbuilt axis, deferred since Ph109 (A5: "until dogfood proves weekly use"). Today the app has ZERO keyboard shortcuts and the gate/revert/stop are mouse-only. A daily-driver GUI meant to replace a terminal must be keyboard-competitive. This is a deliberate pivot back to felt-quality after the Ph108-112 security-hardening run.

## Decision

**Build axis 3 as a small PURE command registry + a custom Cmd+K command palette + a keyboard shortcut layer, all dispatching EXISTING actions** (stop/approve/deny/revert/focus-composer) plus the one genuinely-missing action (new-conversation). The registry is the durable core — it outlives the palette UI; the palette and shortcut layer are two thin presenters over it.

- **Hand-rolled, NO `cmdk` dependency.** ~6 static commands don't justify a runtime dep + supply-chain surface in a strict-CSP, sandbox-hardened app; this follows the Ph109 "owned not adopted" ethos (assistant-ui kept; AI Elements skipped).
- **Pure registry first (T1):** an engine-neutral `Command {id,title,keywords[],shortcut?,enabled(ctx),run(ctx)}` + `buildCommands(ctx)`, no React/DOM imports — node-testable, the ctx source the palette + shortcuts both read.
- **Mechanics-only tests; felt-quality ships on maintainer judgment** (Ph59/80 UI carve-out). The live window-drive stays deferred (Ph109-112 precedent).

## Alternatives considered

- **(B) Pair the build with finally running the 4x-deferred live drive as the acceptance bar — REJECTED.** The maintainer chose the fast ship (Option A): build the palette as the bet that makes the loop reach-for-able, rather than gating it on a live-drive entry signal that has slipped every phase 109-112.
- **(C) Adopt the `cmdk` library — REJECTED.** It is the React standard and reduces effort, but adds a runtime dep + supply-chain surface to a sandbox-hardened app and cuts against "owned not adopted"; the subtraction test does not clear it for ~6 static commands.

## Consequences

- **KEY RISK / honest residual — A1 (high): building axis 3 now BETS that supply creates demand.** The spec gates ported features on a "used weekly" dogfood test (`specs/gui-harness-architecture.md:80`) that has NEVER run, because the live drive was deferred 4x. If the palette isn't reached for, that surfaces at the (still-deferred) live drive and Ph114 can deprioritize. The bet, not the evidence, is the basis here — stated honestly.
- **No new privileged host path.** The palette only re-dispatches existing bridge/runtime actions through existing channels. A Ph112-style no-bypass invariant test guards the boundary: the engine-host `HostInbound` union must be UNCHANGED or grow by EXACTLY ONE benign non-gate `reset` member, with no gate/approval message type added or altered (the [[gate-confirm-approve-loop]] verdict-loop core stays UNCHANGED). Inert-render + strict CSP unchanged; command titles render inert (model-influenced file paths).
- **Two felt-safety footguns are task-bound:** bare-Enter must NOT auto-approve a held destructive gate, and single-key shortcuts must NOT fire while the composer (assistant-ui `ComposerPrimitive.Input` — a textarea/contenteditable, not a bare `<input>`) is focused.
- **OUT (a future security phase):** Vercel bash output redaction + cross-platform OS-sandbox (Linux landlock/bwrap + Windows job-objects).

## Source

Phase 113 plan (2026-06-27). Umbrella spec `specs/gui-harness-architecture.md` (nana:approved, Rev 2 — Success Vision's five axes; axis 3 is the unbuilt one). Ledger Phase-113 (all_accept:true, A1-A4). Builds on [[felt-quality-surface]] (Ph109, the axis-defining decision that deferred axis 3 via A5), [[tool-call-visibility-thread]] (Ph110), [[typed-artifact-fidelity]] (Ph111). Joy/control north star is the maintainer's to judge directly (UI carve-out, Ph59/80).
