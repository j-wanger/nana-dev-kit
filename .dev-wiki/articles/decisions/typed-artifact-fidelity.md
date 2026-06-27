---
title: "Typed artifact fidelity — structured diff from Pi's typed details"
aliases: [typed-artifact-fidelity, structured-diff-from-details, typed-details-thread, phase-111-thread]
category: decisions
tags: [gui-harness, artifacts, diff, engine-adapter, pi-adapter, reduction, typed-details, phase-111]
parents: [phase-111-typed-artifact-fidelity]
created: 2026-06-27
updated: 2026-06-27
source: debrief
confidence: high
---

## Context

Phase 110 threaded real tool args/output through the engine-neutral layers, but the artifact panel still routes via a **diff-SHAPE heuristic** (`looksLikeDiff` over the output text) + a generic-text fallback — because Pi's typed `details` were deferred. The heuristic is brittle two ways: a **false-negative** when an edit's output isn't diff-shaped (no diff renders), and it can only ever show the diff that happens to be *in the output text* rather than the tool's own structured diff. Ph110's adversarial pre-commit review **CONFIRMED** Pi's `AgentToolResult` wrapper carries typed `details` (`EditToolDetails.diff`, verified at pi `edit.js:212-216`) — so the structured source exists and is reachable in wrapper form; Ph110 named threading it the **Ph111 headline** (de-risked). The question is the same single vertical thread as Ph110: source→surface, one engine-neutral additive pass.

## Decision

Thread Pi's typed `details` through the **existing engine-neutral layers additively** (no engine-type reshape — same invariant as Ph108/109/110) so the artifact panel renders a **structured, canonical DiffView** instead of the heuristic. The typed path **WINS over the heuristic** when present; the `looksLikeDiff` + generic-text path remains as fallback for Vercel (details-less) and detail-absent tools (write/bash).

Three direction-gate forks, all accepted on the recommended path:
- **Test panel DESCOPED (diff-only).** NO Pi built-in tool (bash/read/edit/write/grep/find/ls) emits structured test details, so a TestResults panel would require **heuristic-parsing bash output — reintroducing the exact heuristic class Ph110 removed**. The structured headline is the DIFF only; TestResults stays built-ahead-of-data until a real test-runner tool with typed details exists.
- **NORMALIZE `details` to a neutral `{diff?: string}` at the adapter** (not raw-forward). The adapter extracts a whitelisted, redacted, capped `diff` string — no Pi `EditToolDetails` type leaks into the UI; symmetric with how Ph110's `extractToolText` normalizes the wrapper→string. **A4 PRESERVED** — the adapter normalizes DATA shape (a `diff` string), the UI's `mapToArtifact` still owns the VIEW-kind decision. Honors [[engine-adapter-in-process-gate]] (no engine types across the boundary).
- **SCOPE = typed-diff thread + pin the flaky `provider-roundtrip` e2e ONLY.** Command palette (axis 3) / Claude Agent SDK adapter / signed-notarized bundle + A3 keyring residual + one-click rollback each stay SEPARATE future phases — bundling dilutes the dogfood thread.

### Alternatives considered

- **Raw-forward Pi `details?: unknown` — REJECTED:** leaks Pi vocabulary into the UI, a soft violation of [[engine-adapter-in-process-gate]]; cheap reversal if the maintainer later prefers less adapter code.
- **Light up TestResults via bash-output parsing — REJECTED:** reintroduces the heuristic class Ph110 removed; no Pi tool emits structured test details.
- **Bundle command palette / Claude SDK adapter / signed bundle — DEFERRED:** each its own phase; the signed bundle is a distribution concern, not a felt-quality render.

## Consequences

