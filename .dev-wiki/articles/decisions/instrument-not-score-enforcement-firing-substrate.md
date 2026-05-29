---
title: "Build the enforcement-firing substrate, not a scorer — scored fixture-replay duplicates the corpus"
aliases: ["instrument-not-score-enforcement-firing-substrate", "phase-65-direction", "fixture-replay-equals-corpus"]
category: decisions
tags: [eval-validity, instrumentation, measurement-before-optimization, corpus-duplication, subtraction-test, phase-65]
parents: [phase-63-remediation-roadmap, eval-validity-verdict]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phase 63's [[eval-validity-verdict]] (`instrument: mixed`) proposed a non-blind replacement for the blind LLM-judge evals: a "did-a-component-fire-and-change-an-action" eval keyed on observed component actions, off the `enforcement.log` substrate. Phase 65 set out to build a v1 of it (maintainer-approved, since the governing spec was propose-not-build).

The first proposed v1 — a **scored fixture-replay**: hand-script ordered tool-event sequences, replay them through the hook layer with a feature toggled ON vs OFF, assert a non-zero action-delta — was killed by an adversarial approach-review, **confirmed against the files**: the corpus `lifecycle` category (`eval-runner.sh`) already replays ordered hook-event sequences and already toggles the `.claude/enforce` marker across steps (`lifecycle-spec-enforcement-flow` is a literal block→allow transition). A coarse "action-delta ≥ 1" assertion is strictly *weaker* than the exact exit-code + stderr the corpus already pins per event. So scored fixture-replay = the corpus with an aggregation wrapper — ceremony, not a new measurement.

The honest alternative (instrument-and-accumulate, score off real `enforcement.log`) is the right end-state, but its substrate does not exist yet: the log is degenerate — 246/249 lines are `enforce-loop`, only 3 of 8 gated hooks write to it, the rest emit nothing.

## Decision

Phase 65 builds the **measurement substrate**, not a scorer. The distinguishing ingredient between "corpus" and a real-agentic eval is **trace provenance** — events emitted by real hook firings, not hand-authored fixtures. That provenance is exactly what's missing, so the available honest increment is: make every lifecycle-enforcement gate emit a structured, fail-open firing record (`{schema_version, ts, hook, action, reason, phase}`), then let real signal accrue. The **scorer** (with/without-feature delta) defers to Phase 66, gated on accrued signal. This is "measurement before optimization, don't optimize what you haven't measured" applied literally — and it avoids both the corpus-duplication trap (fixtures) and the score-on-no-data trap (degenerate log today). Coupled with the eval-apparatus disposition the verdict prescribes (retire the confounded A-vs-C arm; demote the LLM-judge to calibration-only).

Governed by the spec `specs/phase-65-enforcement-trace-instrumentation.md` (Tier-1 accept after the gitignore-mechanism, marker-gate, and demote-gate fixes).

## Consequences

The substrate is **safe-passive by construction** (the cost of getting instrumentation wrong is a broken safety hook): logging is exit-code-neutral under `set -euo pipefail` (`|| true` + decision-exit independent of logging), records controlled-vocabulary tokens never raw paths/commands (a logged bash body would be the exfiltration `scan-secrets.sh` exists to stop), atomic single-`>>` append (the existing read-modify-write `tail` truncation races), and gated OR on `.dev-wiki`/`.claude/enforce` so non-lifecycle projects neither pay the cost nor leak data. Retrofitting the 3 existing loggers onto the hardened pattern fixes their latent JSON-injection + truncation-race bugs. `enforcement.log` gets untracked (it was git-tracked → `cp -r` churn/leak into every project). After Phase 65, reasoning-quality remains unmeasured — acceptable, because the demoted judge measured nothing either; v1 does NOT pretend to fill that gap. The roadmap items "build the real-agentic eval" + "execute the disposition" partially convert: the disposition lands now; the eval's substrate lands now; its scorer becomes the Phase-66 decidable-when (signal-richness of the accrued log).
