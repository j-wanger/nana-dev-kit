# Active Phase Context

Phase: 76 — Installed-Copy-Drift Guard
Status: Active

Objective: Detect when the maintainer's installed `~/.claude` has drifted from the kit source
(`templates/.claude`), so a stale installed copy stops silently undermining work. The kit develops in
templates/ but RUNS from ~/.claude — bit twice (Phase-73 curator gap; Phase-75 debrief ran the OLD
delivery-flow). Deterministic, fail-open, scoped to the kit repo so it is signal not noise.

Scope:
- `scripts/check-install-drift.sh` — comparator over kit-managed copy-verbatim files (modules.json:
  skills + global hooks + verbatim rules), templates/.claude vs installed-root (default ~/.claude,
  OVERRIDABLE for hermetic tests); pinned exclusion allow-list (settings.json [merged], nana-personal.md, …).
- `templates/.claude/hooks/session-start.sh` — `[nana:drift]` advisory gated to git-root == the
  `~/.claude/.nana-dev-kit-path` marker (kit repo only); fail-open, once/session.
- `install.sh --status` — drift line via the same script. tests/test_install.sh extended (no new file).

Key constraints: FAIL-OPEN (never blocks); noise-scoped to the kit repo; comparison set + bounded-count
exclusion allow-list from modules.json (firing-coverage-exemption analog); tests use an installed-root
override (NEVER touch real ~/.claude); surgical, respect the session-start line-cap.

Exit criteria: comparator detect/silent/exclude/fail-open + shellcheck clean; session-start emits
`[nana:drift]` in the kit repo on drift, silent outside + when synced; `install.sh --status` shows it;
make test green (no new test file/hook → no count/firing/registration churn); make eval unchanged.

Abort: if blocked >3 attempts on a task, mark [blocked] + ask user skip/abort.

Decision: [[installed-copy-drift-guard]]. Spec: `specs/phase-76-installed-copy-drift-guard.md`.
Deferred: (B) consuming-project drift; `install.sh --link` symlink dev-mode.

Gates:
- [x] Direction confirmed by user (approach approved 2026-05-31 — "A only")
- [ ] Delivery accepted (post-implementation report)