- `types.ts` `tool-result` EngineEvent gains an additive `details?: { diff?: string }`; `runtime.ts` `SurfaceToolCall` gains the same; `artifact-feed.ts` `toArtifact` checks `details.diff` FIRST, falls back to `looksLikeDiff` + generic-text. **The Vercel adapter + the host/bridge JSON line protocol are the "consumers you didn't touch"** — they need NO change beyond type-checking the additive-optional field, and every payload MUST stay JSON-serializable (the bridge relays `EngineEvent` verbatim → enrichment auto-flows only if serializable).
- `details.diff` is **untrusted model-adjacent content** → routes through `redactSecrets()` + a ~16KB cap at the adapter boundary + stays on the inert React-string path (DiffView already renders inert). The inert-render/CSP/key-store tests gain assertions for the new `details` field.
- **The #1 risk is A1 (front-loaded T1 live spike):** `tool_execution_end.result` is typed `any` and the strongly-typed `ToolResultEvent` (with `.details`) is an **extension-hook event, not the subscribe stream** — so reading `result.details` off the subscribe event is INFERENCE. T1 live-spikes it (Ph110-T1 pattern; pin ≥1 test against the REAL Pi event shape, not string fixtures); fallback = `pi.on('tool_result')` hook + `toolCallId` correlation. If details reach NEITHER subscribe NOR a reliably-correlatable hook → **STOP-and-escalate** (pivot Ph111 to a different dogfood gap), never render empty.
- The **gate CORE stays UNCHANGED** — `ConfirmationBroker`/`confirmingGate` ([[gate-confirm-approve-loop]]) and the key-store hard-deny are untouched; this is a render/fidelity pass, not a verdict-path change.
- No App.tsx/ArtifactPanel change — DiffView already consumes a diff string and ArtifactPanel already routes `kind==='diff'` → DiffView.

### Outcome — BUILT + DELIVERED (2026-06-27)

- **A1 RESOLVED HELD via the T1 live spike.** Pi's typed `details.diff` IS populated on the LOCAL subscribe path — a live local-model edit emitted `{diff:'-1 hello world / +1 goodbye world / 2 second line'}` and really edited the file; the `pi.on('tool_result')` hook fallback was NOT needed.
- **KEY FINDING (made the typed path strictly better, not just a refactor):** Pi's `EditToolDetails.diff` is a line-number-prefixed `+`/`-`/space format with NO `---`/`+++`/`@@` header → Ph110's `looksLikeDiff` heuristic MISSES it, so the heuristic would render NO diff (terminal fallback) where the typed branch now renders a real diff. `DiffView`'s `+`/`-`/space line-classing still renders the header-less form. The typed-diff branch in `artifact-feed.ts` WINS over the heuristic; detail-absent / Vercel tools fall back cleanly to `looksLikeDiff` + generic-text.
- **TestResults stayed descoped** (A2 held) — no Pi built-in tool emits structured test details, so it remains built-ahead-of-data until a real test-runner tool with typed details exists.
- A SECURITY scope-amendment rode alongside (T4, reshaped from "pin the flaky e2e"): see [[host-gate-out-of-workspace-hardening]]. health: app suite 157 → 201 (+44, all live e2e green); tsc + `npm run build` + `cargo check` exit 0.

## Source

Phase 111 plan (2026-06-27). Builds directly on [[tool-call-visibility-thread]] (Ph110 — confirmed details-on-the-wrapper and named this the headline). Umbrella spec `specs/gui-harness-architecture.md` Rev 2 (Surface line 41 names "TestResults, diff/CodeBlock"; Success Vision line 84 "artifacts preview instantly"; Ph108/109/110 ADR-named precedent — no separate phase spec). Ledger Phase-111 (all_accept:true — A1 accept-spike-mitigated/revisit-open, A2/A3/A4 accept). Builds on [[engine-adapter-in-process-gate]], [[felt-quality-surface]], [[gate-confirm-approve-loop]], [[webview-engine-bridge]]. UI/felt quality UNMEASURABLE in-kit (Ph59/80) → mechanics-only tests; legibility judged by the maintainer at delivery.
