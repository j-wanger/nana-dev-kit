---
title: "Codebase Snapshot — 2026-06-30 (Phase 115 DELIVERED)"
aliases: [2026-06-30-snapshot]
category: status
tags: [snapshot, phase-115, conversation-memory, gui-harness, app]
parents: [phase-115-conversation-memory]
created: 2026-06-30
updated: 2026-06-30
source: debrief
---

# Codebase Snapshot — 2026-06-30

Captured at the Phase 115 (Conversation memory — persist + restore the chat thread) debrief. BUILT + adversarially reviewed; READY FOR COMPLETION (delivery gate flips after commit). Same-day as the Phase 114 debrief.

## App subsystem (`app/`, the GUI dev-harness — the focus of this phase)
- `app/src/`: 52 `.ts`/`.tsx` source files. Phase 115 addition: **`ui/conversation-store.ts` (NEW pure module)** — `redactForPersist(UiMessage)→UiMessage` (redacts ALL string leaves incl. nested tool output + `details.diff`, STRIPS the write `content` body → `'[N bytes]'`, finalizes `done:false` + clamps tool `called`→`done`) + `save`/`load`/`clear` over per-workspace localStorage (keyed by `ready.workspaceRoot`, bound = last-N-turns + byte backstop prune-oldest, fail-soft `setItem` prune-retry-then-SKIP). `ui/chat-runtime.ts` gained an OPTIONAL workspace-source param + persist-on-settle + first-ready restore + onWorkspace SWAP + clear-on-newConversation; `App.tsx` passes the bridge's workspace interface. Restore/swap is DISPLAY-ONLY (zero engine sends).
- `app/tests/`: 54 Vitest files — **374 tests green** (Ph114 343 → Ph115 +31: conversation-store 22, conversation-persist 5, workspace-swap 4).
- Build status: `tsc --noEmit` clean; `cd app && npm run build` (tsc + vite) exit 0; `cd app/src-tauri && cargo check` exit 0.
- The host gate + inert-render + redact rail + no-bypass invariant + stdin/stdout line protocol UNCHANGED (no engine types across the boundary; the store is NOT gate-load-bearing).

## Kit (host project)
- Shell/Markdown/Python scaffolding kit (260+ files). `make test` (28 scripts) + `make eval` (50 scenarios) unaffected by this phase (app-only changes). v0.5.0.
- Toolchain: kit = GNU Make + bash + jq; app = Vite + Tauri 2 (Rust 1.96.0) + Vitest + TypeScript + npm; LOCAL OpenAI-compatible model backend; Python MCP memory server mounted unchanged.

## Recent Commits (last 5)
- `dbe4965` Phase 114: Pi as the default daily engine (good tools) + Rust-atomic workspace picker
- `3309b44` Dogfood hotfix: Vercel step cap (#1) + working/error indicators (#4/#5)
- `776167a` Phase 113: Felt-Quality Build — Axis 3 (command palette + keyboard control)
- `7b63ce8` Phase 112: OS-sandbox bash filesystem isolation (seatbelt) — close the Ph111 string-gating residual
- `1556ee3` Phase 111: Typed Artifact Fidelity + host-gate out-of-workspace hardening

## Notes
- Phase 115 work is NOT yet committed (this debrief precedes the delivery commit; gate-log `delivery=pending`, D3 flips on commit). Branch `main`.
- HONEST RESIDUALS (accepted): A1 at-rest (`redactSecrets` is pattern-based, misses short/plaintext secrets; the content-strip is write-only — edit `new_string` redacted-not-stripped); no cross-workspace localStorage LRU past ~15-20 large active workspaces (fail-soft skip); the live restart-restore + native swap round-trip is live-drive-only (Tauri runtime). The adversarial review caught + fixed 6 incl. 1 HIGH (byte-backstop could overwrite good history with `[]`).
- Detailed module/dependency maps: see `_ARCHITECTURE.md` (refreshed 2026-06-30). This snapshot summarizes the app-subsystem delta only.
