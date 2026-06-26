---
title: "Phase 109 — Felt-Quality Surface + Branding: drivable surface + the webview↔engine bridge"
aliases: []
category: journal
tags: [gui-harness, assistant-ui, surface, context-assembly, confirming-gate, webview-engine-bridge, felt-quality, tauri, phase-109]
parents: [phase-109-felt-quality-surface]
created: 2026-06-26
updated: 2026-06-26
source: debrief
duration: ~1 session
---

# Phase 109 — Felt-Quality Surface + Branding

## What Happened

- Planned + implemented in one session. Turned Ph108's placeholder `App.tsx` (a literal `<h1>`) into a real, drivable assistant-ui surface wiring the 5-axis felt-quality thesis to Ph108's already-tested engine-neutral reduction. All 6 tasks landed (T6 discovered mid-phase, maintainer-approved, completed same session).
- **A1 spike resolved CLEAN** (T1, the front-loaded risk): `useExternalStoreRuntime` + a custom `convertMessage` bound to `applyEngineEvent`/`reduceEngineEvents` with **zero engine-type reshape** — the AI-SDK-data-stream fallback was never needed. AI Elements skipped in favor of custom owned components ("owned not adopted").
- **Two discovered scope additions** (both maintainer-approved DISCOVERY escape hatches): T3 needed a real host-owned approve-loop, not pure UI (the gate had no held-call resolution path); T6 needed a webview↔engine bridge (the Node-only engine was unreachable from the browser webview — Ph108's "daily loop" had only ever run in Node tests).
- Delivery **ACCEPTED** by the maintainer via this debrief: "I'll do the verification later, anything feels off can be fixed next phase." Phase flagged READY FOR COMPLETION (not auto-flipped; the orchestrator's delivery flow flips the gate after the commit lands).

## Decisions Made

- [[felt-quality-surface|Build the drivable felt-quality surface + minimum context-assembly]] (high) — updated to BUILT outcome
- [[webview-engine-bridge|Rust-spawned Node sidecar + line protocol + BridgeClient-as-EngineAdapter]] (high) — NEW (T6)
- [[gate-confirm-approve-loop|Host-owned ConfirmationBroker + confirmingGate on the setToolCallGate seam]] (high) — NEW (T3)

## Problems Solved

- **Node-only engine unreachable from the webview** — Rust spawns a Node host sidecar over a stdin/stdout JSON line protocol; the webview reaches it only via Tauri IPC, so the capability manifest stays `core:default` + CSP `connect-src 'self'` (no localhost server, no XSS→RCE broadening). Inert-render guard stayed green.
- **CJS bundle of `pi-coding-agent` failed** (`ERR_PACKAGE_PATH_NOT_EXPORTED` — export-map-only) — switched `build:host` to esbuild ESM (`.mjs`); the sidecar starts clean (`{"type":"ready"}`).
- **The gate could ask for confirmation but never resolve it** — a `confirmingGate` turns a confirmable deny into an unresolved `Promise<GateDecision>` (already awaited by every adapter), parked in a `ConfirmationBroker` and resolved on the human verdict. SECURITY: only the literal "requires explicit human confirmation" marker is confirmable — key-store denials ("is denied") stay hard-denied, tested against the real gate.
- **`applyEngineEvent` mutates** → the streaming hook must clone-on-event or React won't re-render (the #1 assistant-ui integration detail).

## Open Questions

- Live end-to-end round-trip (webview → Rust spawn → node sidecar → local model → back) is **UNVERIFIED** — each layer tested independently, not the assembled live drive. Likeliest failure: Rust spawn + `NANA_ENGINE_HOST_JS` env-path resolution inside the real `tauri dev` runtime. Maintainer deferred this to a later launch.
- Real app icon / branding finalization (placeholder kept; maintainer's call).
- Richer artifact pipeline (live tool-results → typed DiffView/TestResults/TerminalOutput) — components built+tested, live wiring minimal (`SurfaceToolCall` drops the result; threading it touches the Ph108 reduction).

## Artifacts Changed

- `app/src/host/` (NEW — `engine-host.ts` + `main.ts`: sidecar + line protocol)
- `app/src/gate/confirm/` (NEW — `broker.ts` + `confirming-gate.ts` + `diff.ts`)
- `app/src/context/` (NEW — `assembly.ts`: AGENTS.md/CLAUDE.md + `.claude/rules/*.md` → per-turn system context, loud-on-missing)
- `app/src/ui/` (NEW — `Thread.tsx`, `chat-runtime.ts`, `chat-binding.ts`, `tool-call-view.tsx`, `gate-confirm.tsx`, `diff-view.tsx`, `artifacts.tsx`, `engine-bridge.ts`)
- `app/src/engine/adapter.ts` (`SendPromptOptions.systemContext`, additive — Vercel native `system:`, Pi `<project-context>` preamble)
- `app/src-tauri/src/lib.rs` (Node-sidecar spawn + `engine_send` command + stdout→`host-message` events)
- `app/src/App.tsx` + `styles.css` (composed dark control-instrument surface; `main.tsx` imports styles)
- `app/package.json` (deps: `@assistant-ui/react`; dev: `esbuild`; scripts: `build:host`, `app`; `dist-host/` gitignored)

## Related

- [[phase-109-felt-quality-surface|Phase 109: Felt-Quality Surface + Branding]] — parent phase
- [[phase-108-gui-harness-v1-thin-slice|Phase 108]] — the engine + rails this surface makes felt

## Health Delta

- App tests 63 → **108** (+45: chat-stream 9, context 5, confirming-gate 7, engine-host-protocol 6, bridge-adapter 7, gate-confirm 5, artifacts-revert 5, app-smoke 1). All green.
- `tsc --noEmit` + `vite build` + `cargo check` all exit 0. ESM host bundle starts clean. inert-render/CSP/capability guard STILL green (boundary unbroadened). No type errors introduced.
- 1 intermittent FLAKY live-model e2e test under concurrency (pre-existing; passes in isolation).

## Retro Check (Phases 100-109)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 recurring (enforce-spec non-md write Ph98, apparatus rmtree Ph102, flaky e2e Ph109 — each one-off) | low |
| 2. Decision Reversals | Ph107 reversed Ph106's dashboard subtraction; Ph105 agent reversed its own "already-covered" prior under evidence — each deliberate, outcome-improving | low |
| 3. User Corrections | Consistent: Ph101 (bug-inject→from-scratch), Ph104 (frontier redirect), Ph107 (dashboard unusable→cockpit), Ph108 (adapter override), Ph109 (A2 directed in + T3/T6 scope) | high |

Recommendations:
- Only 1 high-signal dimension (not systemic). The maintainer's corrections consistently land on the **A-rank (highest-cost) assumption** at the direction gate (A2 here, adapter in Ph108) or as mid-phase scope additions — the gate is working as intended, catching real reframes. Keep front-loading the cheapest-reversible / highest-cost assumption at the gate; the redirections are a feature of the 2-gate model, not thrash.

## Soft Observations / Phase 110 Candidates

- Verify the live bridge round-trip in the actual Tauri window (the maintainer's deferred check); fix the Rust spawn / env-path if off. | Phase 110: live-drive verification | this journal's Open Questions
- Real app icon + branding finalization. | Phase 110 branding pass | Open Questions
- Richer artifact pipeline (live tool-results → typed views); needs threading the tool-result without breaking the Ph108 reduction. | Phase 110 | Open Questions
- Signed/notarized bundle + opt-in auto-update + one-click rollback (folds the A3 keyring bundle-time residual + production host-sidecar bundling — dev spawns `node` directly). | Phase 110+ distribution | [[webview-engine-bridge]]
- Pin/serialize the flaky live e2e tests (retry or non-concurrent) so the suite is deterministic. | Phase 110 test-hygiene | Health Delta
- Command palette (axis 3, deferred A5) — dogfood-driven. | Phase 110+ | ledger Phase-109 A5
- Claude Agent SDK adapter (gated on an API key) — still deferred. | future | [[second-adapter-vercel-ai-sdk]]
- Daily-driver dogfood on the live repo (now genuinely possible once the launch is verified). | Phase 110 dogfood | Open Questions
