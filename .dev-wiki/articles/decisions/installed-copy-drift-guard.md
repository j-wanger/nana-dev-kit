---
title: Installed-Copy-Drift Guard — detect-and-warn over symlink, kit-maintainer scope
status: active
confidence: high
date: 2026-05-31
phase: 76
source: debrief
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

## Implementation notes (Phase 76 delivery)

How the approved decision was realized (these are refinements of the one approved decision, not
separate decisions):

1. **Comparison set + bounded exclusion allow-list.** The comparison set is derived from
   `modules.json` (installed skills + `scope:global` hooks + the managed rules-dir glob). The pinned
   exclusion allow-list has exactly 3 entries — `rules/nana-personal.md`, `rules/py-session-state.md`,
   `settings.json` (merged). It EARNS its complexity by removing template-only rule files the rules-dir
   glob picks up but `install.sh` does not copy verbatim. Not-installed skill dirs are SKIPPED (avoids
   partial-install false positives; assumes the maintainer's `--all` install).

2. **Canonical physical-path gate (correctness catch).** The kit-repo gate compares CANONICAL physical
   paths: `git rev-parse --show-toplevel` is already physical, and the marker is resolved via
   `cd && pwd -P`. A plain string compare silently never fired under a symlinked checkout
   (macOS `/var` → `/private/var`) — a real correctness bug found during T2 testing.

3. **Advisory kept INLINE in session-start.sh (not extracted).** Extraction to a `session-start.d/`
   curator would add to the firing-coverage `extra_dirs` denominator, violating T3's "21/21 unchanged"
   constraint; the block is small/tested/cohesive (consistent with the Phase-75 delivery-divergence
   sibling). session-start.sh is now 108 lines (two inline advisory blocks).

4. **Reviewer 9/10 accept.** Two MEDIUM observations are by-design: project-scoped hooks (incl.
   `session-start.sh` itself) are out of the comparison set — a bounded false-negative, now documented
   in the comparator header; a missing whole-skill-dir is treated as not-installed, not drift.

5. **Dogfood confirmation.** At session start the maintainer's real `~/.claude` was 36 files behind
   `templates/` — including `skills/dev-debrief/delivery-flow.md` (the exact Phase-75 scar). Resynced
   via `install.sh` this session; detect→resync→silent verified end-to-end (drift 36 → 0).

## Links

- Spec: `specs/phase-76-installed-copy-drift-guard.md`
- Evidence: [[delivery-commit-verification]] (Phase 75, stale debrief), [[harden-consuming-project-scaffold]]
  (Phase 74 / Phase-73 curator gap).
- Manifest source: [[decision:single-source-scope-tagged-hook-registration]]; posture:
  [[decision:functional-smoke-invariant-rule]].
