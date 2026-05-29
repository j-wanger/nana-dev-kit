---
title: "Run the assessment over a frozen harness state; batch all cuts at the end as migrations"
aliases: ["cuts-are-frozen-batched-migrations", "frozen-state-pass", "template-cut-is-a-migration"]
category: decisions
tags: [harness, assessment, migration, quarantine, registration-invariant, referential-integrity, blast-radius]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The harness is both the artifact under test and the tool doing the test (assessor=assessed). A finding generated mid-pass must not be measured against a world that has already had the thing being removed taken out of it — interleaving cuts with assessment mutates the harness underneath later findings. Separately, every `templates/` deletion ships to every scaffolded project via the installer's `cp -r`: the cascade-failure anti-pattern (nana-init not installed → enforce marker missing → all enforcement silently off) has bitten three times, so a template cut has real downstream blast radius and is a migration, not an edit.

## Decision

Run the four assessment angles over a frozen harness state and batch all cuts to the end of the pass. Treat every template deletion as a migration: quarantine (disable in `modules.json` / move out of the install path) before hard-delete for anything non-trivial; hard-delete only frozen dead records (e.g. stale eval result files). After the batched cuts, four checks must all pass or the offending cut is reverted and kicked to the roadmap: `tests/test_registration.sh` (bidirectional registration invariant), a referential-integrity check (every `source:`/`[[...]]` link in `working-knowledge.md` + `active-knowledge.md` resolves to an existing target), `make test` (≥13 scripts green), and `make eval` (54/54 Phase-61 baseline). Alternative rejected: incremental cut-as-you-go — cheaper to execute but corrupts the frozen-state premise and risks a half-migrated install path.

## Consequences

Cuts are gated behind a mid-phase checkpoint that reports the proposed cut list before anything is removed. Quarantine-first means a wrong cut is reversible within git history; if a component cannot be cleanly quarantined (a load-bearing transitive dependency surfaces), it is kept, the dependency is recorded in the coherence map, and the item is deferred to the roadmap. The registration + referential-integrity invariants are the hard tripwires that distinguish a slam-dunk from a roadmap item.
