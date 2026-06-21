---
title: "Memory-Layer Disposition (Phase 95)"
aliases: [memory-layer-disposition, phase-95-disposition, reconcile-and-close]
category: decisions
tags: [memory, disposition, subtraction, enforce-memory, trim-trial, det-vs-llm]
parents: [phase-95-memory-layer-disposition]
created: 2026-06-20
updated: 2026-06-21
source: plan
confidence: high
---

## Context

Phase 95 is the disposition the Phase 92→94 arc was built toward. The Phase-92
[[strategic-inflection-review]] mandated "re-measure-once-then-shrink" because the Phase-89
consumer memory demand-zero was COULDN'T-FIRE (memory was broken in consumer cwds until the Ph91
PYTHONPATH fix; that zero was inadmissible — [[HEU-012]]). Phase 94 ran the clean re-measure
([[consumer-memory-remeasure]]; `eval/memory-remeasure/memory-demand-remeasure.md`) and it
**REVERSED the "consumer demand is zero" premise**: on the repaired global memory MCP the
coerced/announced demand is substantial and VALUE-BEARING (cross-session read-back 10/10
aml-casework, 25/28 aml-substrate) in 2 of 3 live consumers; the spontaneous floor (signal-watch,
no rules/hooks) is ≈0. The old `specs/phase-92-memory-layer-prune.md` was shaped as a CUT apparatus
on the demand-zero premise; that premise is gone, so this round **supersedes** it and re-shapes the
long-deferred prune into a reconcile-and-close round (the subtraction test applied to the spec
itself: a keep-leaning disposition is not dressed as a cut apparatus).

The open obligations to close: assumption-ledger Phase-83 A5 (`revisit-status: open` — kit-side
memory-layer value), Phase-88 A4 (kit-side memory-MCP-layer disposition) + A6 (bridge/harvest writer
trims) + A5-trim, the Phase-83 enforce-memory keep-with-revisit, and the two Phase-88 trim-trials
(ak-ride-along `d43950f` + wk-seeding `df3e623`, REVERT-COUPLED) whose windows closed clean at
Phase 93. Success = no obligation left silently open, whatever the verdicts.

## Decision

Adjudicate EVERY open memory-layer obligation to a single recorded, evidence-cited closed-enum
verdict in `eval/memory-disposition/verdict-table.md` (row schema PINNED: `| <id> | <verdict> |
<evidence> |`, verdict in column 2). Most rows are evidence-cited re-affirmations:

- **memory-mcp-layer = KEEP** — on the Phase-94 consumer reversal (MCP-tool demand specifically, not
  Claude Code native auto-memory).
- **bridge-writer + harvest-writer = KEEP-by-affirmation** — the consumer reversal + cheapness, NOT
  a fresh kit-side store audit (the maintainer rejected the audit requirement at the direction gate).
  Evidence-split asymmetry is stated: consuming-project evidence may KEEP a kit-side writer but may
  NOT CUT one.
- **ak-ride-along + wk-seeding = CONFIRM** — windows closed clean (ZERO triggers Ph88–93); restore
  would take both (REVERT-COUPLED).

The one genuine investigation is **enforce-memory** — the single live fork
(`keep | redesign | retire`), decided at a HARD maintainer checkpoint on (1) a deterministic
firing-distribution audit (allow/block ratio + block→real-`memory_search`-follow-through vs ritual
marker-touch, counted via JSON `tool_use` never grep, positive-control-gated) and (2) a redesign
feasibility spike (can a PreToolUse hook deterministically assert a prior in-session `memory_search`?
— det-over-narration per [[deterministic-vs-llm-boundary]] Principle 2). `redesign` is on the menu
only if the spike records `SPIKE: PASS`. The cut-execution rails are CONDITIONAL — they arm only if a
destructive verdict fires (the only destructive path left is enforce-memory retire: low-hazard —
un-blocks, no store backup, no self-lockout since the layer keeps).

Rejected alternatives: inheriting the phase-92 full cut apparatus (subtraction test — most verdicts
keep); a fresh kit-side store audit for the writers (maintainer rejected → keep-by-affirmation);
restoring the trim-trials (windows clean → confirm).

## Consequences

- The assumption ledger's memory rows finally close their revisit loop: the Phase-83 A5
  `revisit-status: open → held` flip (the only authorized prior-block edit; `held`/`bit` are the
  schema-valid targets — there is NO `closed` token), Phase-88 A4/A6 via Blockers + the verdict table,
  Phase-88 A5-trim via the trim CONFIRM. The phase-92 spec is cleanly superseded (note, not deletion).
- A non-`keep` enforce-memory verdict must carry `supersedes: enforce-memory@Phase-88 (<delta>)` —
  the standing Phase-88 keep ([[trim-round-outcome]]) is superseded-not-contradicted. A destructive
  verdict classifies its firing zero couldnt-fire vs didnt-fire BEFORE execution ([[HEU-012]]).
- Zero destructive verdicts (all keep + confirm) is a fully valid outcome — verdicts are
  evidence-forced, not quota-driven. Zero kit code change UNLESS enforce-memory is redesigned/retired.
- Cross-links: [[consumer-memory-remeasure]], [[strategic-inflection-review]],
  [[deterministic-vs-llm-boundary]], [[trim-round-outcome]], [[prune-on-value-subtraction]],
  [[HEU-012]].

## Outcome (executed 2026-06-21, commits 3d401d5 + b960c70)

All obligations closed; verdict table `eval/memory-disposition/verdict-table.md`:
- **memory-mcp-layer KEEP**, **bridge-writer KEEP**, **harvest-writer KEEP** (keep-by-affirmation per A3).
- **enforce-memory REDESIGNED** (T3 maintainer checkpoint, on enforce-memory-audit.md ~55% per-episode value
  + the gameable marker, and redesign-spike.md SPIKE: PASS): the agent-touched `.claude/.memory-consulted`
  existence check is replaced by a transcript assertion of a real `memory_search` (`type==assistant` tool_use)
  with `ts >= ~/.claude/.session-start-ts` — det-vs-LLM Principle 2 + per-session freshness (fixes the
  resumed-session stale-pass; sessionId is stable across --resume, so .session-start-ts is the anchor, not
  sessionId). jq-only, fail-open. Supersedes the standing Phase-88 keep. Honest limit: a fail-open nudge —
  one real search per session satisfies it.
- **ak-ride-along (d43950f) + wk-seeding (df3e623) CONFIRMED** permanent.

Ledger Phase-83 A5 `open->held`; Phase-88 A4/A6 + the trim re-triggers + the enforce-memory resume-artifact
harden-candidate resolved. The Phase-95 ultracode adversarial verification corrected a window-gamed 71% audit
headline to the honest 55%/35-70% band and surfaced the stale-pass that shaped the freshness bound.
