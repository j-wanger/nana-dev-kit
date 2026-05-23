---
title: "PostCommit hook architecture"
aliases: [postcommit-hook, post-commit-hook, pending-commit-sidecar]
category: decisions
tags: [hooks, postcommit, advisory, jq]
parents: [phase-25-postcommit-hook]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

Claude Code has no native PostCommit event. We need a hook that detects when a `git commit` succeeds so the dev-wiki lifecycle can react (mark tasks complete, update state). Three sub-decisions were needed: (1) what hook type to use, (2) how to communicate commit data to Claude, and (3) what format for that data.

## Decision

**PostToolUse on Bash with git commit detection.** No native PostCommit event exists, so we reuse the PostToolUse hook pattern (established by detect-loop.sh). The hook parses Bash tool JSON stdin via jq, fast-path exits on non-commit commands, and fires only on `git commit` with exit_code 0. Skips --amend/--fixup/--squash to avoid false positives.

**Advisory-only with .pending-commit sidecar.** The hook writes a one-line JSON file to `.dev-wiki/.pending-commit` and emits `[dev-wiki:post-commit]` to stdout. It does NOT modify tasks.md directly. Claude follows existing dev-wiki-hooks rules to act on the trigger. This prevents race conditions, format corruption, and false positives from direct task mutation.

**.pending-commit as one-line JSON.** Format: `{"hash":"...","message":"...","files":["..."]}`. Machine-parseable, consistent with the jq convention established in Phase 24. Alternative (plain text) rejected for ambiguous parsing.

Alternative considered: git-native `.git/hooks/post-commit` -- captures manual commits but cannot emit text to Claude's context window. Rejected because the primary consumer is Claude, not external tooling.

## Consequences

- All hook paths must exit 0 (advisory only). Exit 2 would block tool use, which is wrong for a commit notification.
- session-start.sh must handle stale .pending-commit files (from sessions that ended before Claude processed the trigger).
- The hook adds one file to templates/.claude/hooks/ and one PostToolUse entry to settings.json.
- install.sh must copy the hook and register the PostToolUse matcher.
- Eval corpus needs 3 new scenarios to cover the commit/non-commit/amend paths.
