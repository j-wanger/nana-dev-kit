---
title: "Phase 115 delivered — Conversation memory (persist + restore the chat thread)"
date: 2026-06-30
type: journal
phase: 115
tags: [phase-115, conversation-memory, persistence, localstorage, redaction, security, workspace, gui-harness, adversarial-review, delivered]
parents: [phase-115-conversation-memory]
created: 2026-06-30
updated: 2026-06-30
source: debrief
duration: ~2-3 hours (single session: plan + 5 TDD tasks + 2 review rounds)
---

# Phase 115 delivered — Conversation memory (persist + restore the chat thread)

## What Happened

- Closed dogfood gap #2: the GUI conversation was pure in-memory React state (`chat-runtime.ts:36`), so an app restart lost the whole thread AND a workspace change LEAKED it. Persist a bounded, structurally-redacted, PER-WORKSPACE conversation to **localStorage** (keyed by `ready.workspaceRoot` via `bridge.onWorkspace`); restore on restart + **SWAP** on workspace change — the swap also fixes the Ph114 stale cross-workspace leak as a side effect.
- The **approach reviewer corrected the FACTUAL PREMISE** before any code: the plan assumed "restart/workspace-change LOSES the thread." In code the Ph114 respawn never remounts the surface (same `BridgeClient`, `setBridge` called once, `HarnessSurface` has no `key`), so the prior workspace's thread STAYS VISIBLE against the new workspace's fresh gate — a stale LEAK, not a loss. This reframed success: the test that matters is "thread SWAPS on workspace change," not "restore after respawn" (which tests a non-loss). Ledger A4 was strengthened by this correction (key-is-stable premise held; framing sharpened).
- 5 TDD tasks, source→surface order: T1 `redactForPersist` (security core, front-loaded) → T2 store I/O + bound/prune + per-workspace keying + fail-soft → T3 persist/restore/clear wiring + OPTIONAL workspace source → T4 swap-no-leak + display-only invariant → T5 full gate + adversarial review + residuals + BUILT.
- A1 don't-know (redaction completeness at-rest) was RESOLVED at the gate via the down-scope **'strip high-risk bodies'** — drop the write `content` body → `'[N bytes]'` rather than full-redact-or-text-only.

## Decisions Made

- [[conversation-memory-persistence|Conversation memory — per-workspace persisted + redacted at the boundary]] (high) — article written by the plan; touched `updated:` only this debrief (no duplicate).

## Problems Solved

- **(HIGH) silent total-loss on overwrite** — `saveConversation`'s byte-backstop `while (kept.length > 0 …)` could prune a NON-empty thread to `[]` when one message exceeded `MAX_BYTES`, then `setItem("[]")` overwrote good history (the opposite of the feature's promise; reachable on a large read/bash output). Fixed: keep ≥1 message (`> 1`), the quota retry SKIPS the write at the last message rather than clobbering, whole body wrapped fail-soft. (Ledger A5 BIT — caught by the correctness reviewer.)
- **5 lower findings, all fixed** — (MED) multi-workspace quota: lowered `MAX_BYTES` to 256KB + documented the no-cross-workspace-LRU residual; (LOW) tool-status not finalized → clamp `called`→`done` in `redactForPersist`; (LOW) `details` forwarded verbatim → `redactDeep(tc.details)`; (LOW) shape guard incomplete (`toolCalls:[null]` crashed restore) → validate each element; (LOW) empty-root inconsistency → `apply` ignores a bogus empty root.
- Redact at the **PERSISTENCE boundary** (not the render-path projections): the in-memory store holds RAW tool args (output/diff are adapter-redacted, but args are not) — serializing verbatim would write secrets to disk. `redactForPersist` walks ALL string leaves + strips the write content body.

## Open Questions

- None. (Residuals are accepted delivery-gate items, not open questions.)

## Artifacts Changed

