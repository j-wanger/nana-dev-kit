<!-- nana:approved -->
# Spec: Phase 76 — Installed-Copy-Drift Guard

## Objective

Detect when the kit maintainer's installed `~/.claude` has drifted from the kit source
(`templates/.claude`), so a stale installed copy stops silently undermining work. The kit DEVELOPS in
`templates/` but RUNS from `~/.claude` — twice this has bitten: the Phase-73 "curator gap" (a stale
installed copy, source was correct) and Phase-75 (the kit's own `/dev-debrief` ran the *old*
`delivery-flow` because `~/.claude` was behind `templates/`). A deterministic, fail-open comparator,
scoped to the kit repo so it is signal not noise.

## Success Vision

Working in the nana-dev-kit repo, if `~/.claude` is behind `templates/.claude` on any kit-managed
copy-verbatim file, `session-start` emits a specific, actionable `[nana:drift]` advisory (names the count,
points at `install.sh`), and `install.sh --status` shows the same. **Silent everywhere else** —
consuming projects, and when in sync. The maintainer can no longer unknowingly run/test against a stale
installed harness.

## Scope

IN:
- `scripts/check-install-drift.sh` — the deterministic comparator. Reads `modules.json` for the
  kit-managed **copy-verbatim** file set (installed skills + global hooks + verbatim rules), diffs each
  `templates/.claude/…` against its installed counterpart under an installed-root (default
  `$HOME/.claude`, **overridable for hermetic tests**). Reports differing/missing files + a count.
  Fail-open. shellcheck + `bash -n` clean.
- `templates/.claude/hooks/session-start.sh` — advisory gated to `git-root == ~/.claude/.nana-dev-kit-path`
  (kit repo only): `[nana:drift] N kit file(s) differ from your installed ~/.claude — run install.sh to sync.`
  Once per session, fail-open.
- `install.sh --status` — add a drift line via the same comparator.
- `tests/test_install.sh` — EXTEND (no new test file → no README-count churn): detects an injected drift,
  silent when synced, exclusion-list respected (+ bounded-count assertion), fail-open, kit-repo scoping.

OUT (deferred, documented in T3):
- (B) consuming-project drift (`templates/` vs a project's `.claude/`) — different problem (projects pin a
  kit version deliberately), harder, unevidenced. YAGNI until it bites.
- `install.sh --link` symlink dev-mode — considered and rejected: symlinking `~/.claude` live means a broken
  WIP edit to `session-start.sh` breaks *every* session everywhere; copy-install gives a stable last-good
  checkpoint, and the drift is the price of that safety. The detector preserves the safety AND catches the
  forget. Recorded as a rejected alternative.

## Constraints

- Deterministic + FAIL-OPEN: the advisory never blocks a session start; the comparator never crashes on
  missing files.
- **Noise-scoped:** fires ONLY when the git-root / CWD equals the kit-path marker
  (`~/.claude/.nana-dev-kit-path`, written by install.sh). Consuming projects never run it. Once per session.
- Comparison set = kit-managed copy-verbatim files from `modules.json` (the single source of truth —
  [[decision:single-source-scope-tagged-hook-registration]]). A **pinned, bounded-count exclusion allow-list**
  for legitimately-divergent files (`settings.json` [merged by register-settings.py], `nana-personal.md`
  [user-customized], `py-session-state.md` [runtime], install metadata) — the firing-coverage-exemption analog,
  guarding against BOTH false positives and silent scope-shrink.
- The comparator accepts an installed-root override so tests run hermetically — **never touch the real
  `~/.claude`** in tests.
- Surgical; respect the `session-start.sh` line-cap (Phase-55 erosion scar).

## Assumptions

- `modules.json` authoritatively lists what `install.sh` copies verbatim (skills, global hooks).
- `~/.claude/.nana-dev-kit-path` reliably marks the kit repo (written by install.sh on core install).

## Exit Criteria

- [ ] `check-install-drift.sh`: detects a drift, silent when synced, respects the exclusion allow-list,
      fail-open; `shellcheck` + `bash -n` clean.
- [ ] `session-start` emits `[nana:drift]` in the kit repo when drifted; SILENT outside the kit repo and
      when synced; fail-open.
- [ ] `install.sh --status` shows the drift status.
- [ ] `make test` green (test_install extended; firing-coverage / registration / settings-template / README
      count all unchanged — no new test file, no new hook). `make eval` unchanged.
- [ ] (B) consuming-project drift + `--link` dev-mode recorded as deferred.
