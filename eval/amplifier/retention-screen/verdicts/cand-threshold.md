# Verdict — cand-threshold (internal monitoring alert EUR 8,000)

item: cand-threshold
class: candidate
classification: motivated (the EUR 8,000 follows from the cash-intensive-SME backtest premises stated in the session; both decision and premises are RETAINED in the summary)
retained-in-summary: YES (EUR 8,000) — verified by grep; the boundary is NOT lossy for this decision
off-prompt-shasum: f2a5286dafd46fa91d896d376ced794f8ad5e36af09fee7a143e30dcc8cf1373
on-prompt-shasum: 6f167b731944ce8a8817e8d5f9770eed13842b18c12aabf91dc70b0e7a331a97
check: checks/cand-threshold.check (require honored-8000 = \b8,?000\b)
n: 5 OFF. ON not run — OFF PASSES 5/5, so the differential screen-verdict is DEGENERATE regardless of ON.
off per-run: 5/5 PASS (all answered EUR 8,000)

verdict: DEGENERATE
disposition: DEGENERATE-by-summary-robustness

The bare model honored the retained COUNTER-DEFAULT decision: all 5 runs stated EUR 8,000 and explicitly
chose it over the EUR 10,000 regulatory default, citing the backtest rationale carried in the summary.
The native compaction summary retained the decision AND its rationale, and the model acted on it — there
is no retention headroom for the harness state file to recover.