- `app/src/ui/conversation-store.ts` (NEW pure module — `redactForPersist` + `save`/`load`/`clear` over localStorage, shape-guarded parse, bound/prune, fail-soft I/O)
- `app/src/ui/chat-runtime.ts` (OPTIONAL workspace-source 2nd param; persist-on-settle + first-ready restore + onWorkspace swap + clear-on-newConversation)
- `app/src/App.tsx` (passes the bridge's workspace interface to `useChatRuntime`)
- `app/tests/ui/{conversation-store.test.ts (22), conversation-persist.test.tsx (5), workspace-swap.test.tsx (4)}` (NEW, +31)
- `.dev-wiki/articles/phases/phase-115-conversation-memory.md`, `.dev-wiki/assumption-ledger.md` (A2-A4 held, A5 bit), `.claude/rules/active-phase.md`

## Health Delta

App suite **343 → 374** green (+31 across conversation-store/conversation-persist/workspace-swap); +1 module; `tsc --noEmit` clean; `npm run build` + `cargo check` exit 0. No lint/type regressions; gate/inert/redact/no-bypass + Ph110/111/114 tool-visibility rails unbroken.

## Related

- [[phase-115-conversation-memory|Phase 115 — Conversation memory]] — parent phase
- Builds on [[tool-call-visibility-thread]] (Ph110 redact-at-adapter), [[engine-adapter-in-process-gate]] (no engine types across the boundary; no-bypass), [[pi-default-engine]] (Ph114).

## Review Gate

Adversarial pre-commit review (2 parallel finders — lens 1 security: secrets-at-rest + display-only/no-bypass + inert-render; lens 2 correctness: fail-soft + lifecycle/races + key + bound/prune + regression), each finding VERIFIED against the code by the orchestrator (subagent prose = candidate-only, [[qa-verification-sweep]]). 6 confirmed findings ALL FIXED inline via the DISCOVERY/SECURITY escape hatch (not new tasks). Served as the size-gated review for this Standard phase.

## Gate Compliance

direction=approved (assumption gate, ledger Phase-115 all_accept:false — A1 don't-know RESOLVED via down-scope; `--gate 115` exit 0); delivery=PENDING — the gate flips post-commit (D3). Spec gate satisfied by the ADR-named umbrella `specs/gui-harness-architecture.md`.

## Assumption-Ledger Revisit

A1 **held** (the 'strip high-risk bodies' down-scope held; at-rest residual documented + accepted at the delivery gate). A2 **held** (display-only confirmed by the zero-engine-sends no-bypass test + review). A3 **held** (localStorage persistence is live-drive-pending but did not bite at build/test). A4 **held** (workspaceRoot keying held; the reviewer's HIGH correction sharpened the framing — respawn LEAKS not loses — but the key-is-stable premise held). **A5 BIT** (the byte-backstop could prune a non-empty thread to `[]` then overwrite good history = a real bound/quota data-loss bug; found + FIXED in T5). `--revisit 115` exit 0. SUGGESTION: the A5 bite is a fix-in-place, not a reversal — [[conversation-memory-persistence]] confidence stays high (the maintainer decides).

### Retro Check (Phases 106-115)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User / reviewer corrections | recurring | low |

Recommendations:
- No systemic issue. The recurring Dim-3 class across Ph109-115 is maintainer/reviewer reframes at the assumption/approach gate (Ph115: the factual-premise correction "respawn leaks not loses") — the gate working as designed, not a reliability gap.
- The **adversarial pre-commit review** has now caught a HIGH the passing TDD suite missed on FIVE consecutive security/cross-boundary phases (Ph110/111/112/114/115) — keep it as load-bearing practice for any phase that touches a security rail, crosses the engine boundary, or persists model-adjacent output.

## Soft Observations / Phase 116 Candidates

- **Live window-drive deferred a 6th time** — the restart-restore round-trip + the Ph114 native dialog→respawn are still live-drive-only across Ph109-115 (cargo-check/vitest = compile/unit only). Candidate Ph116: a dedicated live-validation phase (felt-quality + the deferred round-trips). | evidence: this journal + Ph114 journal "5th time" note.
- **Multi-workspace localStorage quota has NO cross-workspace LRU eviction** (Ph115 MED residual) — past ~15-20 large active workspaces new saves fail-soft/skip. Future hardening if multi-project use grows. | evidence: phase article Review & Residuals.
- **Pre-existing renderer-trust gap** (Ph108/109 — a compromised renderer can auto-approve a held gate via `engine_send{gate-verdict}`) still open — candidate hardening phase. | evidence: Ph114 journal soft-observations.
- **Blocking out-of-workspace READ** (the standing Ph112 confidentiality residual) still open. | evidence: Ph112/114 residuals.
