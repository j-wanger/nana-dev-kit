---
source_type: session
source_path: conversation
ingested: 2026-06-10T19:18:42
tier: private
---

# Raw: Transcript Edit-reversal forensics for unrecoverable pre-fix states

## Context
nana-dev-kit Phase 86 (ceremony-lift measurement) needed outcome-grade evidence that a Phase 85
review-gate catch was real. The fix had been applied inline before commit: the pre-fix state was
never committed, and the git diff between adjacent phase commits was empty — git alone could not
recover the counterfactual (defective) state.

## Insight
When inline fixes erase the pre-fix state from git history, the pre-fix FILE state is still
recoverable from the session transcript: reverse-apply the transcript's Edit tool calls
(swap new_string → old_string, applied in reverse chronological order) in an isolated worktree.
This reconstructs the defective state deterministically, letting you re-execute gates against it
and upgrade an otherwise-ambiguous evidence row to outcome-grade. Generalizes to any
agent-workflow forensics where inline fixes erase counterfactual states.

## Evidence
Phase 86 reconstructed a defective script this way: 4/4 Edit calls reverse-applied cleanly in a
worktree; the defect reproduced (false-DRIFT rows) while the deterministic test gate (`make test`)
stayed green on the defective state — proving the gate passes-where-it-should-fail.
See nana-dev-kit `eval/ceremony-lift/re-execution-log.md#r-ph85-review-gate`.
