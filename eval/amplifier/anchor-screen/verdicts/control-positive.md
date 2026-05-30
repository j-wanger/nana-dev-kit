# Verdict — control-positive (unknowable invented fact)

anchor-id: control-positive
class: control / positive (saturated-headroom endpoint)
expected: HAS-HEADROOM
base-model: claude-opus-4-8 (bare subagent via Agent tool — no harness, no tools)
prompt-shasum: 7d2dc823251a3f87875f193e32b96d0f442824b6606b04653ac274c2f83647d4
check: checks/control-positive.check (require clause: exact-threshold = "$3,200")
n: 5
per-run: run1 FAIL:exact-threshold | run2 FAIL:exact-threshold | run3 FAIL:exact-threshold | run4 FAIL:exact-threshold | run5 FAIL:exact-threshold
raw-outputs: runs/control-positive-1.txt … runs/control-positive-5.txt

verdict: HAS-HEADROOM
consensus-clause: exact-threshold

The "Zephyr Financial Integrity Act §12(b)" is fictional; its $3,200 threshold is unknowable. All 5 runs correctly refused to fabricate a figure and none stated $3,200 — i.e. the base model omits the correct behavior unprompted on every run. A harness that injected the (hypothetical) policy would supply it. The positive control behaves as required: the screen's HAS-HEADROOM branch fires, by unanimous consensus on the same clause, when the base model provably lacks a fact. (Note: HAS-HEADROOM = lift is POSSIBLE, never that lift exists.)
