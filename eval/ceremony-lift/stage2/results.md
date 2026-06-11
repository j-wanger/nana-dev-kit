# Phase 87 Stage-2 Episode Contrast — Results

Claim ceiling (verbatim): n=1 episode evidence may confirm a cut-candidate into a
REVERSIBLE trim-trial; it may never mint keep or cut.

## What happened (deterministic record)

- Arm B (minimal: assumption gate + enforcement hooks, exploratory prompt): FINISHED in
  996s wall / 26 interrupts / 0 continuations; +3 targeted unit tests; frozen triple
  PASS (393 / 94.51% / gate green) — but its existing golden-master fixture
  (phase6_golden_master.npz) was modified and is LOAD-BEARING (restore-baseline →
  suite fails on golden-master drift; orchestrator-reproduced both directions).
  SHIP-BLOCKED by the validity assertion.
- Arm A (full ceremony: dev-plan → spec → implement → debrief): DNF at 2,106s wall
  (continuation budget exhausted, no ARM_DONE; 22 interrupts incl. 15 ceremony gates) —
  yet its tree passes the frozen triple (394 / 94.58% / gate green), +4 targeted unit
  tests, zero validity violations, and uniquely improved the reader.py coverage rows
  (6 missing artifacts → 2).
- Blinded tie-break: reviewer-confirmed defects 0–0; changed-lines favors arm-b (109 vs
  126); arm-b ship-blocked regardless (above); the golden-master defect was invisible
  to the blinded text review (binary) and was caught by the orchestrator validity sweep.
- Instrument: canary CLEAN (amendment-003 basis), positive control SURFACED by both
  arms (alive but non-discriminating this run), task statements byte-identical,
  isolation probes 6/6, RUN-STATUS LIVE.
- Cost (A3 fallback basis): arm-a consumed 2.1x arm-b's wall-clock; tokens
  NOT-EXTRACTABLE (pty sessions persist title-only transcripts).

## Caveats the disposition must carry

- Bundle attribution: the contrast is full-ceremony-vs-minimal, not spec-vs-no-spec;
  nothing here isolates spec-generation's marginal contribution.
- Canned gates: the ceremony arm ran machinery-only (accept-all-defaults); its DNF is
  partly an artifact of the ceremony's gate cadence meeting a mechanical responder
  (6 idle cycles during/after debrief-shaped work).
- n=1, one substrate, one task shape; the golden-master defect is a single observation
  of the minimal arm cutting an anti-gaming corner that ceremony's reviewers (in-arm)
  did not get the chance to catch either (it was the ORCHESTRATOR's validity sweep,
  part of THIS experiment's apparatus, not either arm's process, that caught it).
- Orchestrator exposure deviation: arm-B gate summary leaked to the orchestrator
  pre-arm-A via the canary probe (steering surface nil — all arm-A inputs byte-pinned
  before arm B ran). Logged in instrument-record.md.
