---
title: "Status command in install.sh"
aliases: [install-status, nana-status, install-sh-status]
category: decisions
tags: [install, dx, discoverability, status]
parents: [phase-28-dx-discoverability]
created: 2026-05-23
updated: 2026-05-23
source: plan
confidence: medium
---

## Context

Users have no way to check what's currently installed by the nana dev kit. After running install.sh, there's no inventory command to see which skills, hooks, rules, and infrastructure components are present or missing.

## Decision

**Add `--status` flag to install.sh** rather than creating a separate script. install.sh already has flag parser infrastructure (`--dry-run`, `--all`, `--core-only`, `--no-python`) and owns the "what's installed" concern. A separate `nana-status.sh` would be a new file to maintain with duplicated path knowledge.

The status command performs dynamic filesystem checks: counts skills, hooks, rules, checks memory venv, reads VERSION, checks enforcement marker. Output is grouped by module category for readability.

Alternative considered: standalone `nana-status.sh` script -- rejected because it adds maintenance surface and duplicates the path knowledge already in install.sh.

## Consequences

- install.sh grows ~40-60 lines for the `--status` case handler.
- Status output must stay in sync with install.sh's module definitions. If a new module is added to install, status should reflect it.
- test_install.sh needs new assertions for the `--status` flag.
- No changes needed to settings.json or hooks -- this is a pure CLI addition.
