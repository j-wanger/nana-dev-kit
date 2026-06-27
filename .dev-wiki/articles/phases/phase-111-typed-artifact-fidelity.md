---
title: "Phase 111: Typed Artifact Fidelity (typed-details structured diff)"
aliases: [phase-111, typed-artifact-fidelity, structured-diff]
category: phases
tags: [gui, artifacts, diff, typed-details, pi-adapter, reduction, engine-neutral, dogfood]
parents: [phase-110-dogfood-ux-pass]
created: 2026-06-27
updated: 2026-06-27
source: plan
status: active
scope: ["app/src/engine/pi/pi-adapter.ts", "app/src/engine/types.ts", "app/src/ui/runtime.ts", "app/src/ui/artifact-feed.ts", "app/src/gate/host-gate.ts", "app/tests/**", "specs/gui-harness-architecture.md"]
entry_criteria: "Phase 110 BUILT + delivery accepted — real tool args/output thread adapter→reduction→UI, but the artifact panel routes via the looksLikeDiff SHAPE heuristic + generic-text fallback because typed `details` were deferred. Ph110's adversarial review CONFIRMED Pi's wrapper carries typed `details` (EditToolDetails.diff) and named this the de-risked Ph111 headline."
exit_criteria: "An allowed edit tool call renders a STRUCTURED canonical diff sourced from typed `details` (not the looksLikeDiff heuristic), and the typed path WINS over the heuristic when output text isn't diff-shaped; details-absent / Vercel tools degrade to heuristic/generic-text cleanly; the flaky provider-roundtrip e2e is deterministic (security invariant ship-blocking, no flake on absent denial); inert-render/CSP/capability-guard/gate-confirm NO regression; full app suite green; npm run build exit 0; cargo check exit 0; + adversarial pre-commit review confirmed-findings fixed. Felt-quality ships on maintainer judgment (Ph59/80 carve-out)."
---

# Phase 111: Typed Artifact Fidelity (typed-details structured diff)

## Objective

The de-risked Ph110 follow-on. Thread Pi's typed `details` (normalized to a neutral `{diff?: string}` at the adapter) **additively** through the existing engine-neutral layers — `types.ts` `tool-result` EngineEvent → `runtime.ts` `SurfaceToolCall` → `artifact-feed.ts` `mapToArtifact` — so the artifact panel renders a **structured, canonical DiffView** (more reliable: no false-negatives when edit output isn't diff-shaped; richer: the display-diff regardless of output text) instead of Ph110's `looksLikeDiff` shape-heuristic. A single vertical thread, source→surface, exactly like Ph110. No engine-type reshape (same invariant as Ph108/109/110).

## Scope

Files and modules affected:
- `app/src/engine/pi/pi-adapter.ts` — extract + redact + cap `result.details.diff`, attach as `details:{diff}`
- `app/src/engine/types.ts` — additive `details?: { diff?: string }` on the `tool-result` EngineEvent variant (HIGHEST blast radius)
- `app/src/ui/runtime.ts` — `SurfaceToolCall` gains `details?: { diff?: string }`; the `tool-result` reduction threads it
- `app/src/ui/artifact-feed.ts` — `toArtifact` checks `details.diff` FIRST (structured branch), `looksLikeDiff` + generic-text as fallback
- `app/tests/**` — adapter mapping (≥1 REAL Pi event shape), reduction round-trip, router, deterministic e2e, integration
- `specs/gui-harness-architecture.md` — read-only (umbrella spec, Rev 2)

**OUT (→ future phases):** structured TestResults (no Pi tool emits typed test details); signed/notarized bundle + A3 keyring residual + one-click rollback; command palette (axis 3); Claude Agent SDK adapter.

## Exit Criteria

- [x] An allowed edit tool call renders a STRUCTURED diff sourced from typed `details` (adapter→reduction→router→DiffView), NOT the `looksLikeDiff` heuristic
- [x] The typed path WINS over the heuristic when the output text is NOT diff-shaped; details-absent / Vercel tools degrade to heuristic / generic-text cleanly
- [x] The `provider-roundtrip` e2e is deterministic — the security invariant ("no out-of-workspace side effect"; "if a write/rm call was emitted, it was denied") is ship-blocking and no longer flakes on absent denial. **EXPANDED (ledger A5):** the e2e exposed a REAL host-gate out-of-workspace coverage gap → T4 reshaped to gate hardening (see Outcome)
- [x] inert-render/CSP/capability-guard/gate-confirm NO regression; `details.diff` redacted + capped + on the inert React-string path
- [x] Full app suite green (157→201); `cd app && npm run build` exit 0 (tsc + vite); `cargo check` exit 0; adversarial pre-commit review confirmed-findings fixed
- [ ] Felt-quality / legibility — maintainer judgment at delivery (Ph59/80 carve-out; deferred, Ph109/110 precedent)

## Outcome — BUILT + adversarially reviewed (2026-06-27); status active, delivery=pending

