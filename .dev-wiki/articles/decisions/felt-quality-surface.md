---
title: "Build the drivable felt-quality surface (assistant-ui + AI Elements) bound to the engine-neutral reduction, plus the minimum context-assembly seam"
aliases: [felt-quality-surface, phase-109-surface, drivable-surface, surface-pass]
category: decisions
tags: [gui-harness, assistant-ui, ai-elements, surface, context-assembly, felt-quality, joy-control, tauri, phase-109]
parents: [phase-109-felt-quality-surface]
created: 2026-06-26
updated: 2026-06-26
source: debrief
confidence: high
---

## Context

Phase 108 delivered the engine + security rails of the GUI pivot and proved them headlessly (63/63 tests — gate deny/modify/confirm, `CheckpointStore` revert, the engine-neutral event reduction, tool-call normalization). But it deliberately deferred the **surface** as the UI carve-out: `app/src/App.tsx` is a literal placeholder `<h1>`, assistant-ui and AI Elements are not installed, and there is no context-assembly layer. The pivot's whole thesis — felt **joy + sense of control** — is unjudgeable until there's a real surface to drive. So "is it pleasant" and "dogfood it" are both blocked on building the surface first.

The architecture spec (`specs/gui-harness-architecture.md`, Rev 2) already pins the surface: assistant-ui (custom runtime → the engine adapter) + Vercel AI Elements' dev components (Terminal/FileTree/TestResults/diff), with the Success Vision enumerating **5 control/joy axes** (preview-and-approve, one-action rewind, everything-reachable, visible streaming, instant artifact preview). The mechanics behind all 5 exist; the UI for none does.

## Decision

**Phase 109 = build the minimum drivable surface that makes Phase 108's rails felt, bound to the existing engine-neutral `runtime.ts` reduction — plus a minimum context-assembly seam so the harness isn't project-blind.** Mechanics tested; felt-quality/joy ships on the maintainer's judgment at delivery (Ph59/80 carve-out; the north star is his to judge directly).

- **Surface, minimum-first (A5):** streaming chat (axis 4, the core) · gate-hold blocking confirm dialog + diff (axis 1 — makes the security thesis felt) · AI Elements diff/CodeBlock + TestResults (axis 5) · one-action revert button → `CheckpointStore.revert` (axis 2). **Defer** the command palette + rich shortcuts (axis 3) until dogfood proves weekly use (the spec's own scope guard).
- **Minimum context-assembly (A2, maintainer-directed):** the app assembles the active workspace's `AGENTS.md`/`CLAUDE.md` + `.claude/rules/*.md` into the engine's per-turn system context; loud-on-missing. The porting-matrix item "context loader → rebuilt as app code," at a minimum-viable level — not the full dev-wiki/memory-search assembly.
- **Branding + launch:** real app icon/identity (replace the placeholder); actually build + **launch** the Tauri window (criterion #1 moves compile-proven → launch-proven).
- **Integration spike front-loaded (A1):** T1 binds a custom runtime to the existing `applyEngineEvent`/`reduceEngineEvents` reduction. If it forces reshaping Ph108's tested engine types → STOP, fall to AI-SDK-data-stream-shape binding; never reshape the proven engine-neutral types.

## Alternatives considered

- **Context-blind v1, context-assembly later (my recommendation — REJECTED by the maintainer):** fastest path to a drivable surface, dogfood reveals what context needs porting. Maintainer judged a project-blind first dogfood an unfair felt-read → context-assembly moved into Phase 109.
- **All 5 axes incl. command palette in v1 (rejected):** more complete, but runs ahead of the spec's "used weekly" scope guard before any measurement.
- **Claude Agent SDK adapter / signed bundle as Phase 109 (deferred):** engine breadth (gated on an API key) and distribution hardening are both "later by subtraction" — premature before the daily loop is shown drivable + worth distributing.

## Consequences

- Tests assert **mechanics only**; there is no honest in-kit felt measure (A3). The delivery gate is a human judgment, consistent with Phase 107/108.
- The new surface MUST preserve T6's inert-render + strict CSP — a regression reintroduces the GUI XSS→RCE class.
- Unblocks the daily-driver dogfood (Phase 110+) once the surface is drivable.

## Outcome (BUILT 2026-06-26)

Delivered in one session, all axes 4/1/5/2 wired; app tests 63→108 green, tsc+vite+cargo check all exit 0. **A1 resolved CLEAN** (the front-loaded spike): `useExternalStoreRuntime` + a custom `convertMessage` bound to the existing reduction with **zero engine-type reshape** — no fallback needed. AI Elements was skipped in favor of custom owned components ("owned not adopted"). Two discovered, maintainer-approved scope additions earned their own decisions:

- **[[gate-confirm-approve-loop]]** (T3) — axis 1 needed a real host-owned `ConfirmationBroker` + `confirmingGate`, not pure UI (the gate had no held-call resolution path); constraint #4 relaxed "UI-only" → "UI + host broker; gate CORE unchanged."
- **[[webview-engine-bridge]]** (T6) — the Node-only engine was unreachable from the webview, so Ph108's "daily loop" had never run through the GUI; a Rust-spawned Node sidecar + line protocol + `BridgeClient`-as-`EngineAdapter` makes it drivable while keeping the webview manifest `core:default` + CSP `connect-src 'self'`.

The live end-to-end round-trip is the maintainer's deferred delivery-time launch check (delivery accepted with "I'll do the verification later, anything feels off can be fixed next phase"). Real app icon/branding finalization also deferred to the maintainer's call. Phase READY FOR COMPLETION.

## Source

Phase 109 plan (2026-06-26). Umbrella spec `specs/gui-harness-architecture.md` Rev 2. Ledger Phase-109 (all_accept: false; A2 reject→revised). Built on [[engine-adapter-in-process-gate]]. Joy/control north star is the maintainer's to judge directly (UI carve-out, Ph59/80).
