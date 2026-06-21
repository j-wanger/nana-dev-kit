---
title: "Consumer Re-sync Rollout — consolidate-to-local + live --update across all 7 consumers"
aliases: [consumer-resync-rollout, migrate-to-local, phase-96-rollout]
category: decisions
tags: [install, consuming-projects, hooks, registration, deregistration, settings-topology, consolidation, rollout]
parents: [phase-96-consumer-resync-rollout]
created: 2026-06-21
updated: 2026-06-21
source: plan
confidence: high
---

## Context

Phase 93 built `install.sh --update` and proved it sandbox-only ([[install-resync-update-mode]]); the live
application was filed in Blockers (dry-run-first, per consumer, arm separately). A Phase-96 planning probe
of the 7 live consumers REVERSED the filing's premise: `--update` hardcodes `.claude/settings.local.json`,
but **4 of 7 consumers register their kit hooks in `.claude/settings.json` (project scope)** — edge-analyst,
ai-game, fate, aml-casework. On those, running `--update` as-built would `rm detect-loop.sh` while its
registration sits in `settings.json` (a **ghost registration** — the registered-but-broken class bitten 5×,
[[install-gap-dir-currency]] / [[HEU-012]]) AND spawn a parallel `settings.local.json` → cross-file
double-fire ([[drq-1-settings-merge-semantics-are-string-keyed]]). The Phase-93 fixtures modeled only
`settings.local.json` — an unmodeled drift class. `settings.local.json` is gitignored in all consumers;
`settings.json` is git-TRACKED in 3 of the 4 Group-B consumers; `cut_hooks = ["detect-loop"]`.

## Decision

**Consolidate-to-local** (maintainer A1 reject of in-place reconcile): the kit's single canonical hook
topology is gitignored `settings.local.json` for every consumer. Add a one-shot `install.sh
--migrate-to-local` that, for a `settings.json`-topology consumer, registers the current project-scope kit
set into `settings.local.json` and basename-deregisters the kit-managed + cut-hook (`detect-loop`)
registrations from `settings.json` — behind `--dry-run` + a timestamped backup of **BOTH** settings files
+ survivor functional smoke + revert-on-failure. The existing single-file `--update` stays UNCHANGED and
runs after migration. Reuses `register-settings.py hooks`/`deregister` (file-path-agnostic) — no new
primitives, only new orchestration (subtraction test).

Then apply LIVE across all 7, gated per consumer (maintainer A4 accept): ready-3 (signal-watch onboard,
edge-screener, aml-substrate) via `--update`; Group-B 4 via `--migrate-to-local` then `--update`. Each:
`check-install-drift --consumer` (read-only) → `--dry-run` → maintainer review → git-snapshot dirty trees
(ai-game's 73 files committed/stashed first) → apply → drift 0 + idempotent re-run + survivor smoke. Arm
signal-watch + aml-casework (maintainer A5 reject of fully-decoupled); ai-game + fate stay unarmed; the 3
already-armed untouched.

Alternatives considered and rejected:
- **In-place two-file-aware `--update`** (the planning recommendation) — maintainer REJECTED (A1): keeps
  `--update` reasoning about two files forever and leaves kit hooks in committed `settings.json`.
  Consolidate gives one canonical topology + simpler `--update` + gitignored/personal kit hooks; the cost
  (a visible git diff on 3 committed `settings.json`) is acceptable on solo repos with no kit-less collaborators.
- **Defer ai-game** (73 dirty files) — maintainer REJECTED (A4): include it, git-snapshot first.
- **Arm all unarmed / arm none** — maintainer chose a subset (A5): signal-watch + aml-casework only.
- **Hand-migrate Group B with per-consumer jq surgery** — rejected: reintroduces the manual surgery
  Phase-93 was built to end; no durable fix.

## Consequences

Ships the cross-file consolidation/dereg the kit has been burned by 5×, proven controls-first in mktemp
before any live use, and lands the banked Phase-93 value across all 7 consumers — closing the deferred
Blockers filing. Kit hooks leave the 3 committed `settings.json` (a visible, correct consumer git diff).
After the phase: every consumer on the `settings.local.json` topology, current kit set, `detect-loop` gone
with no ghost; armed set = edge-screener, edge-analyst, aml-substrate, signal-watch, aml-casework (ai-game,
fate unarmed). If a consumer holds a drift class not modeled by the fixtures, that consumer STOPs for
re-modeling (the dry-run-first gate catches it). Blast radius is real (7 live external repos) but each
write is dry-run-reviewed, two-file-backed-up, and reversible.
