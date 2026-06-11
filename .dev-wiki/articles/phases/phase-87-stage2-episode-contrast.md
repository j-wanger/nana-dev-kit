---
title: "Phase 87: Ceremony Stage-2 Episode Contrast"
aliases: [phase-87, stage2-episode-contrast]
category: phases
tags: [ceremony, measurement, episode-contrast, stage-2, edge-screener]
parents: [phase-86-ceremony-lift-measurement]
created: 2026-06-10
updated: 2026-06-10
source: plan
status: active
scope: ["eval/ceremony-lift/stage2/**", ".dev-wiki/articles/phases/phase-87-stage2-episode-contrast.md"]
entry_criteria: "Phase 86 delivery accepted (6728e2f); STAGE-2 go verdict recorded in [[ceremony-step-verdicts]]; spec specs/phase-87-stage2-episode-contrast.md nana:approved"
exit_criteria: "bash eval/ceremony-lift/stage2/run-exit-criteria.sh exits 0 (8 machine-checkable criteria in the spec)"
---

# Phase 87: Ceremony Stage-2 Episode Contrast

## Objective

Execute the pre-registered stage-2 episode experiment frozen in
`eval/ceremony-lift/pre-registration.md` `## Stage-2 parameters`: full-ceremony arm
(dev-plan → spec → implement → debrief) vs minimal arm (assumption-approval gate +
enforcement hooks, exploratory prompt) on burnable edge-screener Phase 10, producing
admissible episode evidence for the maintainer's disposition of the
`spec-generation = ambiguous-stage-2` verdict. Claim ceiling: n=1 may confirm a
cut-candidate into a REVERSIBLE trim-trial only — never mint keep or cut.

## Scope

Files and modules affected:
- `eval/ceremony-lift/stage2/**` (NEW, additive only — no stage-1 file edited)
- Out-of-repo, HARD-checkpoint-gated: edge-screener twin worktrees/clones from pinned
  SHA 368e056; one positive-control seed write into edge-screener's dev-wiki; gated
  ship step for the better arm
- Read-only: edge-screener arm transcripts (programmatic parsing only), stage-1 cost
  extractor (reused as-is), kit skills/hooks as the measured apparatus
- Phase article verdict block: maintainer's spec-generation disposition (closed
  vocabulary: confirm-trim-trial | not-confirmed | undecidable | instrument-dead | void)

## Exit Criteria

- [ ] Frozen pre-registration byte-intact; stage-1 apparatus additive-only (spec criterion 1)
- [ ] Execution-protocol addendum's first add-commit strictly precedes results' add-commit, byte-unchanged between (criterion 2)
- [ ] `bash eval/ceremony-lift/stage2/check-instrument.sh` (restoration, isolation probe, canary, positive control) (criterion 3)
- [ ] `bash eval/ceremony-lift/stage2/check-ship-table.sh` (criterion 4)
- [ ] `bash eval/ceremony-lift/stage2/check-cost-table.sh` (criterion 5)
- [ ] `bash eval/ceremony-lift/stage2/check-claim-ceiling.sh` (criterion 6)
- [ ] `bash eval/ceremony-lift/stage2/check-substrate-intact.sh` (criterion 7)
- [ ] `git diff --quiet 6728e2f..HEAD -- templates/ scripts/ install.sh modules.json Makefile` (verdicts/evidence-only; kit-commit embargo) (criterion 8)

All aggregated by `bash eval/ceremony-lift/stage2/run-exit-criteria.sh`.

## Constraints

- Parameters FROZEN in the Phase-86 pre-registration (byte-frozen since 9ad62f0) —
  executed verbatim, never re-litigated; execution mechanics pinned by the addendum
  BEFORE any arm runs (prevents post-hoc retrofit).
- Kit-commit embargo across the experiment window (prevents the full-ceremony arm
  measuring a moving target).
- Leak canary in arm B (DRQ-1 question) — correct answer voids the run; positive
  control must surface in the ceremony arm or the instrument is DEAD, not null.
- Claim ceiling embedded verbatim in every summary artifact, deterministically checked.
- Arm transcripts parsed programmatically only — never loaded into agent context.

## Checkpoints

- HARD checkpoint before ANY out-of-repo write (worktree creation, dev-wiki seed, ship step — each its own gate).
- Instrument validation sequenced FIRST; STOP on restoration failure, isolation-probe failure after 2 addendum fixes, canary contamination (VOID), dual-arm control miss (INSTRUMENT-DEAD), or any post-unblinding apparatus defect (VOID).
- HARD checkpoint (the phase's center): maintainer takes the spec-generation disposition inside the closed vocabulary.

## Assumptions

- A1: edge-screener at 368e056 still matches the frozen baseline (390 tests, 94.44% coverage). If drifted: STOP and re-present.
- A2: "twin worktrees" admits an isolation-correct implementation. If clones ruled unfaithful AND worktrees can't pass the probe: STOP.
- A3: stage-1 cost extractor parses edge-screener arm transcripts. If false: down-scope token columns to NOT-EXTRACTABLE.
- A4: dev-wiki positive-control seed is an acceptable out-of-repo write. If rejected: STOP and re-present.
- A5: two same-model budget-capped sessions are drivable to completion. Budget exhaustion mid-arm → DID-NOT-FINISH row, not a re-run.

## Notes

Created as a planning stub by the dev-plan state loader (2026-06-10); distilled from
`specs/phase-87-stage2-episode-contrast.md` (nana:approved 2026-06-10). Substrate
observations at stub time: edge-screener HEAD == 368e056 but the working tree is
DIRTY (Phase-85 hook/settings migration uncommitted; `settings.local.json` gitignored;
`.dev-wiki/phase-10-candidate-analysis.md` untracked) — worktrees cut from 368e056
will not carry the migrated kit install or the Phase-10 task analysis. Resolved at
planning by the three maintainer rulings in [[stage2-episode-execution-design]]
(independent clones from a checkpoint-gated setup commit with parity provisioning;
standing phase-exit gate as the ship-runner referent; canned orchestrator-mediated
gate inputs) plus addendum-pinning and the T1 drivability spike.

**Direction gate closed 2026-06-10** (assumption positions: A1-A3 accept, A4
accept-spike-defended round 2, A5 accept; all_accept: true). Planned 2026-06-10:
8 tasks (M/M/M/M/L/M/M/S), decision [[stage2-episode-execution-design]] (high).
