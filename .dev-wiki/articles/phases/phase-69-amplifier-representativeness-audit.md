---
title: "Phase 69: Amplifier Measurement — Representativeness Audit + Anchor-Validity Verdict"
aliases: [phase-69, amplifier-representativeness-audit, anchor-validity-verdict, measurability-gate]
category: phases
tags: [eval-validity, amplifier-vision, measurement, representativeness, anchor-validity, phase-69]
parents: []
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope: ["eval/amplifier/*", "specs/*", ".dev-wiki/articles/*"]
entry_criteria: "Phase 68 delivered (the ruler exists + control-validated); a read-only recon ran it across all 8 real consuming-project transcripts and falsified the handover's live-run plan (8/8 surfaced=false, AUQ-scoped hits=0, anchor degenerate in the OFF baseline)"
exit_criteria: "survey + frozen record reproduce 8/8 surfaced=false with positive-control; measurability-gate prints NOT-MEASURABLE + --selftest green; VALID-MEASUREMENT defines headroom/degeneracy + Phase-70 experiment; SCHEMA-NOTES line-50 resolved; apparatus disposition recorded; emitter git-diff-empty + no eval/comparison|corpus|reasoning code edits; no-LLM + no harness-verdict-token + disclaimer present; make eval 52/52; make test green at UNCHANGED script count"
---

# Phase 69: Amplifier Measurement — Representativeness Audit + Anchor-Validity Verdict

## Objective

Using the validated Phase-68 ruler against REAL consuming-project transcripts, deliver the honest answer the deferred live run cannot yet give — the instrument's ground-truth detector is non-representative on real data and the same-day-close anchor is degenerate for measuring harness lift — and ship a committed, re-runnable **measurability gate** that currently BLOCKS (NOT-MEASURABLE) and is the trigger any future live off/on experiment (Phase 70) must flip. See [[amplifier-representativeness-audit]].

## Scope

Files and modules affected:
- `eval/amplifier/survey-real-transcripts.sh` + `real-transcript-survey.md` — read-only survey runner + frozen empirical record (the 8 pinned transcripts, shasummed, OFF/ON-labelled).
- `eval/amplifier/measurability-gate.sh` + `VALID-MEASUREMENT.md` — the NOT-MEASURABLE/MEASURABLE/NO-DATA predicate (`--selftest`) + anchor-validity criteria + Phase-70 experiment design.
- `eval/amplifier/SCHEMA-NOTES.md` — resolve the line-50 "revisit in Phase 69" note.
- `.dev-wiki/articles/decisions/amplifier-representativeness-audit.md`, `.dev-wiki/articles/phase-63-remediation-roadmap.md` — decision + apparatus disposition.

**Out of scope (do NOT touch):** any live agent run (Phase 70); `eval/amplifier/emit-proxy-vector.sh` + its frozen schema/predicate (predicate repair is the deferred Approach-C work); new fixtures / a replacement detector; CODE under `eval/comparison|corpus|reasoning`; hooks, `modules.json`, `settings.json`, `install.sh`, the memory server.

## Tasks

4 tasks (see `tasks.md` for enriched fields):

- **T1 [M] (FIRST/checkpoint)** — survey runner + committed empirical record. Read-only, shasum-pinned 8-transcript set; per-transcript columns `escalation_count` / in-AUQ-boundary-match / raw-phrase / `parse_errors` / `surfaced` + sourced OFF/ON provenance; a positive-control row that RUNS the ruler on `surfaced.jsonl` (→true). CHECKPOINT: reproduces 8/8 `surfaced=false`; expected non-aborting state = 5/8 with `escalation_count≥1` AND zero in-boundary matches. STOP+re-derive if the detector fires on real data.
- **T2 [M]** — measurability gate + `VALID-MEASUREMENT.md`. Deterministic predicate (≥2 distinct ON ∧ ≥2 distinct OFF in-boundary events ∧ OFF-vs-ON differential, threshold read from the doc, planted-fixture shasums excluded) → NOT-MEASURABLE now; `--selftest` asserts a MEASURABLE + a NOT-MEASURABLE scenario; doc defines operational degeneracy (OFF-baseline headroom), the dual-failure-direction pre-mortem, and the minimal Phase-70 experiment.
- **T3 [S]** — resolve `SCHEMA-NOTES.md` line-50 (AUQ-only confirmed non-representative on real data; prose/ExitPlanMode scoping deferred to the gated predicate-repair) + honest apparatus disposition in the roadmap (comparison stays tombstoned, reasoning stays calibration-only, binary corpus remains sole gate — disposition advances only when the gate flips MEASURABLE). No apparatus CODE edits.
- **T4 [S] (LAST)** — regression gate + Phase-70 handoff + scope-honesty: `make eval` 52/52; `make test` green at UNCHANGED script count (probes NOT wired as make-test gates → no README bump); all Phase-68 deliverables git-diff-empty; no-LLM sweep; disclaimer present + no machine verdict token; decision article + roadmap name the Phase-70 deferred items.

