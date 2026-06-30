---
title: "Phase 115: Conversation memory (persist + restore the chat thread)"
aliases: [phase-115, conversation-memory, persisted-thread]
category: phases
tags: [conversation-memory, persistence, localstorage, redaction, security, workspace, dogfood, phase-115]
parents: []
created: 2026-06-30
updated: 2026-06-30
source: plan
status: active  # READY FOR COMPLETION — 5/5 tasks [x], app suite 374/374 + npm run build + cargo check exit 0, ledger A1/A2/A3/A4 held + A5 bit; delivery gate pending (D3 flips post-commit; completion = user confirmation)
scope: ["app/src/ui/conversation-store.ts", "app/src/ui/chat-runtime.ts", "app/src/App.tsx", "app/tests/ui/**", "app/src/** (review fixes)", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 114 DELIVERED + ACCEPTED (Pi the default + Rust-atomic workspace picker; app suite 343/343, tsc + npm run build + cargo check exit 0). The Ph114 respawn surfaced the cross-workspace-leak bug + the no-conversation-memory gap (#2), both routed here; #2 was deferred from Ph114 to design once the engine was decided."
exit_criteria: "Conversation persists to localStorage keyed by the active workspace root + restores on restart (live-drive-only, maintainer-verified); redactForPersist redacts ALL string leaves (incl. nested tool output + details.diff) AND strips the write content body → '[N bytes]' (serialized string carries NO seeded known-secret); per-workspace keying (no cross-leak); a workspace change SWAPS the thread (no stale cross-workspace leak — the Ph114 bug fixed); restore/swap issues ZERO engine sends (display-only); bound = last-N-turns + byte backstop, prune-oldest; setItem QuotaExceededError → prune-retry then skip (never throws); corrupt/wrong-shape/missing → empty (shape guard); done:false turns finalize on restore; newConversation clears store + persisted entry; full app suite + npm run build + cargo check all exit 0 + a focused adversarial pre-commit review's confirmed findings fixed."
---

# Phase 115: Conversation memory (persist + restore the chat thread)

## Objective

Close dogfood gap #2: persist a bounded, structurally-redacted, per-workspace conversation to localStorage so the chat thread survives an app restart AND swaps correctly on a workspace change — fixing, as a side effect, the stale cross-workspace leak the Ph114 respawn introduced (the surface never remounts, so the prior workspace's thread stays visible against the new workspace's fresh gate). Restore/swap is display-only (zero engine sends).

## Scope

Files and modules affected:
- `app/src/ui/conversation-store.ts` (NEW pure module — `redactForPersist` + `save`/`load`/`clear`, shape-guarded parse, bound/prune, fail-soft localStorage I/O)
- `app/src/ui/chat-runtime.ts` (optional workspace source + persist-on-settle + first-ready restore + onWorkspace swap + clear-on-newConversation)
- `app/src/App.tsx` (passes the bridge's workspace interface to `useChatRuntime`)
- `app/tests/ui/**` (`conversation-store.test.ts`, `conversation-persist.test.tsx`, `workspace-swap.test.tsx`)
- `app/src/**` (review fixes only, T5), `.claude/rules/active-phase.md`

The host gate, the engine-neutral types, and the stdin/stdout line protocol are UNTOUCHED — no engine types cross the boundary (honors [[engine-adapter-in-process-gate]]).

## Exit Criteria

- [ ] Conversation persists to localStorage keyed by the active workspace root + restores on restart (live-drive-only, maintainer-verified)
- [ ] `redactForPersist` redacts ALL string leaves (user/assistant text, error, tool args values, nested tool output, `details.diff`) AND strips the write `content` body → `'[N bytes]'`; the SERIALIZED string carries NO seeded known-secret substring (at-rest assertion)
- [ ] Per-workspace keying (key A ≠ key B, no cross-leak); a workspace change SWAPS the thread — NO stale cross-workspace leak (the Ph114 bug)
- [ ] Restore/swap issues ZERO engine sends (no `sendPrompt`/`respondGate`/`engine_send`) — display-only / no-bypass
- [ ] Bound = last-N-turns + byte backstop, prune-oldest; `setItem` QuotaExceededError → prune-retry then skip (never throws); corrupt/wrong-shape/missing → empty (shape guard); `done:false` turns finalize on restore; `newConversation` clears store + persisted entry
- [ ] Full app suite + `npm run build` + `cargo check` all exit 0; gate/inert/redact/no-bypass + Ph110/111/114 tool-visibility NO regression; a focused adversarial pre-commit review's confirmed findings fixed

## Constraints

- Redact at the PERSISTENCE BOUNDARY via a NEW structured walker (NOT the private truncating render projections in `chat-binding.ts`) — prevents persisting un-redacted leaves the render path never sees.
- Restore/swap is DISPLAY-ONLY — prevents a restored thread re-triggering tool calls or desyncing the freshly-reset gate after a respawn.
- The workspace source is an OPTIONAL `useChatRuntime` param — absent disables persistence — prevents breaking the bare adapters / offline path.
- Fail-soft localStorage I/O (try/catch + prune-retry then skip) — prevents a QuotaExceededError throwing inside a React effect/render.
- SECURITY (the constant): the host gate + inert-render + redact rail + no-bypass invariant stay UNCHANGED — prevents widening the renderer-trust gap (the store is NOT gate-load-bearing).

## Assumptions

(Locked at the assumption gate — ledger Phase-115, all_accept:false; A1 don't-know RESOLVED via down-scope.)
- A1 (KEY RISK, don't-know → resolved): redacting at the persistence boundary keeps on-disk secret-free. RESOLVED via 'strip high-risk bodies' (drop the write `content` body). If the residual proves unacceptable → persist text+tool-metadata only (the rejected max-safety option).
- A2 (accept): restore/swap is display-only (pure `setMessages`). If false → a no-bypass test catches a regression.
- A3 (accept): localStorage in the Tauri WebKit/wry webview persists across restarts. If false → the feature silently no-ops → fall back to a host/Rust-file path.
- A4 (accept): `ready.workspaceRoot` is a stable per-workspace key; restore triggers on `onWorkspace`, NOT at mount (null until first ready). The phase ALSO fixes the stale cross-workspace leak.
- A5 (accept): the quota holds a bounded redacted single conversation. If false → T2's prune-and-retry-then-skip path.

## Notes

Standard ceremony, 5 tasks (all M), source→surface order: T1 `redactForPersist` (security core, FRONT-LOADED) → T2 store I/O + bound/prune + per-workspace keying + fail-soft → T3 persist/restore/clear wiring + optional workspace source → T4 swap-no-leak (SECURITY-CRITICAL) + display-only invariant → T5 full gate + adversarial review + residuals + BUILT.

Rides the umbrella spec `specs/gui-harness-architecture.md` (nana:approved; Ph108-114 precedent, ADR-named) — NO separate phase spec. The spec north star: felt joy + control + "decisions and memory carry across sessions"; scope-guard "minimum daily loop, used-weekly test".

HONEST RESIDUALS (do NOT over-claim): A1 at-rest — `redactSecrets` is pattern-based and misses short/plaintext secrets; the content-strip is write-only (an edit tool's `new_string` body is redacted-not-stripped and shares this residual) — same content the live DOM already showed, the delta is durability (memory→disk); named a delivery-gate item. The live restart-restore round-trip is live-drive-only (Tauri runtime; cargo-check/vitest = compile/unit, Ph109-114 precedent).

Decision: [[conversation-memory-persistence]] (high). Builds on [[tool-call-visibility-thread]] (Ph110 redact-at-adapter), [[engine-adapter-in-process-gate]] (no engine types across the boundary; no-bypass), [[pi-default-engine]] (Ph114).

## Review & Residuals (T5)

DELIVERED 2026-06-30, 5/5 tasks [x]. Gate: app suite **374/374** (54 files; incl. the live Pi e2e + gate-deny when localhost:8080 is up), `npm run build` (tsc + vite) exit 0, `cargo check` exit 0. New tests: conversation-store 22, conversation-persist 5, workspace-swap 4.

**Adversarial review** — 2 parallel finders (lens 1 security: secrets-at-rest + display-only/no-bypass + inert-render; lens 2 correctness: fail-soft + lifecycle/races + key + bound/prune + regression), each finding VERIFIED against the code by the orchestrator (subagent prose = candidate-only, [[decision:qa-verification-sweep]]). 6 confirmed findings ALL FIXED (DISCOVERY/SECURITY escape hatch):
- **(HIGH) silent total-loss on overwrite** — `saveConversation`'s byte-backstop `while (kept.length > 0 …)` could prune a NON-empty thread to `[]` when one message exceeded `MAX_BYTES`, then `setItem("[]")` overwrote good history (the opposite of the feature's promise; reachable on a large read/bash output). Fixed: keep ≥1 message (`> 1`), the quota retry SKIPS the write at the last message rather than clobbering the prior value, and the whole body is wrapped fail-soft.
- **(MED) multi-workspace quota** — `MAX_BYTES` 1MB × unbounded workspace keys > the ~5MB origin quota, no eviction. Mitigated: lowered to 256KB; documented residual (no cross-workspace LRU).
- **(LOW) tool-status not finalized** — a turn interrupted after `tool-call`/before `tool-result` persisted `status:'called'` → restored as a perpetual tool spinner. Fixed: clamp `called`→`done` in `redactForPersist` (per-tool analogue of the message `done` finalize). Confirmed display-only (no re-exec).
- **(LOW) `details` forwarded verbatim** — the one non-whitelisted field. Fixed: `redactDeep(tc.details)`.
- **(LOW) shape guard incomplete** — `toolCalls:[null]` passed `Array.isArray` and crashed chat-binding on restore. Fixed: validate each element (non-null object with string id/name/status) — hardens restore vs tampered/legacy storage.
- **(LOW) empty-root inconsistency** — fixed: `apply` ignores a bogus empty `root`.

Documented NON-issues (not fixed): `redactDeep` doesn't redact object KEYS (keys are tool-schema param names; output is pre-stringified — not secret-bearing); a turn interrupted by a workspace change persists its `workspace changed` error marker (an HONEST interrupted-turn signal — intended, not spurious).

**Residuals (accepted, delivery-gate items):** A1 at-rest (above); the live restart-restore + native swap round-trip is live-drive-only (Tauri runtime); multi-workspace quota fail-soft past ~15-20 large active workspaces (no LRU). The host gate + inert-render + redact rail + no-bypass invariant are UNCHANGED; out-of-workspace READ stays the Ph112 residual.
