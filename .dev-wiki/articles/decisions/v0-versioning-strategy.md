---
title: "v0 versioning strategy"
aliases: [versioning strategy, VERSION file, v0.1.0]
category: decisions
tags: [versioning, release, distribution]
parents: [phase-03-distribution-and-polish]
created: 2026-05-15
updated: 2026-05-15
source: plan
status: accepted
confidence: medium
---

## Context

Phase 3 needs a versioning strategy for the kit. The project is a shell-only toolkit at early maturity. Options considered: (1) VERSION file at repo root + git tags starting at v0.1.0, (2) starting at v1.0.0, (3) git-tag-only with no VERSION file.

## Decision

VERSION file at repo root as single source of truth, with annotated git tags (v0.1.0). Starting at v0.x to signal experimental/evolving status. install.sh gets no version-awareness at v0.x -- upgrades are unconditional overwrite via re-running install.sh.

v1.0.0 was rejected because it implies stability guarantees and would require upgrade-path investment disproportionate to current maturity. Git-tag-only was rejected because having a file makes the version accessible without git context (e.g., in CI, in scripts).

## Consequences

- Simple versioning with minimal infrastructure (one file, git tags)
- v0.x communicates that breaking changes are expected
- No migration logic needed -- install.sh always overwrites
- When the kit matures to v1.0, a version-aware upgrade strategy will be needed
- VERSION file can be read by CI, scripts, or documentation without git access
