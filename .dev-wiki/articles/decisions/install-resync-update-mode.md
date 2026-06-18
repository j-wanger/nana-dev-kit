---
title: "install.sh Idempotent Update / Re-sync Mode (build + sandbox-verify, automated dereg behind rails, build-only)"
aliases: [install-resync-update-mode, install-update-mode, consuming-project-resync]
category: decisions
tags: [install, consuming-projects, hooks, registration, deregistration, idempotency, build-only, subtraction]
parents: [phase-93-install-resync]
created: 2026-06-18
updated: 2026-06-18
source: plan
confidence: high
---

## Context

Consuming projects drift from the kit and there is no idempotent "bring this consumer up to current
kit" command. `install.sh --project-local` cp-overwrites hook files and upserts registrations, but it
(1) never REMOVES cut hooks — the Phase-88 `detect-loop` lingers, producing the observed 17/18/19-hook
spread across edge-screener / edge-analyst / ai-game / fate / aml-substrate; (2) cannot dedupe
Phase-79-style hand-patched duplicate registrations because `register-settings.py` is upsert-only
([[drq-1-settings-merge-semantics-are-string-keyed]] — distinct command strings invoking the same
script BOTH fire); and (3) `touch`es `.claude/enforce`, which would ARM the 4 consumers Phase 91
deliberately left un-armed. signal-watch has NO kit hooks at all. The kit has deliberately never shipped
a deregistration mechanism ([[prune-on-value-subtraction]]: `register-settings.py` merges, never
removes); every cut to date used manual sandbox-rehearsed jq surgery ([[hook-registration-hygiene]]),
and the registered-but-broken class has bitten 5× ([[install-gap-dir-currency]], [[HEU-012]]).

## Decision

Extend `install.sh` with an idempotent `--update` re-sync mode (REUSE its `cp` / `register` /
`ship_hook_dirs` — single source, NOT a separate `scripts/resync.sh`; subtraction test) that reconciles
a consumer's project-local hooks + `settings.local.json` registrations to the current kit: ADD/UPDATE
changed hooks, dedupe registrations by script basename (DRQ-1), and AUTOMATE the basename-normalized
deregistration of cut hooks (codifying the manual Phase-84/85 jq surgery) behind `--dry-run` +
timestamped backup + tested restore + survivor functional smoke + revert-on-failure. Hook-refresh is
DECOUPLED from arming — `.claude/enforce` is untouched unless an explicit `--arm` opt-in. The
never-installed case (signal-watch) routes through the existing `--project-local` path.

**BUILD + SANDBOX-VERIFY ONLY this phase**, with ZERO live consumer writes (ledger A1/A2): controls-first
mktemp consumer fixtures (3 drift classes — no-hooks / staged+detect-loop-ghost / Phase-79
duplicate-registration) + seeded controls (a synthetic cut-hook + a synthetic duplicate registration the
dereg/dedupe MUST catch; clean-on-seed = instrument-dead) ARE the test.

Alternatives considered and rejected:
- A separate `scripts/resync.sh` — rejected on the subtraction test; the re-sync IS install logic with
  reconciliation + dedupe + dereg added (ledger A3).
- Detect-and-warn-only / no auto-dereg — the maintainer chose automate-behind-rails (ledger A1); the
  manual jq surgery is exactly the destructive op the kit keeps re-deriving by hand.
- Build + a canary live write this phase — the maintainer chose build-only (ledger A2); the blast radius
  drops from 5 external repos to kit-code + tests, and Phase 94 is not blocked (consumer memory already
  FIRES globally via the Ph91 PYTHONPATH env, independent of the hook re-sync).

## Consequences

Ships the destructive deregistration the kit has been burned by 5×, but NEVER runs it live this phase —
the dereg path is exercised only in mktemp sandboxes behind backup + tested restore + survivor smoke +
revert-on-failure. signal-watch onboarding and the 4 staged-gate backfills stay un-fixed until a gated
live-application follow-on (filed in Blockers with a per-consumer checklist, dry-run-first, arm
separately). Re-sequenced from the Phase-92 [[strategic-inflection-review]] (product-for-consumers frame)
as the unbuilt original Phase-91 scope and the prerequisite-shaped first move of the consumer-serving
roadmap (93 re-sync → 94 memory re-measure → 95 memory-layer shrink). If a real consumer holds a drift
class not modeled by the fixtures (ledger A5), the dry-run-first follow-on catches it — this phase does
not touch it.
