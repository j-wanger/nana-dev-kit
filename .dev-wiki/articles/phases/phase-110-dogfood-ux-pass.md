---
title: "Phase 110: Dogfood UX Pass (Tool-Call Visibility + Artifact Fidelity + Branding)"
aliases: [phase-110, dogfood-ux-pass, tool-call-visibility]
category: phases
tags: [gui, surface, tool-call-visibility, artifacts, branding, pi-adapter, reduction, tauri, dogfood]
parents: [phase-109-felt-quality-surface]
created: 2026-06-27
updated: 2026-06-27
source: plan
status: active
scope: ["app/src/engine/**", "app/src/engine/adapter.ts", "app/src/ui/**", "app/src/context/**", "app/src/gate/**", "app/src/App.tsx", "app/src-tauri/**", "app/tests/**"]
entry_criteria: "Phase 109 delivered + live-drive VERIFIED (dogfood 2026-06-27 — real prompt→response round-trip through the full bridge; the gate held a destructive request live). The #1 surfaced gap: allowed tool calls render NAME-ONLY because the Pi adapter forwards args:{} + result:{isError}, and the reduction's SurfaceToolCall drops the result/output."
exit_criteria: "Allowed tool calls render WHAT ran (real args) + its output, threaded adapter→reduction→UI; multi-step tool-loops are legible (per-step progress/streaming); a real app icon + branding replace the Tauri placeholder; inert-render still green; full app suite green; npm run build exit 0. Felt-quality ships on maintainer judgment (Ph59/80 carve-out)."
---

# Phase 110: Dogfood UX Pass (Tool-Call Visibility + Artifact Fidelity + Branding)

## Objective

Close the #1 dogfood gap surfaced during Phase 109's live-drive: allowed tool calls render NAME-ONLY. The Pi adapter forwards `args:{}` (on `tool_execution_start`) and `result:{isError}` (on `tool_execution_end`), NOT the real command/output; the Ph108/109 reduction's `SurfaceToolCall` then drops the result entirely. Thread the real tool args + output through adapter→reduction→UI so the chat shows WHAT ran and its output; make multi-step tool-loops legible (per-step progress/streaming — a long local-model run looked frozen); add a real app icon + branding. Candidate: richer typed artifact views (diff/test/terminal) riding the now-real tool results.

## Scope

- `app/src/engine/pi/pi-adapter.ts` + `app/src/engine/types.ts` — source the real `args`/`result` (and possibly `tool_execution_update.partialResult`) Pi already emits; widen the narrowed `PiStreamEvent` type
- `app/src/ui/runtime.ts` — enrich `SurfaceToolCall` (carry args + result/output) + the `applyEngineEvent` reduction
- `app/src/ui/chat-binding.ts` — stop stubbing `args:{}`/`result:'done'`; thread the real fields into the assistant-ui part
- `app/src/ui/tool-call-view.tsx`, `app/src/ui/artifacts.tsx` — render the real args + output (typed views candidate)
- `app/src-tauri/icons/**` + `app/src-tauri/tauri.conf.json` — real app icon/identity (replace the Tauri placeholder)
- `app/tests/**` — mechanics tests for the enriched path

**OUT (DEFER to Phase 111+):** signed/notarized bundle (+ A3 keyring residual + one-click rollback); command palette (axis 3); Claude Agent SDK adapter; pin-the-flaky-e2e.

## Exit Criteria

- [x] An allowed tool call renders its real args (WHAT ran) + its real output, threaded adapter→reduction→UI (no more name-only / literal `'done'`)
- [x] Multi-step tool-loops are legible — per-step progress/streaming (`tool-progress`) so a long local-model run does not look frozen
- [x] A real app icon + branding replace the Tauri placeholder icon set (zlib-PNG Nana mark + `tauri icon` regen)
- [x] `app/tests/security/inert-render` still green (tool args/output render inert regardless of size/content) + redaction both directions pinned
- [x] Full app suite green (157, was 108); `cd app && npm run build` exit 0 (tsc + vite); `cargo check` exit 0
- [ ] Felt-quality / dogfood read — maintainer judgment at delivery (Ph59/80 carve-out; live window-drive deferred per Ph109 precedent)

