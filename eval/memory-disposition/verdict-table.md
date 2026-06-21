# Phase 95 verdict table — Memory-Layer Disposition (Reconcile-and-Close)

phase-base: 45cb12b (Phase 94 delivery-accepted)
checked by: `run-exit-criteria.sh` (controls-first `--selftest`; clean-on-seed = instrument-dead)

**Row schema is PINNED — the exit-criteria greps anchor on column 2; do NOT add columns before the
verdict.** Component section enum: `keep | cut | harden | disable-at-boundary | redesign |
deferred-inadmissible`. Trim section enum: `confirm | restore`. Per-row structured fields that the runner
checks (`SURVIVOR-SMOKE:`, `supersedes:`, `enforce-memory-zero-class:`, `unreachable-installs:`) live as
standalone marker lines BELOW the table, never as extra columns. Evidence cells use no literal `|`.

This is a **reconcile-and-dispose-then-close** round (NOT a shrink hunt): every open memory-layer obligation
gets ONE recorded, evidence-cited verdict; keeps are valid outcomes. The cut-execution rails are conditional
— they arm only if a destructive verdict fires.

## Component dispositions

| id | verdict | evidence |
|---|---|---|
| memory-mcp-layer | keep | eval/memory-remeasure/memory-demand-remeasure.md — Phase-94 re-measure REVERSED the demand-zero premise; coerced demand value-bearing (cross-session read-back 10/10 aml-casework, 25/28 aml-substrate) in 2 of 3 live consumers. MCP-specific (mcp__memory__ calls / .memory/memory.db rows), NOT native auto-memory. |
| bridge-writer | keep | KEEP-by-affirmation (ledger Phase-95 A3): the Phase-94 consumer reversal + the writer's cheapness/liveness affirm keep without a kit-side audit. Evidence-split asymmetry — consumer evidence may KEEP a kit-side writer (safe direction) but not CUT one; no subsystem-zero (0 reinforcements / access_count~0 = couldnt-fire, fastembed-gated) cited as demand. |
| harvest-writer | keep | KEEP-by-affirmation (ledger Phase-95 A3) — same basis as bridge-writer; debrief memory-harvest is cheap and live. |
| enforce-memory | redesign | T3 maintainer checkpoint (2026-06-21) on enforce-memory-audit.md (~55% of bites drive a real same-session search; marker gameable) + redesign-spike.md (SPIKE: PASS). Replaced the agent-touched `.claude/.memory-consulted` existence check with a transcript assertion: a real assistant tool_use memory_search with ts >= ~/.claude/.session-start-ts (det-vs-LLM Principle 2 — assert the artifact, not the narration; per-session freshness fixes the resumed-session stale-pass; fail-open). jq-only, never grep (catalog excluded). |

## Trim-trial dispositions

| id | verdict | evidence |
|---|---|---|
| ak-ride-along | confirm | eval/dogfood-round/evidence/window-events.md — windows closed CLEAN, ZERO trigger-matching events Phases 88-93 (no `event: filed` row); trim-round-outcome (d43950f). Make permanent / stop tracking; no revert. |
| wk-seeding | confirm | eval/dogfood-round/evidence/window-events.md — ZERO trigger events Ph88-93; REVERT-COUPLED with ak-ride-along (df3e623). Confirm (a restore would take both reverts atomically + test_companions.sh). |

SURVIVOR-SMOKE: PASS
supersedes: enforce-memory@Phase-88 (Ph88 kept it on 3/7 block follow-through; the Ph95 audit corrects that to ~55% per-episode value + a window-sensitive 35-70% per-bite band AND confirms the marker is gameable by construction; the redesign keeps the hook but asserts a REAL memory_search event instead of marker-existence — a reversal of the mechanism, not the keep)

Notes:
- The redesign edits hook CODE: templates/.claude/hooks/enforce-memory.sh (+ installed ~/.claude copy, drift 0).
  Tests: tests/test_tooluse_hooks.sh (5 paired incl. a stale-pass freshness guard) + tests/test_firing_log.sh
  (3 block tests moved to a no-search transcript). Eval: hook-enforce-memory-{allow,block} scenarios moved to
  the transcript contract; denominator UNCHANGED at 50/50. Firing reasons: memory-consulted -> memory-searched
  (allow) + no-transcript (fail-open allow); block reason no-memory-search unchanged.
- FOLLOW-UP (filed, not in-phase): session-start.sh:110 `rm -f .claude/.memory-consulted` is now vestigial
  (the gate no longer reads the marker) — harmless, removal deferred to avoid touching the session-start
  surface this phase.
- Honest limit (from redesign-spike.md): still a fail-open relevance NUDGE — one real memory_search since
  session start satisfies it. It hardens gameability (a real event, not a bare file-touch); it is not a hard
  guarantee.
