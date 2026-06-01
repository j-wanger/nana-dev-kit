# Active Phase Context

Phase: 76 — Installed-Copy-Drift Guard
Status: Active — READY FOR COMPLETION (all 3 tasks [x], exit criteria met; delivery gate pending)

Objective: Detect when the maintainer's installed `~/.claude` has drifted from kit source
`templates/.claude` (kit develops in templates/ but RUNS from ~/.claude — bit twice: Phase-73, Phase-75).

Delivered: `scripts/check-install-drift.sh` (modules.json comparison set minus a pinned 3-entry exclusion
allow-list; installed-root override) → kit-repo-scoped `[nana:drift]` session-start advisory (canonical-
path gate) + install.sh --status. FAIL-OPEN, noise-scoped; tests never touch real ~/.claude; no count
churn. Reviewer 9/10. DOGFOOD: caught the real ~/.claude 36 files behind templates/ — resynced to 0.

Decision: [[installed-copy-drift-guard]] (high). Deferred: (B) consuming-project drift; --link symlink mode.
Abort: if blocked >3 attempts, mark [blocked] + ask user skip/abort.

Gates:
- [x] Direction confirmed by user (approach approved 2026-05-31 — "A only")
- [x] Delivery accepted (post-implementation report 2026-05-31)
