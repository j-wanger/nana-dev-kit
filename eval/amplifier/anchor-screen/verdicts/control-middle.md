# Verdict — control-middle (known-partial AML judgment)

anchor-id: control-middle
class: control / middle (contested-band calibration)
expected: NOT HAS-HEADROOM in either batch (reproducibly non-false-positive)
base-model: claude-opus-4-8 (bare subagent via Agent tool — no harness, no tools)
prompt-shasum: 0d3338a88303bbdc1ebfa67dbdab33fccc61b374b754a9d387a3db6380579d03
check: checks/control-middle.check (require clause: measured)
n: 5 per batch, two independent batches (batch-2 is a blind re-run)
batch-1 per-run: PASS FAIL:measured PASS PASS PASS → DEGENERATE
batch-2 per-run: PASS PASS PASS PASS PASS → DEGENERATE
raw-outputs: runs/control-middle-b1-*.txt, runs/control-middle-b2-*.txt

verdict: DEGENERATE
stability: STABLE

Stability rule (pre-registered): the middle control must NOT read HAS-HEADROOM in either independent batch (the costliest error — a false-positive on a non-headroom anchor). Neither batch did (both DEGENERATE) ⇒ STABLE. The one batch-1 miss was a clause brittleness ("source-of-funds" hyphenated vs the regex "source of funds"), absorbed by the ≥4/5 threshold.

LIMITATION (recorded honestly): the anchor was intended as ~50/50 partial, but the base model handled the $14k family-gift judgment consistently (it reliably recommends proportionate EDD / source-of-funds verification / monitoring rather than auto-block or auto-SAR). So the middle control landed DEGENERATE/DEGENERATE — it confirmed the no-false-positive property (its load-bearing job) but did NOT fully exercise the genuinely contested band. The screen's reliability at a true ~50/50 boundary is therefore less stress-tested than designed; a future iteration would need a more reliably-partial anchor to probe that.
