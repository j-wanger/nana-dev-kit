---
title: "Session-start.sh modular sourcing pattern"
aliases: [session-start-refactor, hook-modular-source]
category: decisions
tags: [hooks, refactoring, session-start]
parents: [phase-22-session-start-refactor]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

session-start.sh grew to 125 lines with 8 interleaved concerns across Phases 15-17. Two modules (working-knowledge pruning at 44 lines, memory nudge at 21 lines) account for over half the file. The remaining 6 concerns are 5-10 lines each.

## Decision

Extract the two heavy modules into `session-start.d/wk-prune.sh` and `session-start.d/memory-nudge.sh`, sourced (not subprocessed) by the orchestrator. Source is required because working-knowledge pruning writes to CWD files ($WK_FILE, $STALE_QUEUE). Each module defines a single function with no top-level side effects. The orchestrator resolves module paths via `HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"`.

Alternative considered: refactoring into functions within the same file (thin main() at bottom). Rejected because separate files are independently testable and more readable at 45-line module size.

session-start.d/ is template-only (not globally installed by install.sh). Enforcement hooks install globally; session-start.sh is a project template.

## Consequences

- session-start.sh shrinks from ~125 to ~60 lines
- Modules are independently syntax-checkable (`bash -n`)
- Source-path resolution requires `HOOK_DIR` pattern — templates must be used from their directory
- No install.sh changes needed for this refactor
