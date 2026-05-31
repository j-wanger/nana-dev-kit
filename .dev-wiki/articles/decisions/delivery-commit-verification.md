---
title: Delivery-Commit Verification — deterministic detector over skill-text
status: accepted
confidence: high
date: 2026-05-31
phase: 75
source: plan
tags: [dev-debrief, delivery-gate, hooks, session-start, deterministic-validator, dogfood]
---

# Delivery-Commit Verification

## Decision

Fix the accepted-but-uncommitted divergence the edge-screener dogfood exposed with a **deterministic
detector as the PRIMARY fix**, backed by skill-text reinforcement as secondary — NOT with skill-text
alone.

The defect: `/dev-debrief` marked Phase 2 `[x] Delivery accepted` and wrote its journal, while the work
was never committed (`delivery-flow.md` D3, which says to commit, did not run). Phase 3 then built on the
uncommitted tree. The harness recorded "phase complete, delivery accepted" as durable state while `git`
had nothing — gate-state and git-state silently diverged.

Three parts, detector-first:
1. **(PRIMARY)** A fail-open divergence detector in `session-start.sh` (sibling to the crash-recovery
   block): if `active-phase.md` shows `[x] Delivery accepted` for "Phase N" but no `git log` commit
   references "Phase N", emit `[nana:recovery]`. Survives every compaction/session boundary.
2. **(SECONDARY)** `delivery-flow.md` D3 self-assert: capture the commit exit status; on a failed
   (e.g. pre-commit-hook-aborted) commit, surface loudly and do not push or mark the gate.
3. **(SECONDARY)** Gate-after-commit ordering: write the delivery gate accepted only after D3 verifies
   the commit (today the executor writes `active-phase.md` before D3 runs).

## Rationale

The instruction to commit ALREADY existed (D3) and was skipped — that IS the bug. Adding more skill-text
("verify the commit landed") is the same class of mechanism that just failed: it depends on agent
adherence. Per the kit's own scar tissue (Phase-55 session-start erosion; the functional-smoke
invariant; [[decision:memory-architecture-classification]] — "strengthen always-loaded activation
points, don't add things that can be unwired"), the robust fix is a DETERMINISTIC check that fires
regardless of whether the agent followed the skill. This reframes the objective from "guarantee the
commit fires" (unachievable — committing is an agent action) to "make gate-state diverging from
git-state impossible to ignore" — a deterministic validator at the boundary, per the technical posture.

The detector is also robust to an unknown: whether Phase 2's commit was skipped by the agent or aborted
by a pre-commit hook (no transcript to confirm). It checks the END state, so it catches both; the D3
self-assert specifically covers the hook-abort branch.

## Alternatives considered

- **Skill-text only (add commit-verification to D3).** REJECTED as the primary fix — it repeats the
  exact mechanism that failed (an instruction the agent can skip). Kept as secondary reinforcement.
- **Same-session Stop-time catch (`session-stop.sh`).** DEFERRED — session-start is the load-bearing,
  compaction-surviving point and would have caught edge-screener next session; a Stop nudge the
  just-failed agent generates for itself is marginal. Add if it recurs.
- **Block the session / hard-fail on divergence.** REJECTED — every recovery check in the kit is
  fail-open/advisory; blocking risks self-lockout (the enforce-spec regression class).

## Consequences

- Fixes FUTURE divergence in any consuming project that pulls the kit update; edge-screener's current
  state is a separate manual fix (and a reminder that installed copies drift — a standing soft
  observation).
- No firing-coverage denominator churn (session-start already counted); the new branch needs a
  functional assertion per the smoke invariant.

## Links

- Spec: `specs/phase-75-delivery-commit-verification.md`
- Surfaced by the edge-screener dogfood — see [[cross-session-substrate-stock-screener]] (Phase 73),
  [[harden-consuming-project-scaffold]] (Phase 74, the prior dogfood→harden fix).
- Posture: [[decision:memory-architecture-classification]], [[decision:functional-smoke-invariant-rule]].