## Exit Criteria

- [ ] `survey-real-transcripts.sh --selfcheck` exits 0 (read-only, shasum-pinned, positive control RUNS the ruler) and `real-transcript-survey.md` shows 8/8 `surfaced=false` with the `raw-phrase`/`parse_errors`/`escalation_count` columns
- [ ] `measurability-gate.sh` prints NOT-MEASURABLE on real data; `--selftest` exits 0 (asserts both a MEASURABLE and a NOT-MEASURABLE scenario)
- [ ] `VALID-MEASUREMENT.md` defines the operational degeneracy/headroom criterion, the dual-failure-direction pre-mortem, and the Phase-70 experiment
- [ ] `SCHEMA-NOTES.md` line-50 revisit resolved; roadmap records the `eval/comparison` + `eval/reasoning` disposition
- [ ] emitter + Phase-68 deliverables git-diff-empty; `git status --porcelain eval/comparison eval/corpus eval/reasoning` empty
- [ ] no-LLM sweep clean on the new executables; audit docs carry the disclaimer + no machine verdict token
- [ ] `make eval` 52/52; `make test` green at UNCHANGED script count (probes self-test, not make-test gates)
- [ ] decision article + roadmap name the Phase-70 deferred items (predicate repair, valid non-commodity anchor, the gated live run)

## Constraints

- **Audit-only — do NOT patch the emitter/predicate.** Prevents collapsing Approach-A (audit) into Approach-C (repair), which the user explicitly deferred and gated behind the measurability predicate.
- **No live agent run.** Prevents spending an expensive off/on experiment around a degenerate, detector-invisible anchor (the recon proved it premature).
- **Verdict vocabulary is about the ANCHOR/INSTRUMENT, never harness value.** Prevents the exact overclaim the deliberately verdict-free Phase-68 instrument was built to avoid. Guard: disclaimer-presence + no machine verdict token.
- **The measurability gate must be falsifiable in both directions.** Prevents a vacuously-RED-forever gate (blocks the program permanently) and a trivially-GREEN gate (greenlights a bad experiment). Guard: `--selftest` exercises both, pinned threshold ≥2-ON ∧ ≥2-OFF, planted-fixture shasum exclusion.
- **8/8-false must be attributable to data, not a broken detector.** Guard: the survey's positive-control row RUNS the ruler on `surfaced.jsonl` and shows `surfaced=true`.
- **Honest apparatus disposition — no premature "retired-for-good."** The ruler is not yet a validated gate (NOT-MEASURABLE); the binary corpus stays the sole trusted gate. Prevents overclaiming the instrument supersedes the legacy apparatus.
- **Read-only + deterministic + make eval frozen at 52.** Guards: input shasums unchanged, emitter git-diff-empty, no-LLM sweep, no apparatus CODE edits.

## Checkpoints

- **After T1 (FIRST/checkpoint):** confirm the recon reproduces (8/8 `surfaced=false`; 5/8 with `escalation_count≥1` and zero in-boundary matches is the expected, non-aborting state). If the detector instead fires on a real transcript, STOP and re-derive — the audit premise is wrong.
- **Before concluding genuine concept-absence:** spot-check the existing AUQ-event text for paraphrases (point-in-time / future-leak / look-ahead-bias). If a paraphrase IS present in an escalation, reframe to "detector phrase-list too narrow" and note it (still no emitter patch this phase).
- **If apparatus disposition surfaces genuine residual value in `eval/reasoning`:** record it (keep-as-calibration) rather than forcing retirement.

## Assumptions

- The real transcripts remain readable at `~/.claude/projects/-Users-jwang-ab-test*`. If false: the survey skips-and-reports; the committed `real-transcript-survey.md` remains the record of record.
- The Phase-68 emitter + control fixtures are unchanged. If false: STOP — re-validate the emitter first.
- `make eval == 52`. If false: STOP — an apparatus count drift means the disposition touched a consumer it shouldn't have.
- OFF/ON labels follow directory naming (`ab-test*` = baseline/eval, `condition-c*` = full harness). If ambiguous for any transcript: record `unknown` rather than guessing.

## Phase-70 Handoff

All gated on `measurability-gate.sh` flipping MEASURABLE: (1) predicate repair (broaden the surfaced boundary to where decisions actually surface without raw-text collapse); (2) a valid non-commodity anchor passing the OFF-baseline headroom screen; (3) the gated live off/on run (n>1) producing the first defensible harness verdict; (4) Frontier 1, downstream of a working measurement. See [[amplifier-representativeness-audit]].
