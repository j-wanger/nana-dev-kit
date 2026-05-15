# Active Phase Context

Phase: 3 - Distribution & Polish
Status: Active, ~0%, 0/6 tasks done, 0/4 exit criteria met
Objective: Add versioning, CI, edge-case hardening, upgrade docs.

Scope globs: VERSION, .github/workflows/kit-ci.yml, install.sh, scripts/sync-rules.sh, README.md, tests/test_install.sh, tests/test_sync_rules.sh

Key constraints:
- Zero-dependency (bash only); shellcheck is CI-only, not local
- install.sh stays minimal (3 files); no version-awareness at v0.x
- v0.x signals experimental; unconditional overwrite on upgrade

Exit criteria:
1. Tagged release (v0.1.0) with VERSION file
2. Upgrade path documented in README
3. Kit CI (shellcheck + make test) at .github/workflows/kit-ci.yml
4. Edge cases hardened in install.sh and sync-rules.sh

Abort: if blocked >3 attempts on any task, ask user: skip or abort phase
