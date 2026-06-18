---
title: "Deregistration + dedupe as register-settings.py subcommands (first dereg mechanism, two-tier cut handling, basename-normalized)"
aliases: [deregistration-as-register-settings-subcommands, register-settings-deregister, dedupe-by-basename, two-tier-cut-hook-handling]
category: decisions
tags: [install, deregistration, register-settings, dedupe, hooks, cut-hooks, basename, subtraction]
parents: [phase-93-install-resync]
created: 2026-06-18
updated: 2026-06-18
source: debrief
confidence: high
---

## Context

Phase 93 had to ship the first deregistration mechanism the kit has ever had. `register-settings.py`
was upsert-only ([[prune-on-value-subtraction]]: it merges, never removes), so every prior cut used
hand-rolled, sandbox-rehearsed jq surgery ([[hook-registration-hygiene]], [[install-gap-dir-currency]]).
The DRQ-1 finding ([[drq-1-settings-merge-semantics-are-string-keyed]]) made the removal target precise:
Claude Code dedupes hook registrations by exact command STRING, so two distinct command strings invoking
the same script BOTH fire — removal and dedupe must therefore normalize by script BASENAME, not by string.
The planning decision ([[install-resync-update-mode]]) committed to building the `--update` mode behind
rails; this article records the implementation-level placement and the cut-hook handling design that were
decided during the build.

## Decision

Implement dedupe and deregistration as **subcommands of the existing `register-settings.py`** (a new
`--dedupe` flag on the `hooks` action that collapses entries by `_entry_basename`, and a new `deregister`
subcommand), reused by `install.sh --update` — NOT a separate `scripts/resync.sh` or a standalone
dereg script (subtraction test; the registration single-source stays one file).

Cut-hook handling is **two-tier**, separating warning from destruction:
- LIBERAL flag — any registered/present hook basename not in the current kit set is WARNED (surfaced by
  `check-install-drift.sh --consumer` and the `--update --dry-run` diff). This never removes anything, so
  a consumer's legitimate custom hooks are protected.
- CONSERVATIVE removal — only basenames listed in `modules.json .cut_hooks` (currently `["detect-loop"]`)
  are destructively deregistered. The kit must explicitly declare a hook cut before `--update` will remove
  it from a consumer.

Destructive removal runs only behind the rails: timestamped `.claude/.dereg-backup.<ts>/` (settings +
removed files) BEFORE any removal → survivor functional smoke (a kept enforce hook fires exit-2-block /
exit-0-allow, payload-driven not marker-gated) → revert-on-failure restores settings + cut files.
Arming is DECOUPLED — `.claude/enforce` is untouched unless `--arm`.

Rejected: a separate dereg script (subtraction); string-keyed removal (DRQ-1 — would miss the Phase-79
duplicate class); auto-removing every unknown basename (would delete a consumer's own custom hooks — hence
the `.cut_hooks` allow-list gate).

## Consequences

The kit now has a single, tested, basename-normalized deregistration primitive instead of re-derived jq
surgery each cut. Adding a future cut hook to the dereg path is one `modules.json .cut_hooks` entry. The
LIBERAL/CONSERVATIVE split means `--update` will never silently remove a consumer's bespoke hook, at the
cost that an actually-cut kit hook must be named in `.cut_hooks` to be reconciled away (a deliberate,
explicit step). The dereg path is SANDBOX-VERIFIED ONLY this phase (mktemp fixtures + seeded controls);
it has never run against a live consumer — live application is the gated follow-on filed in Blockers.
Known limitation: the revert-on-failure branch is inspection-verified, not fault-injection-tested — the
survivor probe is refreshed from real templates before the smoke so it always passes on the `--update`
path; the JSON-validity fail-stop is the only live fallback exercised.