5/5 tasks [x] + 3 review fixes; full gate green (app suite 157→201, tsc + `npm run build` + `cargo check` all exit 0). **A1 RESOLVED HELD via the T1 live spike** — `tool_execution_end.result.details.diff` IS populated on the LOCAL subscribe path (a live local-model edit emitted `{diff:'-1 hello world / +1 goodbye world / 2 second line'}` and really edited the file; the `pi.on('tool_result')` fallback was NOT needed). **KEY FINDING:** Pi's `EditToolDetails.diff` is a line-number-prefixed `+`/`-`/space format with NO `---`/`+++`/`@@` header → Ph110's `looksLikeDiff` heuristic MISSES it, so the typed path is strictly BETTER (not just a refactor); DiffView's line-classing still renders it. TestResults stayed descoped (A2 held). **SECURITY scope amendment (ledger A5, maintainer-directed fold-in):** capturing the regression baseline exposed a REAL host-gate out-of-workspace coverage gap — the boundary was enforced ONLY for write/edit with an `args.path` key; bash file-writes + alt-named write tools BYPASSED it (Ph108's "empirically un-bypassable" was happy-path-only). T4 reshaped "pin the flaky e2e" → "close the gate gap," reordered FIRST: [[host-gate-out-of-workspace-hardening]] (high) extends base-policy COVERAGE (`PATH_ARG_KEYS` default-branch + `extractBashWriteTargets` bash-branch + `DEV_SINK` exemption), confirmable, gate verdict-loop core UNCHANGED. An adversarial finder×refuter review (6×2) caught a `/dev/null` over-block + a `>|` write-evasion the 24 gate tests missed. HONEST RESIDUAL: string-gating bash is incomplete by nature → OS-sandbox bash-fs isolation routed to Phase 112. Decisions [[typed-artifact-fidelity]] (high, updated BUILT) + [[host-gate-out-of-workspace-hardening]] (high, NEW). Status stays **active** — delivery gate flips on commit (D3); felt-quality/live window-drive = the maintainer's deferred call.

## Constraints

- **`app/src/engine/types.ts` is the highest blast radius** — the `tool-result` variant is imported by BOTH adapters + reduction + host + bridge; the new `details?` field MUST stay additive-optional + JSON-serializable (the bridge relays `EngineEvent` verbatim → enrichment auto-flows only if serializable). Vercel adapter + host/bridge are the "consumers you didn't touch" — they need NO change beyond type-checking the additive field. (prevents: a non-serializable / required field breaking the line protocol or the untouched adapter)
- **`details.diff` is untrusted model-adjacent content** → `redactSecrets()` + ~16KB cap at the adapter boundary + the inert React-string path (DiffView already renders inert). The inert-render/CSP/key-store tests stay green AND gain assertions for the new field. (prevents: an XSS/exfil regression via the new field)
- **Normalize at the adapter, route in the UI (A3 + A4).** The adapter extracts a whitelisted `{diff?: string}` — no Pi `EditToolDetails` type crosses the boundary; `mapToArtifact` still owns the VIEW-kind decision. (prevents: engine vocabulary leaking backwards across the Ph108 invariant + duplication across both adapters)
- **The gate CORE stays UNCHANGED** ([[gate-confirm-approve-loop]] ConfirmationBroker/confirmingGate, key-store hard-deny) — this is a render/fidelity pass, not a verdict-path change. (prevents: a security-boundary change masquerading as a render pass)
- **"Owned not adopted":** DiffView already consumes a diff string — do NOT add Vercel AI Elements (forces Tailwind/shadcn, Ph109/110 finding).

## Checkpoints

- After T1 (front-loaded live spike): confirm `result.details.diff` is reachable on the subscribe path; if absent → register `pi.on('tool_result')` + correlate by `toolCallId`. If details reach NEITHER → STOP-and-escalate (pivot to a different dogfood gap), do not render empty. Report.
- At delivery: the maintainer dogfoods a real edit and judges diff legibility (the carve-out).

## Assumptions

Direction gate closed 2026-06-27 (ledger Phase-111, all_accept:true):
- **A1 (accept, revisit-status: open)** — Pi's typed `details.diff` is reachable on the LOCAL subscribe path. `result` is typed `any` and `ToolResultEvent.details` is an EXTENSION-HOOK event, not the subscribe stream → reading `result.details` off the subscribe event is INFERENCE. T1 front-loads the live spike (Ph110-T1 pattern — the wrapper-shape bug the all-string fixtures masked was caught this way); pin ≥1 test against the REAL Pi event shape. Fallback = `pi.on('tool_result')` + `toolCallId` correlation. If false → STOP-and-escalate; pivot Ph111. Confirm at debrief.
- **A2 (accept, held)** — Test panel DESCOPED (diff-only). No Pi built-in tool emits structured test details; a TestResults panel would reintroduce the heuristic class Ph110 removed. If false → a separate phase adds a test-runner tool with typed details.
- **A3 (accept, held)** — `details` cross the boundary NORMALIZED to a neutral `{diff?: string}` at the adapter (not raw-forward). No Pi `EditToolDetails` type leaks; symmetric with `extractToolText`. If false → cheap reversal to `details?: unknown` raw-forward.
- **A4 (accept, held)** — Scope = typed-diff thread + pin the flaky e2e ONLY. Command palette / Claude SDK adapter / signed bundle + keyring residual + rollback stay separate future phases. Cheaply reversible (pull any one forward next phase).

## Notes

Umbrella spec: `specs/gui-harness-architecture.md` (nana:approved, Rev 2) — Surface line 41 names "TestResults, diff/CodeBlock"; Success Vision line 84 "artifacts preview instantly"; Ph108/109/110 ADR-named precedent (no separate phase spec). Builds on [[tool-call-visibility-thread]] (Ph110 — confirmed details-on-wrapper, named this the headline), [[engine-adapter-in-process-gate]], [[felt-quality-surface]], [[gate-confirm-approve-loop]], [[webview-engine-bridge]]. UI/felt quality UNMEASURABLE in-kit (Ph59/80) → mechanics-only tests; legibility judged by the maintainer at delivery.

Decision: [[typed-artifact-fidelity]] (high). Planned 2026-06-27, 5 tasks (M/S/M/S/M — zero L; the work is a thread through existing layers, not new subsystems). Knowledge gap: A1 details-on-subscribe reachability (T1 spike resolves; ledger A1 revisit-status: open). Structured TestResults remains unreachable until a test-runner tool with typed details exists (descoped, not a gap to fill this phase).
