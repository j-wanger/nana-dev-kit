---
title: "Phase 25: PostCommit Hook"
aliases: [postcommit-hook-phase]
category: phases
tags: [hooks, postcommit, advisory, jq, lifecycle]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["templates/.claude/hooks/post-commit.sh", "templates/.claude/settings.json", "templates/.claude/hooks/session-start.sh", "install.sh", "eval/corpus/hook-post-commit-*", "tests/test_templates.sh", "tests/test_install.sh"]
entry_criteria: "Phase 24 complete, 150 tests passing, 38/38 eval"
exit_criteria: "post-commit.sh created + registered, session-start stale check, install.sh copies hook, 3 eval scenarios pass, all tests pass"
---

# Phase 25: PostCommit Hook

## Objective

Implement a PostToolUse hook that detects successful `git commit` commands and writes a `.dev-wiki/.pending-commit` sidecar file, enabling the dev-wiki lifecycle to react to commits (mark tasks complete, update state) via the existing `[dev-wiki:post-commit]` trigger protocol.

## Scope

Files and modules affected:
- `templates/.claude/hooks/post-commit.sh` -- new PostToolUse hook
- `templates/.claude/settings.json` -- PostToolUse Bash matcher registration
- `templates/.claude/hooks/session-start.sh` -- stale .pending-commit cleanup
- `install.sh` -- hook copy + PostToolUse registration in JSON merge
- `eval/corpus/hook-post-commit-*/` -- 3 eval scenarios
- `tests/test_templates.sh`, `tests/test_install.sh` -- test assertions

## Exit Criteria

- [ ] post-commit.sh exists, passes bash -n, has jq fail-open guard
- [ ] settings.json has PostToolUse entry matching post-commit
- [ ] session-start.sh warns on stale .pending-commit and deletes it
- [ ] install.sh copies hook and registers PostToolUse matcher
- [ ] 3 eval scenarios pass (commit detected, non-commit skip, amend skip)
- [ ] make test passes, make eval 100%

## Constraints

- All hook paths MUST exit 0 (advisory only). Exit 2 would block tool use. Prevents: accidental tool blocking on commit notification.
- Skip --amend/--fixup/--squash commits. Prevents: false positives on amended commits that don't represent new task completion.
- jq fail-open guard (command -v jq || exit 0). Prevents: hook failure in environments without jq.
- .pending-commit is overwrite (not append). Prevents: unbounded file growth from multiple commits.

## Assumptions

- PostToolUse hooks receive JSON with tool_input.command for Bash tool. If false: adjust parsing to match actual schema.
- git diff-tree provides changed files from a commit hash. If false: use git show --name-only instead.
- The existing dev-wiki-hooks.md rules for [dev-wiki:post-commit] are already in place. If false: document the trigger protocol.

## Notes

- Follows the established PostToolUse pattern from detect-loop.sh (Phase 17).
- Uses jq for JSON parsing, consistent with Phase 24 migration.
- The hook is advisory: it writes data and emits a trigger, but Claude decides what to do via dev-wiki-hooks rules.
