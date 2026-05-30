---
title: "Phase 69 complete — Amplifier Representativeness Audit + Anchor-Validity Verdict (the cheap probe falsified the expensive plan)"
date: 2026-05-30
tags: [eval-validity, amplifier-vision, measurement, representativeness, anchor-validity, phase-69, journal]
phase: 69
status: complete
---

# Phase 69 complete — Amplifier Representativeness Audit + Anchor-Validity Verdict

## What happened

Phase 69 was framed by the strategic handover as "use the validated Phase-68 ruler, run the live off/on
harness experiment, declare the harness verdict." A **read-only reconnaissance at the start of planning
falsified that plan before any spend** — and that falsification *became* the phase.

Running the Phase-68 ruler (`eval/amplifier/emit-proxy-vector.sh`) across all 8 real consuming-project
transcripts (`~/.claude/projects/-Users-jwang-ab-test*`) produced three findings:

1. **The detector is non-representative on real data.** `ground_truth.surfaced=false` on all 8, and
   **AUQ-scoped phrase hits = 0** on all 8 — while the same-day-close / look-ahead phrase appears 8–50× in
   raw assistant text/code. The v1 AskUserQuestion-only escalation predicate is a *structural false-negative*
   on real provenance: the decision surfaces in reasoning / eval-frameworks / code, never inside an
   AskUserQuestion. A paraphrase spot-check of every AUQ event that DID occur (project scoping — phases, tech
   stack, forecast horizons, backtest targets) confirmed the strong form: the look-ahead decision is *never*
   escalated, even paraphrased — not an artifact of brittle matching.
2. **The anchor is degenerate for measuring lift.** The look-ahead concept appears substantively even in the
   harness-OFF baseline transcripts — the base model treats it as first-class unprompted, so there is no
   OFF→ON headroom for the harness to add. This recurs the Phase-59 commodity-knowledge lesson exactly.
3. **The existing transcripts are not a clean off/on experiment** (eval vs build vs full-harness build);
   the interaction-proxy deltas are confounded and direction-ambiguous.

At the direction gate (AskUserQuestion) the user chose **Approach A** — turn the recon into the deliverable;
NO live run; audit-only (do NOT patch the emitter). Four tasks delivered it:

- **T1** — `survey-real-transcripts.sh` (read-only, shasum-pinned 8-transcript set; `--selfcheck` RUNS the
  ruler on the planted `surfaced.jsonl` as a positive control proving the detector's positive branch fires,
  so 8/8-false is a DATA property not a dead branch) + the frozen record `real-transcript-survey.md` with
  separate `escalation_count` / in-boundary / raw-phrase / `parse_errors` columns + sourced OFF/ON provenance.
- **T2** — `measurability-gate.sh`: the runnable Phase-70 trigger (the Phase-66 probe idiom). Classifies
  MEASURABLE / NOT-MEASURABLE / NO-DATA; encodes representativeness (≥2 distinct ON ∧ ≥2 distinct OFF
  in-boundary events ∧ an OFF-vs-ON differential; planted-fixture shasums excluded; threshold read from the
  doc). Returns **NOT-MEASURABLE** now; `--selftest` proves both a MEASURABLE and a NOT-MEASURABLE scenario
  (falsifiable both ways). Plus `VALID-MEASUREMENT.md` — operational degeneracy/headroom criterion, the
  dual-failure pre-mortem, the minimal Phase-70 experiment, and the no-harness-value disclaimer.
- **T3** — resolved the `SCHEMA-NOTES.md` line-50 "revisit in Phase 69" note (AUQ-only confirmed
  non-representative; prose/ExitPlanMode scoping is the deferred, gated Approach-C repair) and recorded the
  **honest** apparatus disposition in the Phase-63 roadmap: the ruler is NOT yet a validated gate
  (NOT-MEASURABLE), so `eval/comparison` stays the tombstone, `eval/reasoning` stays calibration-only, and the
  binary corpus remains the SOLE gate — no overclaim that the ruler supersedes the apparatus.
- **T4** — regression gate: `make eval` 52/52, `make test` green at the unchanged 19-script count (probes
  self-test, NOT make-test gates → no README bump), all Phase-68 deliverables git-diff-empty, no-LLM clean,
  disclaimer present + no machine verdict token.

## Why it matters

This is the project's burden-of-proof discipline applied to its own measurement program: a ~10-minute
read-only probe falsified an expensive live-experiment plan and produced an honest "not measurable yet"
verdict instead of a confounded harness number. The deliberately verdict-free Phase-68 instrument stayed
verdict-free; the audit's verdict is about the ANCHOR and the INSTRUMENT, never harness value. The
measurability gate converts "is a valid measurement possible yet?" from a prose caveat into a runnable
predicate that currently blocks — the load-bearing trigger Phase 70 must flip.

## Health Delta

- `make eval`: 52/52 (unchanged). `make test`: green, 19 scripts (unchanged — the 2 probes self-test, not
  wired as make-test gates, so the README script-count drift-guard needed no bump).
- New repo-only files under `eval/amplifier/`: `survey-real-transcripts.sh`, `real-transcript-survey.md`,
  `measurability-gate.sh`, `VALID-MEASUREMENT.md` (+ SCHEMA-NOTES.md resolution). Emitter + Phase-68
  deliverables unchanged. No edits under `eval/comparison|corpus|reasoning`, no hooks/modules.json/settings.

## Review Gate

Unified reviewer **10/10 accept**. Adversarially verified the load-bearing gate logic empirically: real data
→ NOT-MEASURABLE (dual reasons); `--selftest` both branches; planted-shasum exclusion is content-addressed
(4 renamed copies of `surfaced.jsonl` → NO-DATA, not false-GREEN); differential check real (degenerate-in-both
→ NOT-MEASURABLE, one-arm-only → MEASURABLE); threshold defaults sanely (2/2) if the doc line is missing; no
permanently-RED path; bash-3.2 portable (empty-array-under-`set -u` footgun not triggered); positive control
executes the emitter (not a prose grep); emitter frozen (commit b8c255f). No CRITICAL/HIGH/MEDIUM correctness
issues. Two non-blocking polish suggestions applied: gate stderr now prints `unknown=N`; the record marks its
paraphrase section as a hand-authored appendix (so a future diff-drift check ignores it).

## Gate Compliance

`<!-- gate-log:phase-69 direction=approved delivery=pending -->` — direction gate approved (Approach A via
AskUserQuestion). Delivery gate pending acceptance.

## Soft Observations / Phase N+1 Candidates

- **Phase 70 (gated on `measurability-gate.sh` → MEASURABLE):** (1) predicate repair — broaden the `surfaced`
  boundary to where decisions actually surface (assistant reasoning / plan prose / ExitPlanMode) WITHOUT
  collapsing into raw-text matching (the `buried_phrase_outside_escalation` guard); (2) a valid non-commodity
  anchor passing the OFF-baseline headroom screen; (3) the gated live off/on run (n>1) → first defensible
  harness verdict; (4) Frontier 1, downstream of a working measurement.
- **Generalizable methodology lesson (working-knowledge candidate):** candidate anchors for any off/on
  measurement must pass an OFF-baseline headroom screen — a decision the base model already handles unprompted
  has zero headroom and is degenerate-for-lift regardless of detector quality. Anchor SELECTION is upstream of
  measurement. (Generalizes the Phase-59 "retrieval doesn't pay when parametric knowledge is strong" result to
  measurement-anchor selection.)