## Constraints

- **Do NOT reshape the proven engine-neutral types where avoidable.** `EngineEvent.tool-result.result` is already `unknown` and `NormalizedToolCall.args` already exists — populating them is additive. Adding a NEW union variant (e.g. a `tool-progress` event) is additive too, but touches the reduction + bridge protocol; weigh it (Ph109 A1 lesson — don't churn tested types for UI convenience).
- **Preserve inert-render + strict CSP.** Real tool args/output is now untrusted model-adjacent content rendered in the chat; it MUST stay inert (React string children, never `innerHTML`) — the XSS→RCE rail. `ToolCallView` already renders args/result inert; keep that discipline as outputs get richer/larger.
- **Gate / checkpoint / engine-neutral CORE unchanged.** This is a visibility/render pass; no gate-logic, checkpoint, or security-boundary change. The bridge relays whatever `EngineEvent` the adapter emits verbatim — no protocol-security change needed.

## Checkpoints

- After the adapter+reduction+binding change: a synthetic Pi event stream with real args + output renders WHAT ran + its output end-to-end (mechanics test). Report.
- At delivery: the maintainer dogfoods a real multi-tool run and judges legibility + felt-quality (the carve-out).

## Assumptions

Direction gate closed 2026-06-27 (ledger Phase-110, all_accept:false):
- **A1 (accept, revisit-status: held)** — RESOLVED: Pi DOES populate real args + output on the live local path, but in `AgentToolResult` WRAPPER form (`{content:[{text}],details}`), not strings — a near-bite the adversarial pre-commit review caught + fixed (`extractToolText` normalizes at the boundary). No STOP-and-escalate; the fields render real data.
- **A2 (accept, held)** — threading real tool output adds untrusted content to the renderer. HARD constraint: every new field routes through `redactSecrets()` + stays inert (never raw HTML) + is size-capped at the boundary; the inert-render/key-store tests gained assertions for the new fields. The review hardened `redact.ts` both directions (catch AWS/GCP/JWT, exempt hash digests). T3 was the security-bearing task.
- **A3 (accept, revisit-status: held)** — RESOLVED: typed `details` (`edit.details.diff`) ARE confirmed-available on the path (pi `edit.js:212-216`). Ph110 ships the generic-text/diff-shape-heuristic panel (the A3 fallback); threading the typed `details` for a real structured DiffView/TestResults is deferred to Ph111 (de-risked headline).
- **A4 (don't-know → defended-accept, held)** — tool→view routing lives in the UI layer keyed on tool NAME (`ui/artifact-feed.ts`); the engine-neutral types carry args/output/details opaquely. Defense held: routing-in-adapter pushes UI vocabulary backwards across the Ph108 invariant AND duplicates across both adapters. Shipped with no issue.

## Notes

Umbrella spec: `specs/gui-harness-architecture.md` (nana:approved, Rev 2) — Surface section governs. Built on [[felt-quality-surface]], [[webview-engine-bridge]], [[gate-confirm-approve-loop]], [[engine-adapter-in-process-gate]]. UI/felt quality UNMEASURABLE in-kit (Ph59/80) → mechanics-only tests; joy/legibility judged by the maintainer at delivery. Use the `frontend-design` skill for the icon/branding aesthetic.

**Concrete data-path map (the load-bearing finding for task drafting):**
- Pi SDK ALREADY carries the data: `ToolExecutionStartEvent` has `args` and `ToolExecutionEndEvent` has `result` + `isError` (`node_modules/@earendil-works/pi-coding-agent/dist/core/extensions/types.d.ts:549-570`); there is also a `ToolExecutionUpdateEvent` with `partialResult` (streaming) the adapter does not subscribe to.
- `app/src/engine/pi/pi-adapter.ts:201-207` stubs `args:{}` on tool-call; `:209-216` forwards only `result:{isError}`. The narrowed `PiStreamEvent` (`:23-27`) does not even declare the args/result fields.
- `app/src/engine/types.ts:51` — `tool-result.result` is already `unknown` (can carry rich output, no type change); `:14-18` `NormalizedToolCall.args` already exists.
- `app/src/ui/runtime.ts:10-15` — `SurfaceToolCall` has NO args/result field; `:36` drops args; `:38-42` `tool-result` case only flips status to `done`, DROPPING `ev.result`. (the "reduction drops the result" gap.)
- `app/src/ui/chat-binding.ts:36-39` — projection HARD-STUBS `args:{}, argsText:'', result:'done'`.
- `app/src/ui/tool-call-view.tsx:3-9,30-35` — already ACCEPTS + renders `argsText`/`result` inert; it is starved by chat-binding, not missing the capability.
- The host (`app/src/host/engine-host.ts:103`) + bridge (`app/src/ui/engine-bridge.ts:113-119`) relay `engine-event` VERBATIM → enriching the adapter event flows to the UI automatically (no bridge change).
- Branding: `app/src-tauri/icons/` holds the default Tauri placeholder set (kept so the build passes); `index.html` title + `tauri.conf.json` productName already say "Nana Dev-Harness"/"nana-harness".

Decision: [[tool-call-visibility-thread]] (high). Planned 2026-06-27, 8 tasks (M/S/M/M/S/M/S/M — zero L; the work is a thread through existing layers, not new subsystems).

## Outcome (BUILT + ADVERSARIALLY REVIEWED 2026-06-27 — status active, READY FOR COMPLETION)

All 8 tasks [x] in one long session, each RED→GREEN→VERIFY with full-suite regression. The vertical thread landed source→surface (T1 `mapPiStreamEvent` seam → T2 additive `SurfaceToolCall`+reduction → T3 inline render via `redactSecrets` on the inert path → T4 additive `tool-progress` streaming → T5 pure `ui/artifact-feed.ts` router → T6 `ArtifactPanel` in App.tsx → T7 zlib-PNG Nana icon + `tauri icon` regen → T8 e2e + full gate). The engine-neutral layer stayed minimal/additive (no engine-type reshape); the gate CORE (ConfirmationBroker/confirmingGate, key-store hard-deny) UNCHANGED.

**The session headline was an adversarial pre-commit review** (6 dimension finders × 2 diverse-lens refuters; 15 raised → 6 confirmed → all fixed, 9 correctly refuted) that caught real defects the 142-test string-fixture suite MASKED: (HIGH) Pi's live `result`/`partialResult` are `AgentToolResult` WRAPPER objects (`{content:[{text}],details}`), NOT strings → `extractToolText()` joins `content[].text` + redacts-then-caps at the adapter boundary (else the live app renders `{"content":[…]}` JSON noise, the 16KB cap never fires, edit→diff never routes); (HIGH/MED) `redact.ts` reworked to CATCH AWS/GCP-`AIza`/JWT shapes now reachable via gate-allowed `bash cat ~/.aws/credentials`/`env` while EXEMPTING git-SHA/sha256 digests it over-redacted (both pinned in `tests/security/redact.test.ts`); (LOW) `looksLikeDiff` tightened. These were fixed in-phase as delivery hardening (DISCOVERY escape hatch). Health: app suite 108→142 (8 tasks) →157 (6 review fixes); tsc + `npm run build` + `cargo check` all exit 0; 1 flaky `provider-roundtrip` live e2e (model non-determinism, passes on retry, →Ph111). Ledger Phase-110 A1→held, A2→held, A3→held, A4→held (`--revisit 110` exit 0).

**Status stays `active` (READY FOR COMPLETION)** — delivery accepted per the Ph109 precedent (the live window-drive felt-quality check is the maintainer's deferred call); the delivery gate + `status: completed` flip after the commit verifiably lands (delivery-flow D3). Discovered → Phase 111: typed test/diff-from-structured-`details` (headline) / signed+notarized bundle + A3 keyring residual + one-click rollback / command palette (axis 3) / Claude Agent SDK adapter / pin the flaky live e2e.
