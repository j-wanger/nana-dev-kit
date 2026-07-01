---
title: "Phase 119 — Pi-UX felt-quality + ecosystem slice: BUILT + adversarially-reviewed"
aliases: [phase-119-built, pi-ux-felt-quality-built]
category: journal
tags: [gui-harness, pi-agent, persistent-session, felt-quality, host-gate, context-meter, compaction, model-picker, thinking-level, phase-119]
parents: [phase-119-pi-ux-felt-quality-ecosystem]
created: 2026-07-01
updated: 2026-07-01
source: debrief
duration: long
---

# Phase 119 — Pi-UX felt-quality + ecosystem slice: BUILT + adversarially-reviewed

## What Happened

All 9 tasks (T1–T9) BUILT + GREEN in one (long, single) session. T1 was a hard VERIFICATION CHECKPOINT: rebuild nana's per-turn EPHEMERAL Pi session (built + `dispose()`d inside every `sendPrompt`) into ONE PERSISTENT build-once/reuse-across-turns session, and PROVE the un-bypassable host gate survives persistence + every session-mutation before building any mutating surface. The **A1 verdict came back SURVIVES — DEFER NOTHING** (three converging sources: compiled-SDK read that `beforeToolCall` is installed once in the ctor and reads `this._extensionRunner` at call time; Pi docs that extensions persist across model change + fire `session_compact` hooks; a LIVE proof that the persistent session blocked a real `rm` on turn 2). The checkpoint was reported to the maintainer, who took a USER-OVERRIDE "continue autonomously T2→T9."

The felt-quality tier (each mutating surface shipped a C3 gate-survives-after test): T2 context%/cost meter (additive-optional `context-usage` event; `projectMeter` renders `percent:null` as '—', no NaN%) + manual `/compact` + the previously-unwired `SpendCeiling`; T3 kept Ph115 restore DISPLAY-ONLY (0 engine sends, proven) + a 'model context reset' marker; T4 model switcher (local↔hosted keeping the local $0 default; env-only hosted auth; launch endpoint probe → header warning) + T5 thinking-level toggle (sharing one `Chip`). The ecosystem tier shipped SAFE defaults: T6 de-duped the double AGENTS.md (`noContextFiles:true` + `assembly.ts` as sole injector) + lean `NANA_CONVENTIONS` via context (NO `systemPromptOverride`); T7 prompt-templates + skills as palette slash-commands that SUBMIT through the gated path; T8 host-orchestrated memory (fail-open, self-disabling, NO model-facing memory tool — CLI-over-MCP stance documented). T9 verified the hosted-`maxTokens` "bug" is not a bug.

## Decisions Made

- [[pi-gate-survives-mutation|Pi host gate survives persistence + session mutation (A1 verdict)]] — resolves ledger A1 (deferred don't-know → held).
- [[hosted-maxtokens-not-a-bug|Hosted maxTokens is NOT a bug (T9)]] — the research finding's truncation hypothesis REFUTED; a uniform override would be the actual bug.
- [[pi-ux-persistent-session-slice|Pi-UX persistent-session foundation + Tier 1/3 slice]] — finalized (Outcome appended; confidence stays high).

## Problems Solved

- **The C3 live check caught a real bug** (DISCOVERY): raw `session.compact()` THROWS "Nothing to compact (session too small)" on a small session → added `isBenignCompactError` (swallow too-small/already-compacted only, propagate real errors).
- **Adversarial gate-bypass review** (6 load-bearing claims re-checked against the diff): ZERO gate-bypass defects. 2 Low nits fixed inline — host `runMutation` try/catch so a mid-turn `/compact` (Pi aborts the in-flight op) can't broadcast a top-level error that nukes running turns (+ compact/cycle-model/cycle-thinking disabled while running); a 5s memory-retrieval timeout + 4s connect cap to enforce the fail-open comment.
- **C1 denial-sink decouple**: the gate denial-sink + subscribe callback both read `this.currentTurn` at call time (swapped per turn), so a turn-N denial reaches turn-N's stream even though the hook was wired once at build.

## Open Questions

- Per-mutation NATIVE gate-survival (setModel/compact/setThinkingLevel exercised LIVE, not just SDK-read) — pending the maintainer live-drive.
- A3 (model-facing memory carve-out) remains DEFERRED — the SAFE host-orchestrated path shipped; revisit if it proves insufficient.
- A4 (`systemPromptOverride`) remains DEFERRED — nana conventions shipped via AGENTS.md/context; revisit if context injection proves insufficient.

## Artifacts Changed

- `app/src/engine/pi/pi-adapter.ts` (persistent build-once session: PiSessionHandle/Builder seam, ensureSession + in-flight guard, C1 denial-sink, compact/setModel/cycleModel/setThinkingLevel/meterSnapshot/listPromptTemplates/listSkills/probeLocalEndpoint, piLoaderOptions noContextFiles:true)
- `app/src/engine/{types,adapter}.ts` (ModelInfo/ThinkingInfo/TemplateInfo/SkillInfo + additive `context-usage` event; optional new/compact/model/thinking/list methods)
- `app/src/host/{engine-host,main}.ts` (new-conversation/compact/model/thinking/session-info inbounds + runMutation wrapper; endpoint probe + optional SpendCeiling + memory retriever)
- `app/src/ui/meter.tsx` (NEW), `app/src/ui/session-controls.tsx` (NEW), `app/src/context/memory-context.ts` (NEW)
- `app/src/context/assembly.ts` (NANA_CONVENTIONS preamble + noContextFiles de-dup); `app/src/ui/{chat-runtime,commands,engine-bridge,App}.tsx`; `app/src/control/spend.ts`
- `.dev-wiki/phase-119/checkpoint-a1-gate-survival.md` (the T1 verdict + delivery addendum)

## Related

- [[phase-119-pi-ux-felt-quality-ecosystem|Phase 119: Pi-UX felt-quality + ecosystem slice]] — parent phase (status active; delivery pending)
- Builds on [[pi-default-engine]] (Ph114), [[conversation-memory-persistence]] (Ph115), [[engine-adapter-in-process-gate]] (Ph108), [[pi-gui-setup-improvements]] (the research finding this phase acts on).

## Soft Observations / Phase 120 candidates

- **T2-tier from [[pi-gui-setup-improvements]]** (deferred this phase): gate-as-HERO legibility (show WHY a call is held + what was snapshotted; "always allow this command in this workspace" scoped trust-mode); file-change timeline (file-undo Pi lacks — nana already snapshots); branching sessions (fork/tree, re-invoked through the gate).
- **A3**: a tight, safe model-facing `memory_*` carve-out (vs host-orchestrated) — verified-first.
- **A4**: a lean appended `systemPromptOverride` (vs AGENTS.md/context only) — verified-first.
- **Review residuals**: defer the eager session-build (`useSessionControls` builds at surface mount) to first-prompt if startup cost matters; reset the meter's cost baseline on new-conversation (spend/meter show $0 while the monotonic ceiling holds the prior cumulative — display-only, fail-safe direction).

## Health

app/ vitest GREEN at 456/456 (61 files, incl. all live gate tests) — grew ~+74 this session across T2–T9 + the review fixes (382 at T1 → 456). `npm run build` (tsc --noEmit + vite) green; `cd src-tauri && cargo check` green. No regressions; the host-gate policy (host-gate.ts) is byte-unchanged.
