---
title: "Phase 25: PostCommit Hook Complete"
aliases: [2026-05-22-phase-25-postcommit-hook-complete]
category: journal
tags: [hooks, postcommit, advisory, jq, lifecycle, eval]
parents: [phase-25-postcommit-hook]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 25: PostCommit Hook -- Complete

## What Happened

- Implemented post-commit.sh PostToolUse hook (~55 lines): detects successful `git commit` commands via jq parsing of Bash tool JSON stdin, writes one-line JSON sidecar to `.dev-wiki/.pending-commit`, emits `[dev-wiki:post-commit]` trigger. Skips --amend/--fixup/--squash. All paths exit 0 (advisory only).
- Added stale `.pending-commit` handling to session-start.sh: warns and deletes leftover sidecar files from sessions that ended before Claude processed the trigger.
- Updated install.sh to copy post-commit.sh in dev-wiki hooks module and register PostToolUse Bash matcher in settings.json JSON merge.
- Created 3 eval scenarios: commit detected (sidecar written), non-commit skip (fast-path exit), amend skip (no sidecar).
- Added test assertions to test_templates.sh and test_install.sh for hook existence, settings.json registration, and install copy.

## Decisions Made

- [[postcommit-hook-architecture|PostCommit hook architecture]] -- already created during /dev-plan. Three sub-decisions: PostToolUse on Bash (no native PostCommit event), advisory-only with .pending-commit sidecar (prevents race conditions), one-line JSON format (machine-parseable).

## Artifacts Changed

- `templates/.claude/hooks/post-commit.sh` (new, ~55 lines)
- `templates/.claude/settings.json` (PostToolUse Bash matcher added)
- `templates/.claude/hooks/session-start.sh` (+5 lines stale .pending-commit check)
- `install.sh` (hook copy + PostToolUse Bash JSON merge registration)
- `eval/corpus/hook-post-commit-detected/` (new scenario)
- `eval/corpus/hook-post-commit-non-commit/` (new scenario)
- `eval/corpus/hook-post-commit-amend-skip/` (new scenario)
- `tests/test_templates.sh` (post-commit assertions)
- `tests/test_install.sh` (post-commit install assertions)

## Health Delta

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Tests | 150 | 159 | +9 |
| Eval | 38/38 | 41/41 | +3 scenarios |
| Hooks | 11 | 12 | +post-commit.sh |

## Soft Observations / Phase N+1 Candidates

- PostToolUse JSON stdin uses `tool_input.command` for Bash (not `input.command` like Write/Edit hooks use `input.file_path`). This asymmetry in field paths is worth noting for future hook development.
- install.sh writes hooks in flat format while template settings.json uses nested format -- pre-existing inconsistency, not introduced by this phase.

### Retro Check (Phases 21-25)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 0 | none |

Retro check: no systemic issues in Phases 21-25. 5 phases completed with 0 blocked tasks, 0 reversals, 0 user corrections. scan-secrets BSD grep bug (Phase 22) was the only bug fix, resolved cleanly. Gate compliance clean across all 5 phases.

## Process

Spec: specs/phase-25-postcommit-hook.md (approved). Approach: yes. Plan-review: yes. Tasks: yes. All 4 standard gates checked. Gap 1.6 now CLOSED.

## Related

- [[phase-25-postcommit-hook|Phase 25: PostCommit Hook]]
- [[postcommit-hook-architecture|PostCommit hook architecture]]
- [[roadmap-gap-analysis|Engineering Gap Analysis]] -- Gap 1.6 closed
