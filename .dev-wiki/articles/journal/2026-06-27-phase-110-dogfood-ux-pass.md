---
title: "Phase 110 — Dogfood UX Pass: BUILT + adversarially reviewed (8/8 tasks + 6 review fixes, READY FOR COMPLETION)"
aliases: [2026-06-27-phase-110, dogfood-ux-pass-built]
category: journal
tags: [gui-harness, tool-visibility, artifacts, branding, pi-adapter, redaction, adversarial-review, phase-110]
parents: [phase-110-dogfood-ux-pass]
created: 2026-06-27
updated: 2026-06-27
source: debrief
duration: long single session (plan → 8-task TDD implementation → adversarial review → 6 fixes → debrief)
---

# Phase 110 — Dogfood UX Pass (Tool-Call Visibility + Artifact Fidelity + Branding)

## What Happened
- The first dogfood-driven UX pass, planned + implemented in one long session, closing Ph109's live-drive #1 gap: allowed tool calls rendered NAME-ONLY because the Pi adapter stubbed `args:{}`/`result:{isError}` (`pi-adapter.ts:205/213`) and the reduction's `SurfaceToolCall` dropped the output (`runtime.ts:38-42`), while Pi's event stream + the Ph109 UI components already carried/rendered the real data — the components were built ahead of the data.
- A single vertical thread, source→surface, across 8 tasks (zero L): T1 `mapPiStreamEvent` pure seam forwards real args + capped output + additive `isError`; T2 `SurfaceToolCall`+reduction carry them additively (JSON round-trip asserted); T3 inline render via `redactSecrets` on the inert path (security-bearing); T4 additive `tool-progress` event (`tool_execution_update.partialResult`) for in-flight streaming legibility; T5 pure `ui/artifact-feed.ts` typed router (UI-keyed, generic-text fallback per A3); T6 `ArtifactPanel` wired into `App.tsx` (`useChatRuntime`→`{runtime,artifacts}`); T7 dependency-free zlib PNG generator → 1024² Nana mark → `tauri icon` regen; T8 e2e reduction test + the full gate.
- **The headline of the session was the adversarial pre-commit review** (6 dimension finders × 2 diverse-lens refuters; 15 raised → 6 confirmed → all fixed, 9 correctly refuted) — it caught real defects the 142-test string-fixture suite MASKED, before the delivery commit.
- Delivery accepted per the Ph109 precedent (the live window-drive felt-quality check is the maintainer's deferred call); the delivery gate flips after the commit verifiably lands (D3).

## Decisions Made
- [[tool-call-visibility-thread]] (high) — UPDATED this session: Consequences gained the built outcome + the adversarial-review findings; ledger A1/A3 RESOLVED (Pi populates args/output in `AgentToolResult` wrapper form; typed `details` confirmed-available → Ph111 headline).

## Problems Solved
- **(HIGH) live-engine wrapper shape** — Pi's real `result`/`partialResult` are `AgentToolResult` wrappers (`{content:[{text}],details}`), NOT strings; the adapter forwarded them raw → the live app would have shown `{"content":[…]}` JSON noise, the 16KB cap would never fire, edit→diff never routed. FIXED: `extractToolText()` joins `content[].text` + redacts-then-caps at the adapter boundary; the 142 string fixtures had hidden it. (DISCOVERY escape hatch.)
- **(HIGH/MED) redaction both directions** — `redact.ts` reworked to CATCH AWS-secret/GCP-`AIza`/JWT shapes now reachable via gate-allowed `bash cat ~/.aws/credentials`/`env`, while EXEMPTING git-SHA/sha256 digests it over-redacted; both pinned in `tests/security/redact.test.ts`. (DISCOVERY escape hatch.)
- **(LOW) `looksLikeDiff`** tightened to require diff-header structure; artifact text bounded.

## Open Questions
- None open. Ledger A1/A3 (was: open) RESOLVED by the review — Pi delivers args/output (in wrapper form) and typed `details` are confirmed-available; typed-diff-from-`details` deferred to Ph111, the generic-text/diff-shape-heuristic panel ships now.

## Artifacts Changed
- `app/src/engine/pi/pi-adapter.ts` (`extractToolText` AgentToolResult→text normalization at the boundary; real args/output forwarded)
- `app/src/engine/types.ts` (additive `tool-progress` EngineEvent variant + optional `tool-result.isError`)
- `app/src/ui/runtime.ts` (`SurfaceToolCall` args?/output?/isError?; reduction threads them + folds partial)
- `app/src/ui/chat-binding.ts`, `tool-call-view.tsx` (real argsText + result via `redactSecrets`+truncate)
- `app/src/ui/artifact-feed.ts` (NEW pure `toArtifact`/`toArtifacts` router) + `artifacts.tsx` (`ArtifactPanel`)
- `app/src/ui/chat-runtime.ts` (`useChatRuntime` → `{runtime, artifacts}`), `app/src/App.tsx` (Artifacts panel in `surface__side`)
- `app/src/security/redact.ts` (specific AWS/GCP/JWT patterns + hash-exempting base64 catch-all)
- `app/src-tauri/icons/**`, `app/assets/icon-source.png` (regenerated Nana icon set)
- `app/tests/**` (+ tool-visibility, artifact-feed, artifact-panel, tool-visibility-e2e, security/redact, branding/icon)

## Related
- [[phase-110-dogfood-ux-pass|Phase 110: Dogfood UX Pass]] — parent phase
- Builds on [[felt-quality-surface]], [[webview-engine-bridge]], [[gate-confirm-approve-loop]], [[engine-adapter-in-process-gate]]

## Health
- app suite **108 (Ph109 baseline) → 142 (8 tasks) → 157 (6 review fixes), +49 net**; `tsc --noEmit` clean; `npm run build` (tsc+vite) exit 0; `cargo check` exit 0.
- One live e2e (`tests/e2e/provider-roundtrip` "out-of-workspace write blocked") is flaky (model non-determinism) — passes on isolated retry; →Ph111 #5.
- No regression in inert-render / CSP / capability-guard / gate-confirm.

## Soft Observations / Phase 111 Candidates
- TYPED test/diff-from-structured-`details` is the de-risked Ph111 headline (review confirmed `edit.details.diff` exists, pi `edit.js:212-216`) — replaces the current diff-shape heuristic + generic-text fallback with a real structured DiffView/TestResults. | evidence: review boundary-1 verifier.
- LESSON (harvested → memory): 142 green string-fixture tests masked a HIGH live-engine bug (Pi `AgentToolResult` wrapper vs string) — pin ≥1 test against the REAL upstream event shape; normalize wrapper→text at the boundary. | evidence: review boundary-1.
- LESSON (harvested → memory): an adversarial finder/refuter review BEFORE the commit caught 2 HIGH + a real security gap the TDD suite missed — worth repeating for security-adjacent / cross-boundary phases. | evidence: ph110-adversarial-review (6 confirmed / 15 raised).
- Pin the flaky `provider-roundtrip` e2e (Ph111 #5).

### Retro Check (Phases 81-110, 90 completed)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 1 (maintainer chose fuller scope: panel in Ph110 not inline-only — at the direction gate, not a mid-build override) | low |

Recommendations:
- No systemic issue. The recurring cross-boundary class (test fixtures masking live-engine contracts, security rails under/over-redacting) was caught by the adversarial pre-commit review this session, not by the TDD suite — keep that review step for security-adjacent / engine-boundary phases. The maintainer's only correction was a scope choice at the gate (working as intended).
