---
title: Installed-Copy-Drift Guard — detect-and-warn over symlink, kit-maintainer scope
status: active
confidence: medium
date: 2026-05-31
phase: 76
source: plan
tags: [install, drift, session-start, deterministic-validator, dogfood, modules-json]
---

# Installed-Copy-Drift Guard

## Decision

Detect drift between the kit source (`templates/.claude`) and the maintainer's installed `~/.claude`,
and warn — rather than eliminate the drift class via symlinking. Scope to the kit maintainer's own
`~/.claude` (drift class A); defer consuming-project drift (class B).

Mechanism: a deterministic `scripts/check-install-drift.sh` comparator (kit-managed copy-verbatim files
from `modules.json`, minus a pinned exclusion allow-list for merged/customized files), surfaced at
session-start (gated to the kit repo via the `~/.claude/.nana-dev-kit-path` marker) and in
`install.sh --status`. Fail-open, advisory, once per session.

## Rationale

The kit develops in `templates/` but runs from `~/.claude`, so a stale installed copy silently
undermines work — twice now: the Phase-73 "curator gap" (stale installed copy; source was fine) and
Phase-75 (the kit's own `/dev-debrief` ran the OLD `delivery-flow` because `~/.claude` lagged
`templates/`). That's the evidence (2 instances, both class-A).

**Why detect-and-warn over symlink (the eliminate-the-class alternative):** an `install.sh --link`
dev-mode that symlinks `~/.claude` kit files to `templates/` would make source edits instantly live —
no re-install, no drift. But symlinking live means a broken WIP edit to `session-start.sh` (or any hook)
instantly breaks *every* session in *every* project. Copy-install gives a stable last-good checkpoint;
the drift is the price of that safety. The detector PRESERVES that safety while catching the
forgot-to-reinstall — strictly better for the actual failure mode.

**Why noise-scoped:** during active kit development `templates/` is constantly ahead of `~/.claude`, so
an unconditional drift warning becomes wallpaper (the advisory-rot that eroded the Phase-55 session-start
cap). Gating to the kit repo (CWD == the path marker), once per session, with a specific actionable
message keeps it signal.

## Alternatives considered

- **`install.sh --link` symlink dev-mode.** REJECTED as the mechanism — live-WIP-breakage risk; copy-install
  safety preferred. May return as an opt-in escape hatch later.
- **Consuming-project drift (class B).** DEFERRED — projects pin a kit version deliberately; drift there is
  often intentional, the detection is harder (no co-located source), and it is unevidenced.
- **Record an install-rev and compare revs.** Not chosen — install.sh records only the kit *path*, no
  content-rev. Direct content comparison needs no new marker and catches uncommitted drift too.

## Consequences

- Catches future class-A drift automatically at the maintainer's session-start; no workflow change.
- The exclusion allow-list must be maintained (bounded-count asserted) — adding a new merged/customized
  installed file requires a justified allow-list entry.
- This guard itself only goes live for nana-dev-kit after an `install.sh` re-sync (the very drift it
  detects) — first install bootstraps it.

## Links

- Spec: `specs/phase-76-installed-copy-drift-guard.md`
- Evidence: [[delivery-commit-verification]] (Phase 75, stale debrief), [[harden-consuming-project-scaffold]]
  (Phase 74 / Phase-73 curator gap).
- Manifest source: [[decision:single-source-scope-tagged-hook-registration]]; posture:
  [[decision:functional-smoke-invariant-rule]].
