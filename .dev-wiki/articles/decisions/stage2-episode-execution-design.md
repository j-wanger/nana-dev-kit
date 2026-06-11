---
title: "Stage-2 episode contrast execution design (Phase 87)"
aliases: [stage2-episode-execution-design, phase-87-execution-design]
category: decisions
tags: [ceremony, measurement, episode-contrast, eval-methodology, edge-screener, pre-registration]
parents: [phase-87-stage2-episode-contrast, ceremony-step-verdicts]
created: 2026-06-10
updated: 2026-06-10
source: plan
confidence: high
---

# Stage-2 episode contrast execution design (Phase 87)

## Context

Phase 86 routed STAGE-2 go as Phase 87: the frozen `## Stage-2 parameters`
(eval/ceremony-lift/pre-registration.md, byte-frozen since 9ad62f0) define the arms,
substrate, canary, positive control, ship triple, and claim ceiling; this phase executes
them. Spec: specs/phase-87-stage2-episode-contrast.md (nana:approved 2026-06-10). State
loading surfaced three execution facts the freeze left open: edge-screener's working tree is
dirty (the Phase-85 migrated kit install is uncommitted/gitignored — a worktree cut from
368e056 gets a stale pre-migration harness), no "edge-screener exit-criteria runner" exists,
and git worktrees share one .git (cross-arm refs/stash leak).

## Decision

Maintainer rulings (direction Q&A 2026-06-10):

- **Isolation = independent clones** from the same pinned setup state, recorded in the
  execution-protocol addendum as the faithful implementation of the frozen "twin worktrees"
  wording (same start state, twin working trees; isolation structural, no probe machinery).
- **Ship-runner referent = edge-screener's standing phase-exit gate** (full pytest suite +
  coverage gate + mypy strict + ruff), pinned as one byte-exact command in the addendum,
  orchestrator-executed identically in both arms.
- **Gate inputs = canned, orchestrator-mediated**: addendum pre-registers minimal canned
  responses, logged verbatim per arm; zero-gate-firing in arm B pre-declared a valid run.

Execution shape (freeze-then-execute, cheapest-validation-first):

1. **Addendum first**: eval/ceremony-lift/stage2/execution-protocol.md pins everything
   execution-level — the three rulings above, arm ordering, model + session budget cap with
   ENFORCEMENT mechanics (cap unit = cache-adjusted tokens anchored to the stage-1 cost
   table's per-phase totals; deterministic check command + cadence; deterministic stop rule —
   so DID-NOT-FINISH is never a judgment call), gate-response POLICY (closed policy, not
   literals: select the approve/proceed/default option; one pinned generic string for
   free-text; any input outside policy = logged protocol deviation flagged at checkpoint; an
   arm stalled on a gate the policy cannot answer maps to DID-NOT-FINISH), positive-control
   delivery path + deterministic surfacing detector, canary post-stop placement,
   context-surface parity-shared-vs-voiding classification list (its own named artifact),
   blinded defect-review protocol, claim-ceiling grep patterns, target branch IDs read off
   the baseline coverage report, provisioning manifest (exhaustive BOTH directions: includes
   the gitignored/untracked enforcement surfaces — settings.local.json registrations,
   .claude/enforce marker; excludes named extras — backup tgz, reports/edge-verdict-focus.md),
   per-arm transcript-dir mapping. Committed BEFORE any arm runs (first-add-commit ancestry +
   byte check, stage-1 pattern).
2. **Setup commit (HARD checkpoint — first out-of-repo write)**: a setup branch in
   edge-screener from 368e056 committing parity state both arms need: the Phase-85 kit
   install as committable files INCLUDING the gitignored/untracked surfaces per the manifest
   (force-add or migrate registrations into tracked settings.json; recreate .claude/enforce),
   the Phase-10 candidate analysis, and the positive-control dev-wiki seed (.dev-wiki is
   tracked, so the seed must be IN the git state clones cut from). The checkpoint explicitly
   presents the setup-SHA deviation (spec says "from pinned SHA 368e056"; arms cut from the
   child setup SHA under the frozen "same git state" wording) for maintainer ack — ruled, not
   assumed. The setup file set is grepped for DRQ-1/kit-internal content BEFORE clones are
   cut (cheap canary pre-check). Both clones cut from the setup SHA; restoration tested —
   covering restoration of edge-screener's live DIRTY working state, not just the SHA (the
   live install must not be broken by branch switching); SHAs recorded.
3. **Instrument validation before arm tokens**: clone isolation confirmed structurally,
   HEU-012 hook-fire probe in a scratch clone (pipe a real event through one enforcement
   hook, assert exit 2 — arm B's defining treatment must be ARMED, not registered-but-broken),
   canary/control mechanics rehearsed in scratch, claim-ceiling check validated against its
   seeded-negative, extractor smoked on an existing edge-screener transcript.
4. **Arms in fresh sessions**, order pinned, canned inputs logged; orchestrator opens
   neither diff until both reach ship/stop; canary posed to arm B post-stop.
5. **Orchestrator-executed tables**: frozen ship triple + validity assertions (test-ID
   subset = ship-blocking, branch-ID coverage = reported column) + per-arm cost via the
   stage-1 extractor; blinded tie-break only if both arms pass.
6. **HARD checkpoint**: maintainer takes the spec-generation disposition (closed vocabulary
   incl. not-confirmed); ship-the-better via its own checkpoint; close-out runs the
   claim-ceiling, substrate-intact, and exit-criteria checks.

## Consequences

- The disposition carries an explicit bundle-attribution caveat: the contrast is
  full-ceremony-vs-minimal, not spec-vs-no-spec; n=1 confirms cut-candidate→reversible
  trim-trial only.
- Canned gates mean the ceremony arm is machinery-only; defensible for the primary customer
  (spec runs --internal, no user gate) and barred from minting verdicts on gate-dependent
  steps anyway.
- Kit-commit embargo (component-path diff vs 6728e2f) holds until both arms close; the trim
  round stays sequenced after.
- Setup commit slightly moves the arm base off 368e056 (to a child setup SHA) — recorded
  openly in the addendum; the frozen wording fixes "the same git state", not the SHA.
