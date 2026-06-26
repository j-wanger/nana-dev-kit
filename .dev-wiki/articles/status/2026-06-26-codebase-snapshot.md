---
title: "Codebase Snapshot — 2026-06-26 (Phase 108 BUILT)"
aliases: []
category: status
tags: [snapshot, phase-108, gui-harness, app]
created: 2026-06-26
updated: 2026-06-26
source: debrief
---

# Codebase Snapshot — 2026-06-26

Taken at the Phase 108 debrief (GUI Dev-Harness v1 Thin Slice — BUILT, delivery gate pending).

## File Metrics

- NEW top-level `app/` subsystem (Phase 108 — the pivot): 28 TS/TSX source files under `app/src/`, 15 Vitest test files under `app/tests/` (63 tests), a Tauri Rust shell `app/src-tauri/` (lib.rs + main.rs + standalone `keyhelper/` crate), capability manifest + strict-CSP `tauri.conf.json`.
- Kit (unchanged this phase): 18 `.sh` hook templates, 33 bash test scripts (`make test`), 50 eval scenarios, the vendored Python MCP memory server (UNTOUCHED, mounted as-is by the app).

## Module Structure (new this phase)

- `app/src/engine/` — EngineAdapter interface + canonical types + Noop/Pi/Vercel adapters + normalize + shared event-queue.
- `app/src/gate/` — host-gate (single chokepoint) + Pi gate-bridge + checkpoint/external-mod file rails.
- `app/src/memory/` — MCP stdio mount of the Python memory server.
- `app/src/security/` — secret-deny-list + redact + keychain accessor.
- `app/src/fs/`, `app/src/ui/`, `app/src/control/` — agent-file-read tool; inert renderer + engine→surface runtime + CSP; spend ceiling + ≤2s hard interrupt.
- `app/src-tauri/` — Tauri 2 Rust shell + `keyhelper/` keyring-rs custody crate.

## Dependency Versions (app)

- Runtime: `@earendil-works/pi-coding-agent`, `@modelcontextprotocol/sdk`, `ai`, `@ai-sdk/openai-compatible`, `react`/`react-dom`.
- Dev: `vite`, `vitest`, `typescript`, `jsdom`, `@tauri-apps/cli`, `@tauri-apps/api`.
- Rust: `tauri` 2, `keyring` 3 (apple-native); toolchain Rust 1.96.0 (installed this session).
- Model backend (default): a LOCAL OpenAI-compatible server (e.g. llama.cpp); Console API key optional; subscription-OAuth ruled out.

## Test / Build Status

- `app`: 63/63 Vitest tests green (incl. live Pi round-trip, live Vercel second-adapter, live MCP memory round-trip); `tsc --noEmit` + `vite build` + `cargo build` all exit 0 (Tauri binary 23.5MB).
- Kit: `make test` / `make eval` unchanged (no kit-side change this phase beyond `.dev-wiki/` + `specs/`).
- Assumption ledger: `--revisit 108` exit 0; `--schema` + `--append-only` exit 0.

## Recent Commits

```
9804e44 Phase 107: Decisioning Cockpit (dashboard-as-primary gate) — DELIVERED + ACCEPTED
33c32e8 Fix py-review Stop hook: gate on the live git diff, not the session transcript
0e6607c Phase 106: Project-State Dashboard + Act-from-Page Decision Gate — DELIVERED + ACCEPTED
a3657e6 Phase 105: Code-Retrieval Adopt-Scout — PLANNING-STAGE NULL, DELIVERED + ACCEPTED
4525f30 Phase 104: Emerging-Agent-Tooling Landscape Survey — DELIVERED + ACCEPTED
```

(Phase 108 work not yet committed — delivery gate pending.)
