---
title: "Phase 76: Installed-Copy-Drift Guard"
aliases: ["installed-copy-drift-guard-phase", "phase-76-installed-copy-drift-guard"]
category: phases
tags: [engineering, install, drift, session-start, deterministic-validator, dogfood, modules-json, path-canonicalization]
parents: []
created: 2026-05-31
updated: 2026-05-31
source: plan
status: active
scope: ["scripts/check-install-drift.sh", "templates/.claude/hooks/session-start.sh", "install.sh", "tests/test_install.sh", "tests/test_harden.sh"]
entry_criteria: "Phase 75 closed; the kit develops in templates/.claude but RUNS from ~/.claude, and a stale installed copy silently undermined work twice — the Phase-73 curator gap and the Phase-75 debrief running the OLD delivery-flow."
exit_criteria: "A deterministic fail-open comparator detects drift between templates/.claude and the installed ~/.claude (synced/drift/exclude/fail-open) and is shellcheck-clean; session-start emits [nana:drift] in the kit repo on drift, silent outside + when synced; install.sh --status shows it; make test green (no new test file/hook → no count/firing/registration churn); make eval unchanged."
---

# Phase 76: Installed-Copy-Drift Guard

## Objective

Detect when the maintainer's installed `~/.claude` has drifted from the kit source
(`templates/.claude`), so a stale installed copy stops silently undermining work. The kit develops
in `templates/` but RUNS from `~/.claude` — and was bit twice (the Phase-73 curator gap; the
Phase-75 debrief that ran the OLD `delivery-flow`). Detect-and-warn, scope (A) maintainer-side only.
The 3rd dogfood→harden fix after Phases 74-75.

## Scope

- `scripts/check-install-drift.sh` (NEW — deterministic, fail-open comparator)
- `templates/.claude/hooks/session-start.sh` (kit-repo-scoped `[nana:drift]` advisory)
- `install.sh` (`--status` drift line via the same comparator)
- `tests/test_install.sh` (+8 tests), `tests/test_harden.sh` (+4 firing tests) — extended in place, no new file

## Exit Criteria

- [x] T1[M]: `scripts/check-install-drift.sh` deterministic comparator (comparison set from `modules.json` minus a pinned bounded 3-entry exclusion allow-list; report/`--count`/`--excludes`; installed-root override; not-installed skill dirs skipped) + 7 RED-first tests; `bash -n` clean.
- [x] T2[S]: `[nana:drift]` advisory in `session-start.sh` (kit-repo-scoped via a **canonical-physical-path** gate) + `install.sh --status` drift line + 4 firing tests (fires in-kit-on-drift / silent-outside / fail-open).
- [x] T3[S]: deferrals recorded ((B) consuming-project drift; `--link` symlink mode, rejected); make test green, make eval 52/52 unchanged, firing-coverage 21/21, eval/ git-diff-clean.

## Constraints

- FAIL-OPEN (the advisory never blocks) — every read guarded, exit 0 on any error; every recovery/advisory check in the kit is advisory (blocking risks the enforce-spec self-lockout class).
- Noise-scoped to the kit repo: during active kit development `templates/` is constantly ahead of `~/.claude`, so an unconditional warning becomes wallpaper (the Phase-55 advisory-rot scar). Gated to CWD == the path marker, once/session.
- Comparison set + bounded exclusion allow-list from `modules.json` (the firing-coverage-exemption analog); tests use an installed-root override (NEVER touch real `~/.claude`); respect the session-start line-cap (kept the block inline rather than extracting a curator — extraction would grow the firing-coverage `extra_dirs` denominator).

## Notes

The kit-repo gate compares CANONICAL physical paths — `git rev-parse --show-toplevel` is already
physical; the marker is resolved via `cd && pwd -P`. A string compare silently never fired under a
symlinked checkout (macOS `/var`→`/private/var`), a real correctness catch found during T2 testing.
**DOGFOOD:** the guard's first firing caught the maintainer's real `~/.claude` 36 files behind
`templates/` — including the exact Phase-75 scar (`skills/dev-debrief/delivery-flow.md`); resynced
via `install.sh` this session (drift 36 → 0). Reviewer 9/10; two MEDIUM observations by-design
(project-scoped hooks incl. session-start.sh itself are out of the comparison set — a bounded
false-negative now documented in the comparator header; missing-whole-skill-dir = not-installed).
Decision [[installed-copy-drift-guard]]. The dogfood→harness loop: [[delivery-commit-verification]]
(Phase 75), [[harden-consuming-project-scaffold]] (Phase 74).
