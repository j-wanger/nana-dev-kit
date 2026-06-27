---
title: "Thread real tool args/output/details source→surface (the Ph109 #1 dogfood gap)"
aliases: [tool-call-visibility-thread, tool-call-visibility, args-output-thread, phase-110-thread]
category: decisions
tags: [gui-harness, tool-visibility, artifacts, engine-adapter, pi-adapter, reduction, phase-110]
parents: [phase-110-dogfood-ux-pass]
created: 2026-06-27
updated: 2026-06-27
source: plan
confidence: high
---

## Context

Phase 109's live-drive (dogfood 2026-06-27) proved the spine works: tool calls fire and the security gate holds a destructive request live through the GUI. But it surfaced the **#1 gap** — allowed tool calls render **name-only**. The Pi adapter stubs `args:{}` on `tool_execution_start` (`pi-adapter.ts:205`) and forwards only `result:{isError}` on `tool_execution_end` (`:213`), and the Ph108 reduction's `SurfaceToolCall` drops the output entirely (`runtime.ts:38-42`). Meanwhile Pi's event stream **already carries the real data** — `ToolExecutionStartEvent.args`, `ToolExecutionEndEvent.result`, `tool_result.content` + typed `details` (`node_modules` `types.d.ts:549-570`) — and the Ph109 UI components (`ToolCallView`/`DiffView`/`TestResults`/`TerminalOutput`) already render args/result/diff/test/terminal inertly. The components were **built ahead of the data**: this is a pure nana-side omission, not a missing capability.

## Decision

Thread the real tool data through the **existing engine-neutral layers additively** — no engine-type reshape (honors [[felt-quality-surface]] A1) — and route it to the components already waiting for it.

- **Source (T1, front-loaded spike):** widen the narrowed `PiStreamEvent`, forward `e.args`/`e.result` (capture the rich result + typed `details` via subscribe, else the `tool_result` extension-hook fallback that definitely fires); cap raw output at a documented limit (~16KB) before it enters an `EngineEvent`. The spike confirms the LIVE local-model path delivers args/output AND whether typed `details` populate (resolves ledger A1/A3).
- **Engine-neutral thread (T2, T4):** add `args?`/`output?` (+ optional kind/details) to `SurfaceToolCall` additively; thread them in `applyEngineEvent`; the `SurfaceMessage` must round-trip through `JSON.stringify` (line-protocol safety). Add ONE new union variant `{type:'tool-progress'; id; partial}` for per-step streaming legibility (the "looked frozen" gap) — additive, but every consumer must handle it.
- **Security rail (T3):** every new field renders through `redactSecrets()` on the inert React-string path (the XSS/exfil rail extends to the new untrusted model-adjacent output); a boundary size-cap is load-bearing.
- **Typed routing (T5, T6):** a pure UI-side `mapToArtifact(toolName, output, details)` keyed on tool name routes edit/write→diff, bash→terminal, test-runner→results; degrade to a generic terminal/text artifact when typed `details` are absent on the local path (panel ships either typed or generic, validated by T1's spike).
- **Branding (T7):** generate a simple Nana app icon + regenerate the Tauri icon set; mechanics-only test (felt quality stays the maintainer's call per the UI carve-out).

### Alternatives considered

- **Route typed views in each adapter — REJECTED:** pushes UI presentation vocabulary (view kinds) backwards across the Ph108 engine-adapter invariant ([[engine-adapter-in-process-gate]]) AND duplicates the mapping across both the Pi and Vercel adapters.
- **Defer the typed panel to Phase 111 (inline-only) — REJECTED by the maintainer:** he chose the fuller scope (panel in Ph110, with the generic-text fallback).
- **Adopt Vercel AI Elements for the typed views — REJECTED:** forces a Tailwind/shadcn setup and the custom "owned not adopted" components already exist (Ph109 finding).

## Consequences

- `EngineEvent`/`SurfaceToolCall` + the reduction gain additive fields + one new union variant; **the Vercel adapter + the host/bridge line protocol are the "consumers you didn't touch"** — they must handle `tool-progress` and the payload must stay JSON-serializable.
- More untrusted output now renders → the **redact + inert rail and a boundary size-cap are load-bearing**; the inert-render/CSP tests gain assertions for the new fields.
- The typed panel ships **typed or generic** depending on T1's spike (details-on-local).
- The **gate CORE stays UNCHANGED** — `ConfirmationBroker`/`confirmingGate` ([[gate-confirm-approve-loop]]) and the key-store hard-deny are untouched; this is a visibility/render pass, not a verdict-path change.

### Built outcome + adversarial pre-commit review (2026-06-27)

All 8 tasks landed and an adversarial pre-commit review (6 dimension finders × 2 diverse-lens refuters; 15 findings raised → 6 confirmed → all fixed; 9 correctly refuted) found and fixed real defects the 142-test string-fixture suite had masked:

- **(HIGH) Live-engine wrapper shape** — Pi's real `tool_execution_end.result` / `tool_execution_update.partialResult` are `AgentToolResult` WRAPPER objects (`{content:[{text}], details}`), NOT strings. The adapter forwarded them raw, so the live app would have rendered `{"content":[…]}` JSON noise, the 16KB cap would never fire, and edit→diff would never route. FIXED: `extractToolText()` joins `content[].text` and redacts-then-caps at the adapter boundary (used for both result + partial). The all-string TDD fixtures had hidden this — pin ≥1 test against the REAL upstream event shape (the new full-Pi-path regression test in `tool-visibility-e2e.test.ts`).
- **(HIGH/MED) Redaction rail gaps both directions** — `redact.ts` reworked to CATCH AWS-secret (40-char base64 with `/`) / GCP `AIza…` / JWT shapes now reachable via gate-allowed `bash cat ~/.aws/credentials`/`env`, while EXEMPTING git-SHA / sha256 hash digests it had over-redacted; both directions pinned in `tests/security/redact.test.ts`.
- **(LOW) `looksLikeDiff` tightened** to require diff-header structure (no false-positive on prose bullets); artifact text bounded/redacted at the adapter.

This **RESOLVES ledger A1/A3** (was: open): the live local-model path DOES populate args/output — in `AgentToolResult` wrapper form — and typed `details` (`edit.details.diff`, verified at pi `edit.js:212-216`) are confirmed-available. Ph110 ships the generic-text/diff-shape-heuristic panel; threading the typed `details` for a real structured DiffView/TestResults is the **Phase 111 headline** (de-risked). Health: app suite 108→142 (8 tasks) →157 (6 review fixes), tsc + `npm run build` + `cargo check` all exit 0.

## Source

Phase 110 plan (2026-06-27). Umbrella spec `specs/gui-harness-architecture.md` Rev 2 (Surface + Success Vision + inert-render constraint govern; ADR-named so no separate phase spec). Ledger Phase-110 (all_accept:false — A1/A2/A3 accept, A4 don't-know→defended-accept). Builds on [[felt-quality-surface]], [[webview-engine-bridge]], [[gate-confirm-approve-loop]], [[engine-adapter-in-process-gate]]. UI/felt quality UNMEASURABLE in-kit (Ph59/80) → mechanics-only tests; legibility/joy judged by the maintainer at delivery.
