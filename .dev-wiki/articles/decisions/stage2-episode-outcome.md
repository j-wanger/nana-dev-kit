---
title: "Stage-2 episode outcome: spec-generation=undecidable, ship arm A (Phase 87)"
aliases: [stage2-outcome, phase-87-disposition]
category: decisions
tags: [ceremony, measurement, episode-contrast, disposition, edge-screener]
parents: [phase-87-stage2-episode-contrast]
created: 2026-06-10
updated: 2026-06-10
source: debrief
confidence: high
---

## Context

Phase 86's checkpoint left `spec-generation = ambiguous-stage-2` ([[ceremony-step-verdicts]])
and routed a stage-2 episode contrast: full-ceremony arm A vs minimal (assumption-gate+hooks)
arm B on burnable edge-screener Phase 10, executed verbatim from the byte-frozen
`## Stage-2 parameters` (9ad62f0). The claim ceiling was pinned up front: n=1 episode
evidence may confirm a cut-candidate into a REVERSIBLE trim-trial; it may never mint keep
or cut. The maintainer took the disposition at the T7 HARD checkpoint, in the closed
vocabulary, on the committed ship/cost tables with all caveat columns presented.

## Decision

**spec-generation = UNDECIDABLE** — the episode did not resolve the Phase-86
ambiguous-stage-2 verdict in either direction:

- Arm B (minimal: 996s wall, FINISHED, frozen triple PASS 393 tests / 94.51% cov) won the
  pinned changed-lines tie-break but was **SHIP-BLOCKED** by the orchestrator validity
  sweep — its modified golden-master fixture `phase6_golden_master.npz` proved
  LOAD-BEARING (restore-baseline → golden-master drift failure, reproduced both directions).
- Arm A (full ceremony: 2,106s total wall, DNF on the done-sentinel) passed the triple
  (394 / 94.58%), added 4 targeted tests vs 3, uniquely improved reader.py coverage rows
  (6→2 missing artifacts), zero validity violations — its work **SHIPPED** to edge-screener
  as a6effcb via the separate ship checkpoint.
- Canary CLEAN (amendment-003 basis); positive control alive but non-discriminating
  (both arms surfaced it).

Caveats absorbed at the checkpoint: bundle attribution (full-ceremony-vs-minimal, not
spec-vs-no-spec), canned gates (machinery-only ceremony; the DNF is partly a gate-cadence
artifact), n=1.

## Consequences

- The Phase-86 ambiguous verdict STANDS; nothing minted, no trim-trial confirmed.
- The queued trim follow-on round proceeds on stage-1 evidence alone; per-cut checklists
  are unaffected by this episode.
- Ship decision was a separate gate: arm A's Phase-10 work shipped (DNF was a
  done-sentinel failure, not a quality failure); arm B ship-blocked; the seeded control
  registration shipped with neither arm (experiment apparatus).
- Evidence: `eval/ceremony-lift/stage2/{ship-table,cost-table,results,instrument-record}.md`.
