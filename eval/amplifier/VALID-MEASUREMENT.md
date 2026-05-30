# What a VALID harness off/on measurement requires (Phase 69)

This is the gate any future live "harness-off vs harness-on" experiment (Phase 70) must pass before it is
worth running. The companion `measurability-gate.sh` encodes it as a runnable predicate; this doc states the
criteria, the threshold the gate reads, the pre-mortem, and the minimal experiment design.

> **No-harness-value claim.** This audit makes **no harness verdict** and asserts no harness value of any kind —
> it does not claim the harness helps, and it does not claim the harness fails. It characterises the INSTRUMENT
> (the Phase-68 ruler) and the ANCHOR (the same-day-close / look-ahead decision) only. Whether the harness
> improves outcomes is **not measurable on the current data** (this doc says why) and is deferred to Phase 70.

<!-- gate-threshold: MIN_ON=2 MIN_OFF=2 -->

## The current verdict: NOT-MEASURABLE

`measurability-gate.sh` over the 8 real transcripts returns **NOT-MEASURABLE**. Two independent, structural
reasons (either alone is sufficient):

1. **Detector-invisible anchor (zero in-boundary ground-truth events).** Across all 8 real transcripts the
   ruler's `ground_truth.surfaced` is `false` — the same-day-close / look-ahead decision never appears inside
   an AskUserQuestion event (the v1 escalation boundary), though it appears 8–50× in raw text. With zero
   in-boundary events, the detector has no positive signal to compare across conditions. (See
   `real-transcript-survey.md`.)
2. **Degenerate anchor (no OFF→ON headroom).** The look-ahead concept is handled substantively even in the
   harness-OFF baseline transcripts — the base model treats it as a first-class concern unprompted. An anchor
   the baseline already handles correctly leaves nothing for the harness condition to add, so even a perfect
   detector would measure no lift on it.

## Operational degeneracy criterion (reusable)

**An anchor is degenerate-for-lift iff the base model produces the correct behaviour unprompted in the
harness-OFF baseline** — i.e. zero headroom. Evidence here: the OFF / OFF-eval rows in
`real-transcript-survey.md` carry the look-ahead phrase in substantive context ("checking look-ahead bias
tests", "tracing data flow for look-ahead bias, entry timing"). This generalises the Phase-59
commodity-knowledge lesson: retrieval / harness lift does not pay where the model's parametric knowledge is
already strong.

**Anchor-headroom screen (the positive requirement).** A NON-degenerate anchor must be a decision the base
model **fails or omits unprompted in the OFF baseline** that the harness condition could plausibly fix — and
it must surface inside a boundary the detector can see. Any candidate anchor for a future off/on measurement
must pass this screen *before* the experiment is designed: anchor SELECTION is upstream of measurement.

## What the gate requires to flip MEASURABLE

The gate classifies the transcript set (planted control fixtures excluded by shasum, so a single planted
transcript can never satisfy it):

- **≥ MIN_ON distinct ON transcripts** and **≥ MIN_OFF distinct OFF transcripts** (threshold pinned above:
  `MIN_ON=2`, `MIN_OFF=2`) — so the comparison has n>1 per arm.
- **≥ 1 in-boundary ground-truth event** across the set (the detector can actually see the anchor — defeats
  reason 1 above).
- **An OFF-vs-ON differential** in the surfaced rate (the anchor surfaces at different rates between conditions
  — there is lift to detect; defeats reason 2). Uniform surfacing in both arms is still degenerate.

`MEASURABLE` ⇒ a Phase-70 off/on run on this anchor would carry signal. `NOT-MEASURABLE` ⇒ it would not, for
the stated reason. `NO-DATA` ⇒ no transcripts to judge.

## Pre-mortem — the gate must be falsifiable in BOTH directions

- **Falsely-GREEN failure** (greenlights a worthless experiment): the gate flips MEASURABLE on a single
  contrived/planted transcript, or on a within-arm artifact with no real between-condition differential.
  **Guard:** the planted-fixture shasum exclusion + the per-arm distinct-count threshold (≥2 ON ∧ ≥2 OFF) +
  the explicit OFF≠ON differential requirement. `--selftest`'s MEASURABLE scenario proves the gate *can* go
  green when these are genuinely met (not vacuously stuck RED).
- **Permanently-RED failure** (blocks the whole amplifier program forever): the gate encodes a condition no
  real data could ever satisfy. **Guard:** `--selftest` constructs a realistic MEASURABLE scenario from
  synthetic-but-structurally-valid transcripts and asserts the gate returns MEASURABLE — proving the green
  path is reachable. If that ever regresses, the gate has become unfalsifiable and must be fixed.

## Minimal Phase-70 experiment (gated on MEASURABLE)

Only once the gate flips MEASURABLE (which requires the two predicate-repair / anchor-selection steps below):

1. **Predicate repair.** Broaden the `surfaced` boundary to where real decisions actually surface (assistant
   reasoning, plan prose, ExitPlanMode) *without* collapsing into raw-text matching — raw-text matching fires
   on every condition including the bare baseline (`buried_phrase_outside_escalation` is the guard fixture)
   and discriminates nothing. Validate the repaired predicate against the real transcripts.
2. **Valid non-commodity anchor.** Select/construct a decision that fails the anchor-headroom screen's
   *degenerate* test — one the base model omits unprompted in the OFF baseline — and that surfaces inside the
   (repaired) detector boundary.
3. **The off/on run.** With a detector-visible, non-degenerate anchor and ≥2 distinct transcripts per arm,
   run the controlled harness-off vs harness-on experiment (n>1, identical task, same model/day), emit the
   ruler's proxy vectors, and produce the first defensible harness verdict. Frontier 1 (the escalation layer
   the ruler measures) is downstream of this working measurement.

Re-run the gate after steps 1–2 (`bash eval/amplifier/measurability-gate.sh`); a flip to MEASURABLE is the
only trigger that unblocks step 3. See [[amplifier-representativeness-audit]].
