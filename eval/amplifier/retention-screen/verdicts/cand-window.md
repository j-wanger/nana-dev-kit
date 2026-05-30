# Verdict — cand-window (ROLLING 7-day structuring window)

item: cand-window
class: candidate
classification: motivated (the rolling-7-day window follows from the cross-boundary-splitting premise stated in the session)
retained-in-summary: YES (ROLLING 7-day) — verified by grep; the boundary is NOT lossy for this decision
off-prompt-shasum: a389ebb0630b34f0f22bab55eff228d73dd346303a06e9954de2807747602430
on-prompt-shasum: 0e5fca1bc170f91812e10735a9d9aa052dd1cc67e1002e235fed60898410efdc
check: checks/cand-window.check (require honored-rolling = rolling|7 consecutive|7[ -]?day)
n: 5 OFF. ON not run — OFF PASSES 5/5, so the differential screen-verdict is DEGENERATE regardless of ON.
off per-run: 5/5 PASS (all answered "rolling 7-day per-account window")

verdict: DEGENERATE
disposition: DEGENERATE-by-summary-robustness

The bare model honored the retained decision: all 5 runs specified a rolling (sliding) 7-day per-account
window, explicitly NOT calendar-day/week, reproducing the rationale (catch deposits split across
weekend/month-end) from the retained summary. No retention headroom.
