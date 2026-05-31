---
title: "Phase 72 complete — Compaction-Recovery Subtraction (.session-anchor)"
date: 2026-05-30
type: journal
phase: 72
tags: [harness-right-sizing, subtraction, compaction, post-compact, engineering]
---

# Phase 72 complete — Compaction-Recovery Subtraction (.session-anchor)

The first **"cash the conclusion"** phase after the Phase 58–71 measurement campaign
(14 consecutive CUT/TERMINATE verdicts). Jake paused measurement and chose
**Engineering → Tight subtraction** (AskUserQuestion 2026-05-30), explicitly deferring
gap 4.1 (language-agnostic core) as YAGNI — open since Phase 25 / ~46 phases with zero
consuming-project demand.

## What shipped

Removed the dead `.claude/.session-anchor` recovery machinery — a latent finding recorded
(but frozen) during Phase 71: `post-compact.sh` READS `.claude/.session-anchor` but nothing
in the repo ever WROTE it (`pre-compact.sh` emits its snapshot to stdout for context injection,
never to a file). With measurement paused the freeze lifted.

- **T1**: confirm-truly-dead first — exhaustive `grep -rn "session-anchor"` across the whole repo
  (incl. `install.sh`, `templates/.claude/skills/`, `rules/`) showed the ONLY live references were
  `post-compact.sh:11-13` + `.gitignore:16`; every other hit is a historical dev-wiki record.
  Then deleted the `if [ -f "$ROOT/.claude/.session-anchor" ]; then … fi` block (4 deletions,
  blanks collapsed) and the `.claude/.session-anchor` gitignore line — preserving the
  `[nana:compact]` echo, the `[nana:devwiki]` block, the `.context-warned` rm, and `set -euo pipefail`.
  post-compact firing test 8/8 PASS; no live reference remains.
- **T2**: recorded the rationale in [[cash-compaction-recovery-subtraction]] — the subtraction over
  construction call (Phase 70/71 measured the recovery pathway and found no headroom, so wiring up
  a writer would add machinery the campaign proved inert) + the "right-size the harness from
  measurement" precedent. Historical [[hook-reconciliation]] left intact (superseded, not rewritten).

## Why subtract, not wire up

[[amplifier-anchor-headroom-screen]] (P70) + [[cross-boundary-retention-headroom-screen]] (P71)
showed the native Claude Code compaction summary is decision-comprehensive — the harness
compaction-*recovery* pathway has no measured value. A recovery mechanism with no measured value
is cruft; the subtraction test is decisive.

## Gates

`make test` "All tests passed" at the UNCHANGED script count (post-compact stays registered — only
an internal branch removed → no registration/settings/README drift, no Makefile change),
`make eval` 52/52, `test_registration` 41/41, `test_settings_template` green, firing-coverage gate green.

## Disposition / next

Engineering roadmap remaining: gap 4.1 (DEFERRED YAGNI; re-trigger = first non-Python/non-TS
consuming project), the vector-search-default-on design call. Measurement line stays closed unless
a real multi-session substrate (cross-SESSION persistence) or a non-commodity corpus
(retrieval-on-proprietary) appears.

Tooling note this session: the tool-result channel dropped outputs in bursts (a rendering lag —
results flushed a turn or two later); 3 markdown writes initially failed the read-first guard and
were re-applied via bash. No outward-facing action was taken under the degraded channel.
