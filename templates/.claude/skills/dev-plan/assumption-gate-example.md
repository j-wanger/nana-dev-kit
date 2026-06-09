---
parent: dev-plan
referenced_at: "companion"
---

# Assumption Gate — Worked Example

Two illustrative gate runs, frozen as a reference for the interaction shape (`assumption-gate.md`). These
are hypothetical plans, not live ones.

## Case A — mixed positions (a reject sends the agent back)

Surfaced (cost-sorted) for a hypothetical "add a session-start advisory hook" plan:

1. `[HIGH]` The hook is actually registered AND fires under a non-root CWD — if false, the advisory is
   silent and the feature ships broken (this is the silent-class infrastructure assumption).
2. `[HIGH]` The maintainer wants an advisory, not a blocking gate — if false, we built the wrong control.
3. `[MED]` working-knowledge stays under the context-warning threshold after the addition — if false, we
   trip the warning the change was meant to relieve.

Positions: **A1 accept / A2 reject** ("I want it to block, not advise") **/ A3 don't-know.**

- **A2 reject** → revise: change the design from advisory to a blocking check; update the draft decision;
  re-surface the assumptions for the revised plan.
- **A3 don't-know** → the agent defends with the measured wk size (under threshold) → the maintainer flips
  to accept; OR, if unresolved, it is routed to `## Blockers and Open Questions` with `revisit-status: open`.
- After the revision round, no unresolved reject/don't-know remain → **direction confirmed.**

Ledger row appended: `all_accept: false`; A1 accept / A2 reject / A3 accept; each `revisit-status:` blank
(dev-debrief fills them at close).

## Case B — all-accept (warn + track + restate)

Surfaced for a hypothetical "bump a pinned dependency version" plan: **A1 accept / A2 accept** (all accept).

1. **Warn** — "This is an all-accept; confirm you engaged each assumption rather than clearing the gate."
2. **Track** — the ledger row records `all_accept: true`.
3. **Restate** — "Accepting A1 commits the plan to not re-pinning if CI breaks; accepting A2 commits it to
   the upstream changelog being accurate." Then → **direction confirmed.**

Ledger row appended: `all_accept: true`; A1 accept / A2 accept; each `revisit-status:` blank.
