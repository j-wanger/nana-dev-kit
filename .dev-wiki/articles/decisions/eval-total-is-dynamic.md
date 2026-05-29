---
title: "The corpus eval total is computed dynamically, not asserted as a literal"
aliases: ["eval-total-is-dynamic", "no-hard-coded-eval-baseline"]
category: decisions
tags: [eval, eval-runner, dynamic-count, no-magic-number, scenario-json, spec-reviewer-correction]
parents: [phase-64-cut-heuristic-scoring-machinery-self-dialogue]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The Phase-64 spec draft assumed a hard-coded eval baseline of `54` somewhere in the harness that would need editing down to `52` when the 2 coupled scenarios are deleted. The spec reviewer caught this: it does not exist. `scripts/eval-runner.sh` computes the total at runtime — it `find`s `scenario.json` files and increments `TOTAL` per scenario; there is NO `==54` assertion anywhere. (`tests/test_memory.sh` contains `0.54`, an unrelated overlap ratio — not a count.)

## Decision

Treat the corpus eval total as DYNAMIC. Deleting the 2 scenario directories (`skill-counter-update-companion`, `skill-evolution-lifecycle-companion`) yields `Score: 52/52 (100%)` automatically with ZERO count-literal edits. Do NOT hunt for a baseline constant to change, and do NOT introduce a new hard-coded count. The only `54` literals in the tree are historical prose in `eval/**/results.md` (and `active-phase.md`, phase articles) — leave them as historical record. The success criterion asserts `make eval` reports `52/52`, which the runner produces from the post-deletion scenario count on its own.

## Consequences

The scenario deletion is a pure directory delete — no fragile literal-hunting, no risk of a stale count surviving the cut. This corrects a draft assumption that, if followed, would have sent the implementer searching for a constant that isn't there (and risked introducing one). Generalizes a small but real discipline: verify whether a count is computed or asserted before planning edits against it — a dynamic count needs no maintenance, a literal does. The spec reviewer's catch is why this is a recorded decision rather than a silent assumption.
