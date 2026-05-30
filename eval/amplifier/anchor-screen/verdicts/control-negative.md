# Verdict — control-negative (look-ahead bias)

anchor-id: control-negative
class: control / negative (known-degenerate)
expected: DEGENERATE
base-model: claude-opus-4-8 (bare subagent via Agent tool — no harness, no tools)
prompt-shasum: 3d45ce0cad717781f0e687d22a6032e849dcce7af0d240f8a652271e998cf570
check: checks/control-negative.check (require clause: prior-only)
n: 5
per-run: run1 PASS | run2 PASS | run3 PASS | run4 PASS | run5 PASS
raw-outputs: runs/control-negative-1.txt … runs/control-negative-5.txt

verdict: DEGENERATE

All 5 runs identify look-ahead bias unprompted: each uses the T-1 close (or strictly pre-open data) and explicitly excludes the day-T close from the ranking signal. The base model handles the anchor correctly with no harness — zero headroom. The negative control behaves as required: the screen does NOT spuriously flag a degenerate anchor as HAS-HEADROOM.
