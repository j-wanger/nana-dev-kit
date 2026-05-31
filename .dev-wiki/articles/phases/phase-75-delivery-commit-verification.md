---
title: "Phase 75: Delivery-Commit Verification"
aliases: ["delivery-commit-verification", "phase-75-delivery-commit-verification"]
category: phases
tags: [engineering, dev-debrief, delivery-gate, hooks, session-start, deterministic-validator, dogfood, consuming-project]
parents: []
created: 2026-05-31
updated: 2026-05-31
source: plan
status: completed
scope: ["templates/.claude/hooks/session-start.sh", "tests/test_harden.sh", "templates/.claude/skills/dev-debrief/delivery-flow.md", "templates/.claude/skills/dev-debrief/executor-prompt.md", "templates/.claude/skills/dev-debrief/SKILL.md"]
entry_criteria: "Phase 74 closed; the edge-screener dogfood exposed /dev-debrief marking Phase 2 delivery-accepted + journaling it while the work was never committed (Phase 3 built on the uncommitted tree)."
exit_criteria: "session-start.sh fires a fail-open divergence detector when active-phase.md shows delivery-accepted for Phase N but no commit references Phase N; delivery-flow D3 verifies the commit landed; the delivery gate is written only after a verified commit. make test + make eval 52/52 green."
---

# Phase 75: Delivery-Commit Verification

## Objective

Close the accepted-but-uncommitted divergence the edge-screener dogfood exposed — the 2nd
dogfood→harden fix after Phase 74. The defect: `/dev-debrief` marked Phase 2 `[x] Delivery
accepted` and wrote its journal while the work was never committed, and Phase 3 then built on
the uncommitted tree (gate-state and git-state silently diverged). Fix detector-first, so the
divergence is caught regardless of whether the agent followed the skill text.

## Scope

- `templates/.claude/hooks/session-start.sh` (new fail-open divergence detector, sibling to crash-recovery)
- `tests/test_harden.sh` (4 RED-first detector firing tests)
- `templates/.claude/skills/dev-debrief/delivery-flow.md` (D3 commit self-assert + gate-after-commit ordering)
- `templates/.claude/skills/dev-debrief/executor-prompt.md` #11 + `SKILL.md` Step 18 (write delivery gate UNCHECKED)

## Exit Criteria

- [x] T1: session-start.sh divergence detector (PRIMARY) — fires `[nana:recovery]` when active-phase.md shows `- [x] Delivery accepted` for Phase N but `git log` has 0 commits matching `phase[ _-]?N\b`; 4 firing tests green.
- [x] T2: delivery-flow D3 verifies the commit landed (surfaces hook-aborted commits, no push/gate-mark on failure) + gate-after-commit ordering (executor writes the gate unchecked; D3 flips it post-verified-commit).
- [x] T3: 3 deferrals recorded in Blockers; make test green, make eval 52/52, eval/ git-diff-clean.

## Constraints

- Constraint: detector is fail-open (every read guarded, exit 0 on any error) — every recovery check in the kit is advisory; blocking risks the enforce-spec self-lockout class.
- Constraint: the new detector branch needs a `# fires:`-anchored functional assertion per the functional-smoke invariant — session-start already counts in firing-coverage (no denominator churn).
- Constraint: the PRIMARY fix is deterministic (a validator at the boundary), not more skill-text — the skipped commit step was itself skill-text, so more skill-text repeats the failure.

## Notes

Reframed at the direction gate from "guarantee the commit fires" (unachievable — committing is an
agent action) to "make gate-state diverging from git-state impossible to ignore." The detector
checks the END state, so it catches both an agent-skipped commit and a pre-commit-hook-aborted
commit; the D3 self-assert specifically covers the hook-abort branch. Decision
[[delivery-commit-verification]]. Surfaced by the edge-screener dogfood — see
[[cross-session-substrate-stock-screener]] (Phase 73), [[harden-consuming-project-scaffold]]
(Phase 74, the prior dogfood→harden fix).
