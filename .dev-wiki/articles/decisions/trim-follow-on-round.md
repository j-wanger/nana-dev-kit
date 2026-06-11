---
title: "Trim Follow-On Round (Phase 88)"
aliases: [trim-follow-on-round, phase-88-decision]
category: decisions
tags: [subtraction, trim-trial, ceremony, hooks, memory, deregistration, checkers, harness-right-sizing]
parents: [phase-88-trim-follow-on]
created: 2026-06-11
updated: 2026-06-11
source: plan
confidence: high
---

## Context

Phase 86's stage-1 verdicts queued two ceremony trims (dev-plan-orchestration = trim: the
ride-alongs; debrief-capture = trim: the knowledge-capture half) and Phase 87's disposition
(spec-generation = undecidable, nothing minted) released the round to proceed on stage-1
evidence alone. Four prune-on-value leftovers are evidence-armed in Blockers, and Phase 87's
review gate routed three stage-2 checker tightenings here. Spec
`specs/phase-88-trim-follow-on.md` (nana:approved 2026-06-11) pins the claim ceiling
(reversible trim-trials, never permanent cuts/keeps), the coupled-verdict ordering, the
stage-2 three-file allowlist, and zero-cuts-valid.

## Decision

Verdict-table-first, serialized execution — the Phase-83 method extended with trim-trial
reversibility, five stages:

- **Stage 1 (tasks T1-T2) — evidence + verdict table before anything:** ~10 candidate rows (strand 1 decomposed:
  active-knowledge ride-along, state-loader/artifact-writer heft; strand 2 NARROWED BY GATE
  A6: working-knowledge seeding, journal prose — the memory bridge/harvest writers are
  deferred with the layer question; 3 leftovers — the memory-layer disposition was REMOVED
  from scope by gate A4 reject; 3 checker tightenings), phase-base SHA in the header. Per row: evidence citation with a provenance-filtered re-snapshot of
  enforcement.log (count drifted 69→385 through kit-planning sessions). The filtering
  mechanism is named, not assumed: timestamp cross-reference of log records against session
  transcript windows and memory.db write times; block→follow-through (DRQ-1) is answerable
  only by pairing block events with subsequent memory_store evidence. PRE-STATED FALLBACK:
  if provenance and follow-through cannot be reconstructed, the enforce-memory disposition
  is `undecidable-on-this-evidence` — never argued from the raw 385 count (the decision-only,
  provenance-free schema is itself a T1 finding). Also per row: couldnt-fire vs didnt-fire
  classification for load-bearing zeros; removal set + liveness grep — KNOWN coupling
  pre-listed at T1, not rediscovered mid-execution: `session-start.sh:110` clears detect-loop
  state AND the enforce-memory marker in one rm line, so both rows carry the split
  explicitly; revert trigger + observation window + Blockers re-trigger for trims, with
  per-trim DISTINGUISHABLE signals where possible and joint attribution acknowledged in the
  filings where windows overlap; reader-surface degradation check for the active-knowledge
  ride-along (~15 reader surfaces — graceful-on-absent verified and the enumeration committed
  as an `eval/trim-round/` artifact, else the row's mechanism changes). The memory-layer
  reference-surface enumeration (20 surfaces) defers with the layer disposition.
- **Stage 2 (task T3) — checker tightening strand (cheapest, independent):** seeded-defect + clean +
  boundary fixtures under `eval/trim-round/checker-fixtures/` FIRST (controls-first; a
  tightened checker that passes its seed is instrument-dead and ships nothing); then edit
  only the three routed files; allowlist + cmp byte-identity check on everything else.
  Controls-first applies to ALL new apparatus checkers, not just the routed three:
  check-verdict-table.sh gets a seeded bad-row fixture, check-ghost-registrations.sh a
  seeded ghost fixture, before either vouches for anything.
- **Stage 3 (task T4) — unconditional HARD checkpoint:** full verdict table to the maintainer before any
  trim/cut/harden executes; couldnt-fire candidates presented as defects with no cut offered;
  any contradiction of a standing decision (memory-architecture-classification) surfaced for
  explicit supersession.
- **Stage 4 (task T5) — serialized execution of approved verdicts:** one commit per candidate; sandbox-
  rehearsed revert (SHA recorded) + basename-normalized deregistration with positive control
  + ghost sweep over all discovered surfaces (incl. settings.local.json) + survivor smoke +
  regenerated-diff ⊆ removal set. The coupled memory verdicts were resolved AT THE GATE
  rather than left to execution ordering: the layer disposition is deferred (A4 reject) and
  the bridge/harvest writers stay alive with it (A6 reject — clean future demand evidence
  beats trimming the writer now), so no dead-mandate or evidence-laundering pairing can
  arise this phase; enforce-memory's own disposition (A3 attempt+fallback) proceeds against
  a live layer.
- **Stage 5 (task T6) — close-out:** exit-criteria runner ALL-PASS, working-knowledge superseded entries,
  per-trim Blockers filings (re-trigger = end of observation window), baseline-pin note that
  the trim commits are the new harness baseline for any future ceremony measurement.

Trim mechanism: **deletion with rehearsed revert**, not lite-ceremony demotion. The config-
flip alternative was considered and rejected — it leaves the trimmed machinery as
registered-but-dormant surface (the kit's 4×-bitten failure class) and the dormant code rots
unseen. Demotion remains a per-row fallback ONLY where a reader surface cannot degrade
gracefully and same-commit cleanup is disproportionate.

Direction gate (assumption-approval; ledger block appended, all_accept: false — closed
2026-06-11): A1 accept; A2 accept-spike-defended (severability demonstration opens task T3);
A3 accept-attempt+fallback (undecidable-on-this-evidence is a valid landing); A4 REJECT —
memory-layer disposition removed from scope, deferred with updated filing; A5 accept;
A6 (re-surfaced after A4) REJECT — bridge/harvest writer trims deferred with the layer,
strand 2 narrowed to working-knowledge seeding + journal prose.

## Consequences

The per-session ceremony surface shrinks (planning ride-alongs, debrief capture) while the
direction gate and delivery gate are untouched; every removal carries a working revert path
and a dated restoration review. The wk-prune curator is unaffected by the seeding trim
(separate kept surface per [[extend-wk-prune-not-new-hook]]); with both seeding surfaces
trimmed, working-knowledge becomes a decaying-static cache — consistent with the
amplifier-null evidence that re-presentation does not earn its tokens. Future ceremony
measurements must cite the trim commits as the new baseline, and the eval corpus baseline
moves with any hook cut (52→47 if both detect-loop and enforce-memory scenarios go —
spec-anticipated explained denominator change). Residue (undecidable
dispositions, user-owned reference surfaces) is filed with named re-triggers.
