---
title: "jq guard in install.sh: fail-STOP pattern"
aliases: [jq-install-guard, jq-fail-stop]
category: decisions
tags: [install, jq, guard, dependency, fail-stop]
parents: [phase-41-harness-hardening-process-safeguards]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

install.sh reads modules.json via jq (introduced Phase 40) but has no upfront jq availability check. Hooks use `command -v jq >/dev/null 2>&1 || exit 0` (fail-open) because a missing tool should not block the developer's workflow. install.sh has different requirements: it runs once, explicitly, and failure to parse modules.json silently produces a broken installation.

## Decision

install.sh uses fail-STOP pattern (`exit 1`) unlike hooks which use fail-open (`exit 0`). The guard runs before the first jq call and includes a multi-platform install hint:
- macOS: `brew install jq`
- Linux: `apt install jq` (or equivalent)

This follows the existing install.sh convention of upfront source validation (established Phase 3).

## Consequences

- Users without jq get a clear error message and install instructions instead of a cryptic failure
- Different pattern from hooks is intentional and documented (fail-stop vs fail-open)
- No behavior change for users who already have jq installed (vast majority)
