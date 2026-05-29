---
title: "Harden hot-cache curation deterministically (not a distillation judge-eval)"
aliases: ["harden-hot-cache-curation-deterministic", "phase-62-deterministic-curation"]
category: decisions
tags: [memory, hot-cache, working-knowledge, curation, deterministic, eval, subtraction-test]
parents: [phase-62-harden-hot-cache-curation]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phase 61 proved the always-loaded markdown hot cache (`.claude/rules/working-knowledge.md`) is the harness's effective retrieval layer — it made every planning baseline strong, which is *why* all five runtime-retrieval alternatives measured net-zero-or-negative ([[hot-cache-is-the-effective-retrieval-layer]]). That makes hot-cache curation quality the one memory/knowledge direction with affirmative evidence ([[two-tier-curate-into-hot-cache]]). But the file is mandatory and ships to every scaffolded project via the installer's `cp -r`, and its integrity (100-entry / 210-line cap, no duplicate propositions, well-formedness) is enforced only by LLM prose an AI executes by hand — the documented session-start.sh cap-erosion anti-pattern (Phase 55: a 70-line cap eroded to 137 over 30 phases, untested). The tempting scope is a "curation suite" that also improves distillation quality.

## Decision

Phase 62 hardens the hot cache via a **deterministic curator + invariant test**; distillation-quality improvement is OUT of scope. Three alternatives were weighed:

1. **Deterministic hardening only (CHOSEN)** — cap-enforce, exact-proposition dedup, well-formedness bail, atomic write, all in the existing `wk-prune.sh`; the regression test IS the validation. Sidesteps the Phase-59 unmeasurability trap.
2. **Full curation suite (REJECTED)** — includes a distillation-quality LLM-judge eval. Unmeasurable by the binary runner, and Phase 61 showed the cache already at quality-ceiling (no headroom). Fails the subtraction test exactly like Phase 59's CUT active-research ([[cut-active-research-step-2-7]]): an improvement that cannot be measured net-positive should not ship.
3. **Declare the thread done (REJECTED)** — there are concrete latent defects: an untested cap on a mandatory always-loaded file, and a wrong dedup key ([[dedup-key-proposition-not-slug]]). Doing nothing ships a known cap-erosion footgun to every project.

## Consequences

The curator is bounded, testable, and net-positive by construction (deterministic validators at boundaries over neural judges). Distillation-quality remains an open lever — but only worth revisiting if a future measurement artifact exists and the cache leaves quality-ceiling. The "regenerate hot cache from wiki articles" derived-view redesign stays a deferred future option, not Phase-62 scope.
