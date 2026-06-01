---
title: "Phase 76 complete — Installed-Copy-Drift Guard (the dogfood the guard itself caught)"
aliases: []
category: journal
tags: [install, drift, session-start, deterministic-validator, dogfood, modules-json, path-canonicalization]
parents: [phase-76-installed-copy-drift-guard]
created: 2026-05-31
updated: 2026-05-31
source: debrief
duration: ~1 focused session
---

# Phase 76 complete — Installed-Copy-Drift Guard

## What Happened

- The kit develops in `templates/.claude` but RUNS from the maintainer's `~/.claude`, and a stale
  installed copy silently undermined work twice (Phase-73 curator gap; Phase-75 debrief ran the OLD
  delivery-flow). Phase 76 builds a deterministic, fail-open guard that surfaces that drift so it stops
  being silent. Detect-and-warn, scope (A) maintainer-side only (symlink/`--link` was rejected, not
  merely deferred — live-WIP-breakage risk).
- **T1[M]** — `scripts/check-install-drift.sh`: a bash+jq comparator (NO LLM). Comparison set derived
  from `modules.json` (installed skills + `scope:global` hooks + managed rules-dir glob); a pinned
  bounded-count exclusion allow-list (3 entries: `rules/nana-personal.md`, `rules/py-session-state.md`,
  `settings.json` [merged]) strips template-only/customized files; not-installed skill dirs are SKIPPED
  (no partial-install false positives). Modes: report (exit 0 synced / 1 drift), `--count` (always
  exit 0), `--excludes`. Installed-root override via arg or `$NANA_INSTALLED_ROOT` for hermetic tests
  (never touches real `~/.claude`). 7 RED-first tests added to `tests/test_install.sh`.
- **T2[S]** — `[nana:drift]` advisory in `session-start.sh`, GATED to the kit repo, + an "Install drift"
  line in `install.sh --status` via the same comparator. 4 firing tests in `tests/test_harden.sh`
  (fires in-kit-on-drift / silent-outside / fail-open).
- **T3[S]** — recorded the two deferrals ((B) consuming-project drift; `--link` symlink mode) + full
  regression.

## Decisions Made

- [[installed-copy-drift-guard|Installed-Copy-Drift Guard]] — finalized this session to `confidence: high`,
  `source: debrief`, with an "Implementation notes (Phase 76 delivery)" subsection. The planning-draft
  decision was realized as approved; the implementation refinements (comparison-set derivation, the
  3-entry allow-list, the canonical-path gate, the inline-vs-curator choice) are notes on the one
  decision, not new decisions.

## Problems Solved

- **Path-canonicalization correctness catch (T2):** the kit-repo gate compared a string git-root against
  the stored `~/.claude/.nana-dev-kit-path` marker, which silently never fired under a symlinked checkout
  (macOS `/var` → `/private/var`). Fixed by comparing CANONICAL physical paths — `git rev-parse
  --show-toplevel` is already physical; the marker is resolved via `cd && pwd -P`. In-scope T2 debugging,
  not a deviation.

## Open Questions

- None new. The two Phase-76 deferrals — (B) consuming-project drift and the rejected `install.sh --link`
  symlink dev-mode — are recorded verbatim in `_CURRENT_STATE.md` Blockers under `[deferred: Phase-76]`.

## Artifacts Changed

- `scripts/check-install-drift.sh` (NEW — deterministic fail-open drift comparator, bash+jq, no LLM)
- `templates/.claude/hooks/session-start.sh` (added the kit-repo-scoped `[nana:drift]` advisory block; now 108 lines)
- `install.sh` (`--status` "Install drift" line via the same comparator)
- `tests/test_install.sh` (+8 tests → 120 passed), `tests/test_harden.sh` (+4 → 22 passed)
- `.dev-wiki/articles/decisions/installed-copy-drift-guard.md` (finalized to high / debrief + delivery notes)

## Related

- [[phase-76-installed-copy-drift-guard|Phase 76: Installed-Copy-Drift Guard]] — parent phase
- [[delivery-commit-verification]] (Phase 75) + [[harden-consuming-project-scaffold]] (Phase 74) — the prior dogfood→harden fixes; this is the 3rd in the loop

## Soft Observations / Phase N+1 Candidates

- **DOGFOOD (headline):** the maintainer's real `~/.claude` was 36 files behind `templates/` at session
  start — INCLUDING `skills/dev-debrief/delivery-flow.md` (the exact Phase-75 scar), the whole
  dev-plan/dev-debrief skills, and `rules/file-lifecycle.md`. Resynced via `bash install.sh` THIS session;
  detect→resync→silent verified end-to-end (drift 36 → 0, `--status` "drift: none"). The guard's first
  firing confirmed the drift problem was real AND actively recurring. No follow-up phase needed — the
  guard addresses it. | evidence: this journal + live `--count` 0 post-resync.
- **session-start.sh is now 108 lines** (two inline advisory blocks: Phase-75 delivery-divergence +
  Phase-76 drift), approaching the Phase-55 erosion-scar territory. If a 3rd advisory block lands,
  consider extracting the advisory cluster to a `session-start.d/` curator — but that interacts with the
  firing-coverage `extra_dirs` denominator (the reason this phase kept it inline). | candidate:
  "session-start advisory consolidation."
- **`articles/files/` coverage is sparse + unmaintained** (1/9 scripts, 6/18 hooks; Phase-74's new
  `py-review-stop.sh` got no article). Cat-7 self-check flagged the missing article for
  `check-install-drift.sh`; accepted as consistent with project practice. | candidate: a disposition
  decision — either RETIRE `articles/files/` (subtraction) or maintain it systematically; the current
  half-state provides no reliable invariant.
- **Reviewer MEDIUM (by-design, recorded):** project-scoped hooks (incl. `session-start.sh` itself) are
  out of the comparison set — a bounded false-negative, now documented in the comparator header.
  Re-trigger: a project-scoped hook's installed copy drifts and bites.
