---
title: "Phase 109: Felt-Quality Surface + Branding"
aliases: []
category: phases
tags: [gui, surface, assistant-ui, ai-elements, context-assembly, felt-quality, tauri]
parents: [phase-108-gui-harness-v1-thin-slice]
created: 2026-06-26
updated: 2026-06-26
source: plan
status: active
scope: ["app/src/ui/**", "app/src/context/**", "app/src/App.tsx", "app/src-tauri/**", "app/package.json", "app/tests/ui/**", "app/tests/context/**"]
entry_criteria: "Phase 108 delivered + accepted (engine + rails proven headlessly, 63/63). App surface is a placeholder App.tsx; assistant-ui / AI Elements not installed; no context-assembly layer."
exit_criteria: "Drivable v1 surface: ui/chat-stream + context/assembly + ui/gate-confirm + ui/artifacts-revert PASS; inert-render still green; full app suite green; npm run build exit 0; Tauri window launches (maintainer visual check). Felt-quality ships on maintainer judgment."
---

# Phase 109: Felt-Quality Surface + Branding

## Objective

Turn Phase 108's placeholder `app/` surface (`App.tsx` is a literal `<h1>`) into a real, drivable assistant-ui + Vercel-AI-Elements desktop surface that makes the already-built rails **felt** — the 5 control/joy axes from the architecture spec's Success Vision — bound to the existing engine-neutral `runtime.ts` reduction. Plus the minimum context-assembly seam so the harness isn't project-blind on first dogfood. The felt-quality slice of THE PIVOT; mechanics tested, joy/control judged by the maintainer at delivery.

## Scope

- `app/src/ui/**` — assistant-ui custom runtime + AI Elements views (chat, gate-confirm, diff/test artifacts, revert)
- `app/src/context/**` — minimum context-assembly (workspace `AGENTS.md`/`CLAUDE.md` + `.claude/rules/*.md` → per-turn system context)
- `app/src/App.tsx` — composed surface
- `app/src-tauri/**` — real app icon/branding + window launch
- `app/tests/ui/**`, `app/tests/context/**` — mechanics tests

**OUT:** command palette + rich keyboard shortcuts (axis 3, deferred — A5); dev-wiki/memory-search context-assembly beyond the always-loaded rules files; signed/notarized bundle (Phase 110+); the Claude Agent SDK adapter (gated on an API key).

## Exit Criteria

- [x] `app/tests/ui/chat-stream` — a streamed engine response renders incrementally with tool-call/tool-result/denied states; tool output renders inert (axis 4) — 9/9
- [x] `app/tests/context/assembly` — the active workspace's `AGENTS.md`/`CLAUDE.md` + `.claude/rules/*.md` are assembled into the engine's per-turn system context; a workspace with none yields a loud unavailable state (not silent-blank) (A2) — 5/5
- [x] `app/tests/ui/gate-confirm` — a held destructive gate event surfaces a blocking allow/deny dialog with the action + diff; deny blocks (no side effect); content inert (axis 1) — 5/5
- [x] `app/tests/ui/artifacts-revert` — a file-diff tool result renders in diff/CodeBlock; a test run renders in TestResults; the revert control invokes `CheckpointStore.revert` → pre-edit bytes (axes 5 + 2) — 5/5
- [x] `app/tests/security/inert-render` still green (no XSS regression from the new surface)
- [x] Full app suite green (108/108); `cd app && npm run build` exit 0 (tsc + vite); `cargo check` PASS
- [ ] Criterion #1 — `npm run tauri build` produces a bundle that **launches** (compile-proven; the **live end-to-end window round-trip is UNVERIFIED** — the maintainer's deferred delivery-time launch check)
- [ ] Felt-quality / joy + sense of control — maintainer judgment at the delivery gate (Ph59/80 carve-out; unmeasurable in-kit)

## Constraints

- **A1 — bind a custom runtime to the existing `applyEngineEvent`/`reduceEngineEvents` reduction WITHOUT reshaping Ph108's tested engine types.** Front-loaded as integration spike T1. If the binding forces a reshape → STOP, fall to AI-SDK-data-stream-shape binding. Prevents churning proven engine-neutral code for UI convenience.
- **Preserve T6 inert-render + strict CSP** — the new surface keeps rendering model/tool output inert (never `innerHTML` of model/tool content). Prevents the GUI XSS→RCE class the spec warns about.
- **Context-assembly is loud-on-missing** — a workspace with no project files surfaces a loud "no project context," never silently context-blank. Mirrors the memory-unavailable-loud discipline. Prevents a project-blind agent masquerading as context-aware.
- **Gate / checkpoint / engine logic UNCHANGED** — the UI wires to the existing surface events only; no gate-logic, checkpoint, or engine-neutral type changes. Prevents a UI phase silently weakening the security rails.

## Checkpoints

- After the T1 integration spike (custom runtime bound, a streamed response renders incrementally): report. If the binding forces reshaping the tested engine layer → STOP and escalate (A1 fallback = AI-SDK-data-stream binding), maintainer decision.
- At delivery: the maintainer launches the window and judges felt-quality / joy + control (the carve-out; not an in-kit test).

## Assumptions

See ledger Phase-109 (all_accept: false). A1 (custom-runtime binds without engine reshape — accept, spiked T1) · A2 (minimum context-assembly in-scope — maintainer-directed reject→revised) · A3 (mechanics-only exit criteria; felt ships on judgment — accept) · A4 (architecture spec Rev 2 is the umbrella spec — accept) · A5 (minimum-first depth, defer axis 3 — accept).

## Outcome (BUILT 2026-06-26 — READY FOR COMPLETION)

All 6 tasks [x] (T6 discovered mid-phase, maintainer-approved); delivery ACCEPTED ("I'll do the verification later, anything feels off can be fixed next phase"). Status stays `active` — the delivery gate flips after the commit lands. **A1 spike resolved CLEAN** (zero engine-type reshape; the AI-SDK fallback never needed). Two discovered, maintainer-approved scope additions earned decisions: [[gate-confirm-approve-loop]] (T3 — real host-owned approve-loop; the gate had no held-call resolution path) and [[webview-engine-bridge]] (T6 — a Rust-spawned Node sidecar makes the harness genuinely drivable; Ph108's daily loop had only run in Node tests). App tests 63→108 green; tsc+vite+cargo check exit 0; inert-render/CSP/capability guard unbroadened. **UNVERIFIED:** the live end-to-end window round-trip (the maintainer's deferred launch check). Ledger Phase-109 all `held` (A1 open→held; none bit). See journal `2026-06-26-phase-109-felt-quality-surface`.

## Notes

Umbrella spec: `specs/gui-harness-architecture.md` (nana:approved, Rev 2) — its **Surface** section (assistant-ui + AI Elements: Terminal/FileTree/TestResults/diff), **Success Vision** (the 5 control/joy axes), and **Exit criterion #1** govern this slice. Decision [[felt-quality-surface]] (high). Built on Phase 108's already-tested rails (gate deny/modify/confirm, `CheckpointStore`, the engine-neutral event reduction). Use the `frontend-design` skill for aesthetic direction (distinctive, not templated-default).
