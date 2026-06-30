---
title: "Conversation memory — per-workspace persisted + redacted at the boundary"
aliases: [conversation-memory-persistence, conversation-memory, persisted-thread, chat-persistence, redact-for-persist]
category: decisions
tags: [conversation-memory, persistence, localstorage, redaction, security, workspace, dogfood, renderer, phase-115]
parents: [phase-115-conversation-memory]
created: 2026-06-30
updated: 2026-06-30
source: plan
confidence: high
---

## Context

Live-drive dogfooding flagged gap #2: the GUI conversation is pure in-memory React state (`app/src/ui/chat-runtime.ts:36` `useState<UiMessage[]>`), so **(a)** an app restart loses the whole thread and **(b)** a workspace change LEAKS it. The Ph114 workspace picker kills + respawns the sidecar, but the surface never remounts — `App.tsx:23/35/56/61` keep the SAME `BridgeClient` instance, `setBridge` is called once, and `HarnessSurface` has no `key` — so the prior workspace's thread stays visible against the new workspace's fresh gate + approved-writes (a stale **cross-workspace leak**, CONFIRMED in code by the approach reviewer; ledger A4). `newConversation()` only clears to `[]` (`chat-runtime.ts:65`) — no load/swap path exists.

The headline risk is at-rest exposure: `redactSecrets` is pattern-based (PEM / `sk-` / `AKIA` / `AIza` / `gh*_` / `xox*` / JWT prefixes + opaque ≥32-char high-entropy), so a plaintext password in a written file's `content` arg — or a short/non-prefixed token — would persist DURABLY to localStorage. That is a memory→disk regression vs today's volatile-only display (ledger A1, don't-know).

## Decision

Persist a **bounded, structurally-redacted, per-workspace** conversation to **localStorage**, keyed by the active workspace root (`ready.workspaceRoot`, via `bridge.onWorkspace`/`currentWorkspace` — null until first ready). Restore on restart; swap on workspace change (also fixing the stale leak). Restore/swap is **display-only** (pure `setMessages`, ZERO engine sends).

Redact at the **persistence boundary** via a NEW structured walker `redactForPersist(UiMessage)→UiMessage` (NOT the private truncating render projections in `chat-binding.ts`): apply `redactSecrets` to ALL string leaves (user text, assistant text, error, tool args values, tool output incl. nested per `runtime.ts:21` `unknown`, `details.diff`); **STRIP the write `content` arg body** → `'[N bytes]'` marker (the single largest secret-bearing field — maintainer chose 'strip high-risk bodies' over full-redact, ledger A1); finalize `done:false` turns to `done:true` (no perpetual 'running' bubble on restore). Bound = last-N-turns primary + byte backstop, prune oldest; `setItem` wrapped in try/catch with prune-retry then skip (never throws inside a React effect). The workspace source is an **OPTIONAL** param to `useChatRuntime` — absent → persistence disabled (bare adapters / offline path unaffected).

### Alternatives considered + rejected
- **(B) host/Rust-side transcript** — rejected by the subtraction test: a bounded redacted conversation fits localStorage, and the store is NOT gate-load-bearing, so renderer-owned persistence does NOT widen the renderer-trust gap.
- **(C) text-only / tool-metadata-only (max safety)** — rejected: lower restore fidelity; the chosen strip-high-risk-bodies keeps structure while dropping the one durable-secret field. (Kept as the A1 fallback if the residual proves unacceptable at the delivery gate.)
- **(D) full-redacted incl. write content** — rejected: more at-rest exposure than stripping the body outright.

## Consequences

- New pure module `app/src/ui/conversation-store.ts` (`redactForPersist` + `save`/`load`/`clear`, shape-guarded parse, bound/prune, fail-soft localStorage I/O); `useChatRuntime` gains an optional workspace source + a persist-on-settle effect + first-ready restore + onWorkspace swap + clear-on-newConversation; `App.tsx` passes the bridge's workspace interface. The host gate + line protocol are UNTOUCHED (no engine types across the boundary; no-bypass invariant intact, [[engine-adapter-in-process-gate]]).
- A no-bypass test locks restore/swap to ZERO engine sends (display-only); a workspace-swap test asserts no stale cross-workspace leak (the Ph114 bug, fixed as a side effect).
- **HONEST RESIDUALS (A1, accepted):** `redactSecrets` is pattern-based and misses short/plaintext secrets; the content-strip is write-only — an `edit` tool's `new_string` body is **redacted-not-stripped** and shares this residual. Same content the live DOM already showed; the delta is durability (memory→disk). Named as a delivery-gate item. The live restart-restore round-trip is **live-drive-only** (Tauri WebKit/wry runtime; cargo-check/vitest can't exercise it — Ph109-114 precedent).
- SECURITY (the constant, UNCHANGED): the host gate + inert-render + redact rail + no-bypass invariant stay UNCHANGED; out-of-workspace READ stays the Ph112 residual.

## Source

Phase 115 plan (2026-06-30). Direction confirmed at the assumption gate (ledger Phase-115, all_accept:false — A1 don't-know RESOLVED via the 'strip high-risk bodies' down-scope, A2-A5 accept; `--gate 115` exit 0). Confidence high. Builds on [[tool-call-visibility-thread]] (Ph110 redact-at-adapter), [[engine-adapter-in-process-gate]] (no engine types across the boundary; no-bypass), [[pi-default-engine]] (Ph114). Rides umbrella spec `specs/gui-harness-architecture.md` (Ph108-114 precedent, ADR-named — no separate phase spec).
