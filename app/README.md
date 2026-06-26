# Nana Dev-Harness (`app/`)

GUI-primary, model-agnostic desktop dev harness — Phase 108 v1 thin slice
([[engine-adapter-in-process-gate]], spec `specs/gui-harness-architecture.md`).

## Architecture (the load-bearing invariant)

A host can own a **pre-execution security gate** (deny/modify a destructive tool
call *before* its side effects) **only if the agent loop runs in the host's own
process**. So the swappable boundary is the app-owned **`EngineAdapter`**
interface — *not* a wire protocol or external server. The engine is embedded;
the gate wraps its tool dispatch; swapping engines is a new adapter behind a
fixed internal interface.

- `src/engine/` — the `EngineAdapter` interface + canonical engine-neutral types
  (`NormalizedToolCall`, `GateDecision`, `ToolCallGate`, `EngineEvent`) and the
  `NoopAdapter` reference. Pi (T3) and Claude Agent SDK (T7) adapters land here.
- `src/gate/` — the in-process pre-execution gate + checkpoint layer (T3, T5).
- `src/memory/` — MCP stdio mount of the existing Python memory server (T4).
- `src/ui/` — assistant-ui custom runtime + AI Elements surface (T6).
- `src/control/` — spend ceiling, hard interrupt, tool-call normalization (T8).
- `src-tauri/` — the thin Rust shell: window, strict CSP, audited capability
  manifest, keyring-rs key custody (T2).

## Toolchain

- **Node 20+** — frontend + the engine/adapter/test layer (Vitest, node env).
- **Rust + Tauri CLI** — required to build/launch the desktop shell and to
  compile the `keyring-rs` key custody (T2). **Not yet installed** as of T1.
  Until it lands, `src-tauri/` is complete-on-disk but uncompiled. T1's binding
  contract (`npm run build && npm test -- adapter-contract`) is pure TS and does
  not require Rust.

## Commands

```bash
npm install
npm run build        # tsc --noEmit && vite build  (frontend; no Rust)
npm test             # vitest run
npm test -- adapter-contract   # the T1 contract test

# after the Rust/Tauri toolchain is installed:
npm install -D @tauri-apps/cli@2 @tauri-apps/api@2
npm run tauri icon <path-to-1024px.png>   # generate src-tauri/icons/*
npm run tauri build  # signed desktop bundle
npm run tauri dev    # launch the shell against the dev server
```
