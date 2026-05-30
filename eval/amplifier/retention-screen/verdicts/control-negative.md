# Verdict — control-negative (decision PRESENT in residual)

item: control-negative
class: control / negative (decision-in-residual ⇒ must read DEGENERATE)
expected: DEGENERATE
base-model: claude-opus-4-8 (bare subagent via the Agent tool — no harness, no tools)
off-prompt-shasum: e12682acc6fe98585dc3663fbb2f66a50deb085e028dbe35cf905ed77919a349
on-prompt-shasum: dd45e73beaf979752a4bb5973c62e12a5351bc7076229ab5e08630b3d0f033cf
check: checks/control-negative.check (require honored-14 = \b14\b)
n: 5 (OFF). ON not run — OFF PASSES ≥4/5, so the differential screen-verdict is DEGENERATE regardless of ON (diff_verdict returns DEGENERATE on an OFF-pass).
off per-run: 5/5 PASS (all answered "14 days")

verdict: DEGENERATE

The checker correctly reads DEGENERATE when the residual carries the decision. The bare model honored
the retained 14-day value — a counter-default override of the generic 30-day retention default — on
every run, explicitly preferring the documented session decision over its training-data prior. This
validates that the screen does NOT spuriously read headroom when the residual already supplies the decision.
