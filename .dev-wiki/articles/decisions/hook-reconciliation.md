---
title: "Hook Reconciliation: Per-Hook Disposition for 6 Global-Only Hooks"
aliases: [hook-reconciliation, t2-reconciliation, global-hook-disposition]
category: decisions
tags: [hooks, reconciliation, audit, phase-36, t2]
parents: [phase-36-hooks-audit-housekeeping]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Phase 36 Task 2 deliverable: per-hook disposition (backport / delete / tolerate) for each of the 6 hooks present in the user's `~/.claude/hooks/` but absent from kit `templates/.claude/hooks/`. Decisions surface to user for approval before T4 executes anything.

Evidence basis: [[hook-error-evidence]].

## Disposition Table

| # | Hook | Disposition | Rationale |
|---|------|-------------|-----------|
| 1 | `context-size-check.sh` | **backport** | UserPromptSubmit hook monitoring transcript size with one-warning-per-session flag (`.claude/.context-warned`). Generally useful, not dev-wiki-specific. Threshold (5MB) is calibrated. No conflict with any kit hook. |
| 2 | `dev-wiki-post-commit.sh` | **delete** (superseded) | Functionally equivalent to kit's existing `post-commit.sh` but less robust: no `set -euo pipefail`, no opt-in `~/.claude/enforce` marker check, no exit-code parsing, weaker jq fallback. Kit's version emits the same `[dev-wiki:post-commit]` trigger pattern that `dev-wiki-hooks.md` documents. Delete the global file and register kit's `post-commit.sh` in its slot via install.sh. |
| 3 | `dev-wiki-scope-check.sh` | **backport** | PreToolUse:Write\|Edit hook warning when editing outside active task scope. Emits `[dev-wiki:scope-check]` trigger pattern documented in kit's `dev-wiki-hooks.md`. No kit equivalent exists — this is a documented-but-unshipped hook (shipping gap). |
| 4 | `post-compact.sh` | **backport** | PostCompact hook that re-emits recall guidance after compaction (memory category=correction, active-phase.md). Reads `.claude/.session-anchor` if present. Complements kit's existing `pre-compact.sh`. No kit equivalent. |
| 5 | `session-stop.sh` | **backport** | Stop hook that writes `.dev-wiki/.session-end` breadcrumb (already in active use — see existing `.session-end` file in CWD). Source of the session-end metadata that session-start.sh reads. No kit equivalent. |
| 6 | `stale-queue.sh` | **backport** | PostToolUse:Edit\|Write hook that appends changed paths to `.dev-wiki/.stale-queue` for incremental refresh. Referenced by `dev-wiki-reference.md` Section R. No kit equivalent. |

**Summary: 5 backport, 1 delete, 0 tolerate.**

## Secondary Finding (informational, not part of spec exit criterion #1)

Six kit-shipped hooks at `templates/.claude/hooks/` are NEVER copied by `install.sh` (lines 296-302 install only 6 of 12):

- `audit-log.sh` — PostToolUse: JSONL audit record per file write
- `auto-ruff-format.sh` — PostToolUse: ruff auto-format on Python writes
- `block-dangerous-bash.sh` — PreToolUse:Bash: blocks rm -rf, force-push, --no-verify, reset --hard
- `check-tests-were-run.sh` — Stop: reminds about tests
- `scan-secrets.sh` — PostToolUse: gitleaks/secret scanning
- `session-start.sh` — SessionStart: dev-wiki state, memory nudge, gate-check

These appear intended for **project-local install** (per-project `.claude/hooks/` rather than global `~/.claude/hooks/`). install.sh has no project-local install mode. Disposition for these 6 is OUT OF SCOPE for T2 (not in the exit criterion #1 hook list) but logged here for T4 consideration — if install.sh gains a project-local module, they would be shipped through it.

## Consequences

- **T4 work increases** (5 backports + 1 deletion = 6 install.sh changes + 5 new kit files)
- **install.sh hook count** rises from 6 to 11 installed hooks (5 new backports replace 1 deletion + 6 existing = 11)
- **MANIFEST regeneration** required in T8 because kit ships new hook files
- **test_install.sh** must add assertions for 5 new hooks in install.sh dry-run and HOME-isolated install
- **`[dev-wiki:scope-check]` and `[dev-wiki:post-commit]` trigger patterns in `dev-wiki-hooks.md` become actually backed by installable hooks** — closing a documentation/shipping gap
- The "delete" disposition for `dev-wiki-post-commit.sh` removes Jake's local file ONLY if Jake explicitly approves; alternative is "tolerate" with a comment noting kit's version supersedes it

## Resolved by User (2026-05-25)

1. **Delete confirmed for `dev-wiki-post-commit.sh`** — T4 removes the global file and registers kit's `post-commit.sh` via install.sh.
2. **Polish to kit convention** — all 5 backports get `set -euo pipefail` + `[nana:<name>]` log prefix per `hook-prefix-nana-namespace` decision. Treat backports as new kit hooks held to current standards.
3. **Project-local install mode folded into T4** — secondary 6 unused kit-shipped hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start) gain a per-project install path in install.sh. **USER OVERRIDE:** this expands T4 from M to L, violating spec YAGNI constraint "no L tasks". Documented deviation per dev-wiki-hooks.md escape hatch protocol.
