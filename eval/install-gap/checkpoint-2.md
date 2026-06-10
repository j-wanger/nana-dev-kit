# Checkpoint 2 — edge-screener migration, Phase 85

Date: 2026-06-10. HARD checkpoint per spec: no write to /Users/jwang/edge-screener before approval.

## DRQ-1 verdict (A2 STOP-and-re-present satisfied)

**dedupe (string-keyed)** — see `drq1-verification.md` (two real headless-session probes with
positive controls). Edge-screener's hand-patched form is string-identical to what
register-settings.py writes, so there is NO active double-fire today; the migration is hygiene
with a real failure mode behind it (a future form change would flip the identical-string pair
from dedupe to double-fire silently). Risk model: calmer than planned; revert = file restore.

## Rehearsal (full migration on a mktemp COPY of edge-screener/.claude): GREEN

1. Surgery: `settings.json` → `{}` — safe because the file contains ONLY the 17 kit-owned hook
   registrations (verified: no user-owned entries, no permissions, no prompt hooks).
2. `install.sh --project-local` from the copy root: exit 0; fresh hooks + session-start.d (3
   curators) shipped via hook_dirs; 17 hooks registered in `settings.local.json`; `.claude/enforce`
   marker created.
3. `assert-edge-screener-registration.sh` on the copy: PASS — 17 kit-owned registrations, each
   basename exactly once across the union, all scope:project hooks present (none disarmed).
4. Survivor functional smoke on the copy: block-dangerous-bash.sh blocks the dangerous payload
   (exit 2) AND allows a benign one (exit 0) — both paths, per HEU-012.

## Proposed live action (on approval)

1. Timestamped backup: `tar -czf /Users/jwang/edge-screener/.claude/backup-phase85-<ts>.tgz`
   of `settings.json`, `settings.json.bak`, `hooks/` (restore = untar; mechanism identical to the
   checkpoint-1 backup whose restore was sandbox-tested today).
2. CWD assertion: refuse to run unless the target dir contains edge-screener's project markers.
3. Surgery: `settings.json` → `{}`.
4. `install.sh --project-local` from /Users/jwang/edge-screener.
5. `.bak` disposition: DELETE `settings.json.bak` (the Phase-79 hand-patch rollback is poisoned
   post-migration — restoring it would resurrect the dual-registration state); the fresh
   timestamped backup from step 1 supersedes it as the rollback artifact (dated note here).
6. Post-run assertions (logged below): assert-edge-screener-registration.sh PASS; one headless
   session (`claude -p`) in edge-screener → SessionStart chain runs without error and the
   firing-count probe shows each fired hook exactly once.
7. Revert-on-failure: restore step-1 backup, file the divergence.

firing-count: 1

## Approval

- [x] Maintainer approved (date): 2026-06-10 (AskUserQuestion in-session; .bak disposal included)

## Execution record (post-approval, 2026-06-10)

- CWD assertion passed (pyproject.toml + .dev-wiki present).
- Backup: `edge-screener/.claude/backup-phase85-20260610-094413.tgz` (settings.json + .bak + hooks).
- Surgery: settings.json → `{}` (0 hook events remain); `install.sh --project-local` exit 0;
  `settings.json.bak` DELETED (poisoned rollback superseded by the dated backup above).
- Post-run: assert-edge-screener-registration.sh PASS (17 kit-owned, each basename exactly once,
  all scope:project hooks present); session-start.d 3 curators present; enforce marker present.
- Firing probe: one headless session (`claude -p`, haiku) → enforcement.log delta 3 rows, each
  Stop-event hook exactly once (check-tests-were-run 1, enforce-loop 1, py-review 1) — the
  firing-count line above is this probe's per-hook result.
- Revert: not needed.
