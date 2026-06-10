# Install-Path Inventory — Phase 85

Every path that ships kit hook scripts to an installed root, with line-cited evidence and a
fix/exempt status. Checkpoint-1 evidence (spec precondition: this inventory completes BEFORE any
live write). Format validated by `check-inventory.sh`; `pending` rows are flipped to `fixed` at
close-out (T8) only after the fixing task's success criterion passes.

Date: 2026-06-10 (plan-time evidence gathered same day; greps re-runnable as cited).

causal-path verdict: confirmed

## Shipping paths

| path | evidence | status |
|---|---|---|
| install.sh global (install.sh:288-309) | copies ONLY scope:global hook scripts FLAT to ~/.claude/hooks (:298-302); zero hook-dir handling. session-start.sh is scope:project (modules.json:51), so this path never shipped it — the gap here is the missing INVARIANT (ship dirs alongside any consumer script it ships), not incident 5's cause. Fix: T3. | fixed |
| install.sh --project-local (install.sh:72, :88-93) | ships extra_dirs, but `cp "$HOOKS_SRC/$d"/*.sh` aborts the installer on an empty/no-match glob under `set -euo pipefail` (:14) — a partial install reproduces the registered-but-broken class mid-sequence; copied .d files get no chmod (benign: sourced, see exemption below). Fix: T3 (robustness) + T2 (hook_dirs key). | fixed |
| py-init template copy (templates/.claude/skills/py-init/SKILL.md:108) | `cp -R "$KIT/templates/.claude/hooks/." .claude/hooks/` — recursive, carries session-start.d/; `find … chmod +x` at :109. Verified by grep 2026-06-10. | exempt: recursive since Phase 74 |
| ts-init template copy (templates/.claude/skills/ts-init/SKILL.md:145) | identical recursive `cp -R` pattern with the same session-start.d comment. Verified by grep 2026-06-10. | exempt: recursive since Phase 74 |
| nana-init (templates/.claude/skills/nana-init/SKILL.md) | pure dispatcher — zero `cp` commands (grep exit 1, 2026-06-10); all copying happens in the py-init/ts-init steps it dispatches to. | exempt: no copy logic |
| Phase-82 drift-guided resync (procedure, not a script) | check-install-drift.sh output used as the refresh shopping list; pass 2b collects hooks via `find -maxdepth 1 -name '*.sh'` (check-install-drift.sh:103-108) — structurally blind to session-start.d/, so the resync shipped the script without its dir. Fix: T4 directory cells make the shopping list complete. | fixed |

## Causal-path hypothesis (A1 — deferred don't-know, checkpoint 1 decides)

Verdict above: **confirmed** — incident 5 (2026-06-09, ~/.claude/hooks/session-start.d/ empty while
session-start.sh was md5-current; every SessionStart errored machine-wide) was caused by the
Phase-82 drift-guided resync working from a checker shopping list that omits directory contents.

Evidence chain:
- session-start.sh is scope:project (modules.json:51); install.sh's global path selects
  `scope == "global"` only (install.sh:289-293) — it cannot have placed or refreshed the file.
- py-init/ts-init copy recursively (citations above) into PROJECT roots, never ~/.claude.
- The ~/.claude copy dates from the pre-Phase-79 global-install era; the Phase-82 refresh synced it
  current via the drift checker's comparison set (record: _CURRENT_STATE.md Phase-84 install-gap
  blocker; eval/hook-hygiene coverage-matrix addendum).
- The checker's pass-2b set (`find -maxdepth 1 -name '*.sh'`, check-install-drift.sh:103-108)
  includes session-start.sh but not session-start.d/* — exactly reproducing the observed end state:
  script current, directory never shipped.
- No other refresh machinery exists: no Makefile refresh target (only `sync-rules`, `template`),
  and `install.sh --status` is read-only (install.sh:110+).

Refutation surface: if checkpoint-1 review surfaces another refresh procedure (e.g. an ad-hoc
maintainer script outside the repo), this verdict flips and the spec's conditional scope clause
applies.

## Consumption status — ~/.claude/hooks/session-start.sh (A3 checkpoint-1 input)

- **registration-dead at plan time (2026-06-10):** zero session-start references in
  ~/.claude/settings.json (jq `.. | .command?` extraction; grep exit 1). All live registrations are
  project-local forms: nana-dev-kit and edge-screener use
  `${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.sh`; edge-analyst, ai-game, fate use relative
  `.claude/hooks/session-start.sh`. Positive control: known-registered hooks appeared in the same
  extraction (the instrument reads non-zero where non-zero is known).
- Implication: nothing executes the ~/.claude copy today. Ship-vs-DISPOSE for the registration-dead
  ~/.claude project-scope hook copies is decided at HARD checkpoint 1 (T5) with this evidence; until
  then the checker keeps comparing the present copy (Phase-82 presence charter), so there is no
  stale-invisible window either way.

## Mode-drift exemption (pinned, reasoned)

- session-start.d/* files are SOURCED by session-start.sh (templates/.claude/hooks/session-start.sh:10-12),
  never direct-exec'd → the exec bit is not load-bearing there. Directory-currency cells compare
  CONTENT only (`cmp -s`), consistent with the checker's existing semantics (check-install-drift.sh:128).
- Top-level hooks ARE direct-exec'd; mode drift on installed copies is a known uncovered axis
  (Phase-84 exec-bit incident; test_templates.sh guards templates only). OUT of Phase-85 scope —
  filed as a reasoned exemption, re-trigger: a mode-related firing failure on an installed copy.
