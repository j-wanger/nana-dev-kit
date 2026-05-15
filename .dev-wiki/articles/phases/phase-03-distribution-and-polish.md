---
title: "Phase 3: Distribution & Polish"
status: not-started
phase: 3
created: 2026-05-15T13:03:48
---

# Phase 3: Distribution & Polish

## Objective

Add versioning, release workflow, and edge-case hardening. Make the kit installable and upgradeable with confidence.

## Scope

- `VERSION` or version tagging strategy
- `.github/workflows/` (CI for the kit itself)
- `install.sh` (upgrade path)
- Edge case hardening

## Exit Criteria

- [ ] Tagged release exists with semantic version
- [ ] Upgrade path documented (re-running install.sh on existing installs)
- [ ] CI validates the kit itself (lint scripts, run tests)
- [ ] Edge cases handled: missing dirs, partial installs, permission errors

## Notes

- GitHub releases with git tags are the simplest distribution mechanism
- The kit installs to `~/.claude/` — upgrade logic needs to handle existing files gracefully
