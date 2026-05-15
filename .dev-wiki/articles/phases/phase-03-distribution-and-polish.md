---
title: "Phase 3: Distribution & Polish"
status: active
phase: 3
created: 2026-05-15T13:03:48
updated: 2026-05-15
---

# Phase 3: Distribution & Polish

## Objective

Add versioning, CI, and edge-case hardening. Make the kit installable and upgradeable with confidence.

## Approach

**Versioning:** VERSION file at repo root (single source of truth). Git tags (v0.1.0) created from it. install.sh stays unchanged -- no version-awareness needed at v0.x.

**CI:** GitHub Actions workflow at `.github/workflows/kit-ci.yml` (distinct from Python CI template at `templates/.github/workflows/ci.yml`). Runs shellcheck (available on ubuntu-latest) + `make test`. No local shellcheck dependency.

**Edge-case hardening:** Fix asymmetric error handling in install.sh. Add missing-dir and permission-error guards to install.sh and sync-rules.sh. Proportional to v0.x.

**Upgrade docs:** Add section to README.md -- "re-run bash install.sh to upgrade." No migration logic at v0.x.

**NOT in scope:** No GitHub release automation, no changelog, no package-manager distribution.

## Scope

- `VERSION` -- semantic version file
- `.github/workflows/kit-ci.yml` -- kit CI workflow
- `install.sh` -- edge-case hardening
- `scripts/sync-rules.sh` -- edge-case hardening
- `README.md` -- upgrade documentation

## Tasks (6 total: 3S + 3M)

1. **[S]** Create VERSION file with 0.1.0
2. **[M]** Harden install.sh edge cases (asymmetric error handling, source validation)
3. **[M]** Harden sync-rules.sh edge cases (writability checks, partial write guards)
4. **[M]** Create .github/workflows/kit-ci.yml (shellcheck + make test)
5. **[S]** Update README.md (upgrade section, line budget)
6. **[S]** Tag release v0.1.0 (annotated git tag)

## Key Decisions

- [[v0-versioning-strategy]]: VERSION file + git tags at v0.1.0, no version-awareness in install.sh
- [[kit-ci-separate-from-template]]: kit CI at kit-ci.yml, shellcheck CI-only

## Exit Criteria

- [ ] Tagged release exists with semantic version
- [ ] Upgrade path documented (re-running install.sh on existing installs)
- [ ] CI validates the kit itself (lint scripts, run tests)
- [ ] Edge cases handled: missing dirs, partial installs, permission errors
