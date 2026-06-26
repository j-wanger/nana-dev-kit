---
title: "Phase 108 — GUI Dev-Harness v1 Thin Slice: BUILT (all 8 tasks, 14/14 exit criteria, delivery pending)"
aliases: []
category: journal
tags: [gui-harness, pivot, tauri, engine-adapter, security-gate, pi-sdk, vercel-ai-sdk, mcp-memory, keyring-rs, phase-108]
parents: [phase-108-gui-harness-v1-thin-slice]
created: 2026-06-26
updated: 2026-06-26
source: debrief
duration: unknown
---

# Phase 108 — GUI Dev-Harness v1 Thin Slice: BUILT

## What Happened

THE PIVOT executed: nana-dev-kit got a new top-level `app/` directory — a Tauri (Rust) desktop shell embedding a model-agnostic agent engine IN-PROCESS behind the app-owned `EngineAdapter` interface, with the security gate at the in-process tool-call site. Built security/gate FIRST per the locked spec. All 8 tasks (T1–T8) completed; the Rust toolchain (1.96.0) was installed mid-session (confirmed with the maintainer) as a prerequisite for the Tauri shell + keyring-rs.

- **A1 EMPIRICALLY validated, not inferred:** a real local model (Qwen3.6-35B via llama.cpp @ localhost:8080) attempted `bash rm` AND an out-of-workspace write through BOTH adapters; the in-process gate denied both before execution. No STOP-and-escalate.
- **Provider pivot (research-driven):** subscription-OAuth ruled OUT — Anthropic prohibits `sk-ant-oat` in third-party harnesses and meters it per-token (no Max quota), so a custom harness pays per-token either way. Default = a LOCAL OpenAI-compatible backend (no key, no billing, no ToS exposure).
- **Second-adapter substitution:** the spec named the Claude Agent SDK, but it is Anthropic-API-key-only and can't drive the local backend. Maintainer chose the Vercel AI SDK (the spec's own approved fallback, OpenAI-compatible) via AskUserQuestion — engine-neutrality proven live (one `createHostGate`, two engines both deny a real `bash rm`).
- The Tauri Rust shell COMPILES (`cargo build` exit 0, 23.5MB binary); `tsc --noEmit` + `vite build` + `cargo build` all exit 0; 63/63 tests green (incl. live Pi round-trip, live Vercel second-adapter, live MCP memory round-trip).

## Decisions Made

- [[provider-defaults-to-local-model|Provider defaults to a local OpenAI-compatible model; Claude subscription-OAuth ruled out]] (high) — NEW
- [[second-adapter-vercel-ai-sdk|Second adapter = Vercel AI SDK (substituted for the spec's Claude Agent SDK)]] (high; USER OVERRIDE) — NEW
- [[engine-adapter-in-process-gate]] (high) — CONFIRMED: A1 (Pi gate un-bypassable) empirically validated; A2 (MCP server ports as-is) validated; A3 (keyring-rs) resolved→accept.

## Problems Solved

- **MCP memory round-trip failure** — a MOUNT-side bug, exactly A2's predicted disposition (server UNTOUCHED): FastMCP wraps a list return as `structuredContent.result`; the mount now unwraps it. Fix the mount, not the server.
- **A3 keyring don't-know resolved** — keyring-rs 3.6.3 (apple-native) round-trips the REAL macOS Keychain (set→get→delete one-process, no prompt) via a standalone `keyhelper` crate; the agent file-read tool is denied the key-store path; key-shaped strings redacted from logs. No credential-helper fallback needed at the dev/unsigned level.

## Open Questions

- Claude Agent SDK adapter (Claude-fidelity path) — needs an Anthropic API key; deferred to Phase 109. Its `canUseTool`→host-gate mapping is deterministically testable now.
- A3 residual: keyring behavior inside a SIGNED/NOTARIZED Tauri bundle (entitlements/ACL) — verifies only at bundle time; credential-helper fallback stays the contingency. Fold into the bundle/notarization work.

## Artifacts Changed

- `app/**` (NEW: Tauri Rust shell `app/src-tauri/` + standalone `keyhelper` crate; TS/React surface `app/src/` — engine/ gate/ memory/ security/ fs/ ui/ control/; 15 test files `app/tests/`)
- `.dev-wiki/assumption-ledger.md` (Phase-108 revisit-status filled: A1/A2/A3/A4 all `held` — none bit)
- `.dev-wiki/_ARCHITECTURE.md` (new `app/` subsystem + Development Toolchain: Node + Rust + local model backend)
- `specs/gui-harness-architecture.md` (governing spec, read-only reference)

## Assumption-Ledger Revisit (Phase 108)

A1/A2/A3/A4 → all `held` (none bit). A3 (keyring-rs deferred don't-know) resolved favorably → accept; one NEW bundle-time residual routed to Blockers/Phase-109, not a bite of the assumption as stated. `--revisit 108` exit 0.

## Related

- [[phase-108-gui-harness-v1-thin-slice|Phase 108]] — parent phase

## Soft Observations / Phase N+1 Candidates

- Claude Agent SDK adapter (Claude-fidelity path) | strong Phase-109 candidate once an Anthropic API key exists; `canUseTool`→host-gate mapping deterministically testable now | this journal + tasks.md discovered list
- Full felt surface (assistant-ui visuals, real branding/icon, polish) | a dedicated "felt-quality pass" phase | the joy/sense-of-control north star, UNMEASURABLE in-kit (Ph59/80)
- Signed/notarized bundle + opt-in auto-update + one-click rollback | a packaging/distribution phase (folds in the A3 bundle-time residual) | spec constraint not yet built
- Daily-driver dogfood on the live repo | now UNBLOCKED (all security rails pass) — a deliberate first-week trial tests the joy/control thesis | Phase-108 exit criteria
