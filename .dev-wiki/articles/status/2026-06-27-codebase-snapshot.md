---
title: "Codebase Snapshot — 2026-06-27 (Phase 110 BUILT)"
aliases: [2026-06-27-snapshot]
category: status
tags: [snapshot, phase-110, gui-harness, app]
parents: [phase-110-dogfood-ux-pass]
created: 2026-06-27
updated: 2026-06-27
source: debrief
---

# Codebase Snapshot — 2026-06-27

Captured at the Phase 110 (Dogfood UX Pass) debrief. BUILT + adversarially reviewed; READY FOR COMPLETION (delivery gate flips after commit).

## App subsystem (`app/`, the GUI dev-harness — the focus of this phase)
- `app/src/`: 43 `.ts`/`.tsx` source files. Phase 110 additions: `ui/artifact-feed.ts` (NEW pure router), additive `tool-progress` EngineEvent variant (`engine/types.ts`), `extractToolText` boundary normalization (`engine/pi/pi-adapter.ts`), `redact.ts` rework (`security/`), `useChatRuntime`→`{runtime,artifacts}` (`ui/chat-runtime.ts`), `ArtifactPanel` (`ui/artifacts.tsx` + `App.tsx`).
- `app/tests/`: 31 Vitest files — **157 tests green** (Ph108 63 → Ph109 108 → Ph110 +49; new: pi-event-mapping, tool-visibility, artifact-feed, artifact-panel, tool-visibility-e2e, security/redact, branding/icon). 1 flaky live e2e (`provider-roundtrip`, model non-determinism, passes on retry → Ph111).
- Build status: `tsc --noEmit` clean; `cd app && npm run build` (tsc + vite) exit 0; `cd app/src-tauri && cargo check` exit 0.
- Branding: `app/src-tauri/icons/**` regenerated from `app/assets/icon-source.png` (zlib-PNG Nana mark; icon.png hash 96308f3b→7045a15d ≠ stock placeholder).

## Kit (host project)
- Shell/Markdown/Python scaffolding kit (260+ files). `make test` (28 scripts) + `make eval` (50 scenarios) unaffected by this phase (app-only changes). v0.5.0.
- Toolchain: kit = GNU Make + bash + jq; app = Vite + Tauri 2 (Rust 1.96.0) + Vitest + TypeScript + npm; LOCAL OpenAI-compatible model backend; Python MCP memory server mounted unchanged.

## Recent Commits (last 5)
- `16c6adf` Phase 109 follow-up: launch fix + first dogfood UX quick-wins
- `a78f1f5` Phase 109: Felt-Quality Surface + Branding — DELIVERED + ACCEPTED (live verification deferred)
- `b4244d3` Phase 108: GUI Dev-Harness v1 Thin Slice — DELIVERED + ACCEPTED
- `9804e44` Phase 107: Decisioning Cockpit (dashboard-as-primary gate) — DELIVERED + ACCEPTED
- `33c32e8` Fix py-review Stop hook: gate on the live git diff, not the session transcript

## Notes
- Phase 110 work is NOT yet committed (this debrief precedes the delivery commit; gate-log `delivery=pending`, D3 flips on commit). Branch `main`.
- Detailed module/dependency maps: see `_ARCHITECTURE.md` (refreshed 2026-06-27). Prior scan articles cover the kit structure; this snapshot summarizes the app-subsystem delta only.
