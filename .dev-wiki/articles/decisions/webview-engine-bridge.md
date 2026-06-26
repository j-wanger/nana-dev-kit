---
title: "Bridge the Tauri webview to the Node-only engine via a Rust-spawned Node sidecar + a line protocol"
aliases: [webview-engine-bridge, engine-bridge, node-sidecar-bridge, drivable-bridge]
category: decisions
tags: [gui-harness, tauri, bridge, node-sidecar, line-protocol, engine-adapter, csp, capability-manifest, phase-109]
parents: [phase-109-felt-quality-surface]
created: 2026-06-26
updated: 2026-06-26
source: debrief
confidence: high
---

## Context

Phase 108 built the engine (Pi/gate/memory/checkpoint/context) as **Node-only** code and proved the "running daily loop" in **Node tests** — never through the GUI. The Tauri webview is a browser context: it cannot `require` the Node engine, so the placeholder surface had no path to actually drive a model. The harness compiled and the window launched, but nothing the user typed reached the engine. Making it genuinely drivable was the missing seam — discovered mid-Phase-109 and folded in (maintainer-approved: "fold a minimal bridge in"), retroactively logged as task T6.

The hard constraint: do it **without** broadening the security boundary. Phase 108's inert-render guard rests on the webview capability manifest being `core:default` and the CSP `connect-src` being `'self'` — a localhost engine server (the naive bridge) would force `connect-src localhost`, and giving the webview shell/fs capability would reintroduce the XSS→RCE class the spec warns about.

## Decision

**A Node engine-HOST sidecar that the RUST shell spawns, talking a stdin/stdout JSON line protocol; the webview reaches it only through Tauri IPC.**

- **Host sidecar** (`src/host/engine-host.ts` + `src/host/main.ts`): a transport-agnostic `EngineHost` that composes context-assembly + the engine adapter + `confirmingGate` + the `ConfirmationBroker` + revert behind a JSON line protocol — **in:** `prompt` / `gate-verdict` / `revert` / `interrupt`; **out:** `engine-event` / `gate-pending` / `revert-result` / `ready` / `error`.
- **Rust shell** (`src-tauri/src/lib.rs`): spawns the node sidecar and proxies it — an `engine_send` `#[tauri::command]` writes to the sidecar's stdin; the sidecar's stdout is forwarded as `host-message` Tauri events.
- **Webview `BridgeClient`** (`src/ui/engine-bridge.ts`): implements the `EngineAdapter` interface via Tauri `invoke` + `listen`, so `useChatRuntime` and every view stay **unchanged** (the bridge is a drop-in adapter; the gate is host-side, so `setToolCallGate` is a no-op there). Adds `onGatePending`/`respondGate` (T3) + `revert` (T4).
- **Because RUST does the spawning**, the webview never opens a socket — the capability manifest stays `core:default` and CSP `connect-src` stays `'self'`. No localhost server, no shell/fs capability granted to the webview. The inert-render guard holds.
- **Build:** an esbuild **ESM** bundle (`build:host` → `dist-host/engine-host.mjs`); CJS failed because `@earendil-works/pi-coding-agent` is export-map-only (`ERR_PACKAGE_PATH_NOT_EXPORTED`). `npm run app` builds the host + sets `NANA_ENGINE_HOST_JS` + runs `tauri dev`. Graceful: with no env var the window still launches (just not drivable). `dist-host/` is gitignored.

## Alternatives considered

- **Localhost engine HTTP server the webview calls (rejected):** the obvious bridge, but it forces CSP `connect-src localhost` and a long-lived server surface — broadens exactly the boundary Ph108's guard protects.
- **Give the webview Node/shell capability (rejected):** reintroduces the GUI XSS→RCE class; the whole point of the in-process gate is that the model side can't reach the host.
- **Embed the engine in the webview (impossible):** the engine is Node-only (`pi-coding-agent`, MCP stdio, child processes) — it cannot run in a browser context.

## Consequences

- The harness is now **genuinely drivable** end-to-end in principle; the live prompt→window round-trip is the maintainer's deferred delivery-time launch check.
- **UNVERIFIED:** the assembled live drive (webview → Rust spawn → node sidecar → local model → back). Each layer is tested independently (host starts + emits `ready`, the protocol + `BridgeClient` are unit-tested, `cargo check` passes, the bundle compiles) but not as one running stack. Likeliest failure point: the Rust spawn + `NANA_ENGINE_HOST_JS` env-path resolution inside the real `tauri dev` runtime.
- Production bundling is now a Phase-110 item: dev spawns `node` directly, so a signed/notarized bundle must bundle the host sidecar (folds in with the A3 keyring bundle-time residual).
- The security boundary is **unbroadened** — inert-render/CSP/capability guard stayed green.

## Source

Phase 109 debrief (2026-06-26). Discovered mid-phase, maintainer-approved ("fold a minimal bridge in"), completed same session (T6). Built on [[engine-adapter-in-process-gate]] (the engine-neutral `EngineAdapter`) and [[felt-quality-surface]] (the drivable-surface objective). Sibling: [[gate-confirm-approve-loop]] (the host-side broker the sidecar composes).
