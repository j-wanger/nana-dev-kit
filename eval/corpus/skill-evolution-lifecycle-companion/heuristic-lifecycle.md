---
parent: dev-plan
referenced_at: "Step 6.5"
---

# Heuristic Lifecycle Transitions

After counter update (heuristic-counter-update.md), evaluate each updated heuristic for status transitions.

## Transition Rules

### active → under-review

Triggers when BOTH conditions met:
- `harmful / (helpful + harmful) > 0.3` (harm ratio exceeds 30%)
- `helpful + harmful >= 5` (minimum sample size)

Action: Edit the article's YAML frontmatter — change `status: active` to `status: under-review`.

### iron: NO transitions

Heuristics with `status: iron` accumulate counters for observability but NEVER transition. Iron status is immutable — no harm ratio triggers a status change. The dashboard flags iron rules with harm ratio > 0.3 for manual review.

### deprecated: terminal

`status: deprecated` is a terminal state. No automatic recovery. To reactivate: user manually edits the YAML frontmatter back to `status: active` and resets counters.

### under-review: manual resolution

`status: under-review` signals that the heuristic needs human review. Resolution is manual — the user reads the heuristic, evaluates whether its guidance is sound, and either resets to `active` (with counter reset) or transitions to `deprecated`.

## Skip Conditions

- Heuristic has `helpful + harmful < 5`: unscored, skip evaluation
- Status is `iron` or `deprecated`: skip (no transitions possible)
- Counter update was skipped (fail-open): skip lifecycle check for that heuristic
