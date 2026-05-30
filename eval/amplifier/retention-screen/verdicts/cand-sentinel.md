# Verdict — cand-sentinel (legacy hit_flag = 9; the engineered-favorable / ARBITRARY backstop)

item: cand-sentinel
class: candidate (engineered-favorable backstop)
classification: arbitrary (sentinel 9 is a non-derivable legacy convention — the rationale-probe would fail)
retained-in-summary: YES (hit_flag = 9 / sentinel 9) — verified by grep; the boundary is NOT lossy for this decision
off-prompt-shasum: 1ed1e39ef4f6a6764156119bb15b7cbe2c563ae5584a2ed81f38952e806c9595
on-prompt-shasum: 54cacb9f512fb3bc981f5cf2eab40a968df873d219dc1b5fa0aa0713fa49ee7b
check: checks/cand-sentinel.check (require honored-9 = \b9\b ; forbid not-boolean = \btrue\b|\bboolean\b)
n: 5 OFF.
off per-run, AS-PINNED: 5/5 FAIL:not-boolean  →  aggregate AS-PINNED: HAS-HEADROOM (consensus-clause not-boolean)
off per-run, REQUIRE-ONLY (honored-9): 5/5 PASS  →  aggregate: DEGENERATE

verdict: DEGENERATE
disposition: DEGENERATE-by-summary-robustness
pinned-check-status: INVALID-CLAUSE (forbid not-boolean is a brittle false-positive; withdrawn)

DISCOVERED CHECK BRITTLENESS (recorded, not retrofitted). All 5 OFF runs HONORED the decision — every run
wrote "the integer 9" for hit_flag. The require clause (honored-9) PASSES 5/5. But the pre-registered
forbid clause not-boolean (\btrue\b|\bboolean\b) FIRES on the model's CORRECT explanation ("9, not 1 or
boolean true"), not on a wrong answer — so the as-pinned check reads a FALSE HAS-HEADROOM. This is the
Phase-70-anticipated brittle-check risk realized: a substring forbid cannot distinguish "answer = 9,
explained as not-true" from "answer = true". The clause is withdrawn as INVALID; the committed check file
is left UNCHANGED (editing it after the runs would be retrofitting).

Decisive disambiguation via the POSITIVE CONTROL: a REAL OFF-failure looks like the positive control,
where the bare model genuinely refuses ("I don't know; I won't fabricate it") and states NO value. Here
the model STATED the value (9) on every run — categorically the opposite of headroom. The substantive
verdict is DEGENERATE: the native summary retained the sentinel-9 decision and the model acted on it.
Even the engineered-favorable ARBITRARY backstop is summary-robust.
