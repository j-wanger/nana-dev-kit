---
title: "Crash recovery dual condition"
aliases: [crash-recovery, session-crash-detection]
category: decisions
tags: [session-start, crash-recovery, hooks]
parents: [phase-26-memory-harness-hardening]
created: 2026-05-23
updated: 2026-05-23
source: plan
confidence: high
---

## Context

When a session crashes or is abandoned without debrief, _CURRENT_STATE.md becomes stale. A single condition (commits newer than mtime) fires too often -- normal mid-phase workflow produces commits before debrief runs.

## Decision

Dual condition for crash detection: (1) commits exist newer than _CURRENT_STATE.md mtime AND (2) no debrief commit exists in recent history. Both must be true to trigger advisory [recovery] output. Uses stat for mtime (macOS/Linux variants) and case-insensitive Debrief grep on git log.

Alternatives rejected:
- Single condition (commits > mtime): unacceptable false positive rate during normal workflow
- Full crash recovery with task/memory detection: over-scoped for current needs

## Consequences

False positive rate drops to near zero. Advisory-only output (exit 0) means no workflow disruption. Requires git repo and .dev-wiki to be present (graceful skip otherwise). Detection limited to commit-based signal -- non-commit work loss not detected.
