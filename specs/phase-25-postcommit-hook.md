# Spec: Phase 25 — PostCommit Hook

## Objective

Create a PostToolUse hook that detects successful `git commit` commands, writes commit metadata to `.dev-wiki/.pending-commit`, and emits the `[dev-wiki:post-commit]` trigger so Claude auto-updates task state — closing Gap 1.6.

## Context

The dev-wiki-hooks rule already defines Claude-side behavior for `[dev-wiki:post-commit]`: read `.pending-commit`, match against tasks, mark done. But no hook emits this trigger — task marking is entirely manual. After compaction or between sessions, the commit-to-task mapping is lost. The existing hook architecture (11 hooks, PostToolUse on Bash via detect-loop.sh) provides the pattern. This is a Tier 1 integration gap: connecting the git commit event to the dev-wiki lifecycle.

## Scope

### In scope
- `post-commit.sh` — PostToolUse hook detecting `git commit` success, writing `.pending-commit`, emitting trigger tag
- `session-start.sh` update — clear stale `.pending-commit` on session start, warn if unprocessed
- `install.sh` update — copy hook, register PostToolUse Bash matcher in settings.json
- Eval scenarios — hook detection, .pending-commit format, stale cleanup
- Tests — test_templates.sh assertions, test_install.sh for hook registration

### Out of scope
- Direct modification of tasks.md by the hook (Claude handles this via existing rules)
- Direct modification of _CURRENT_STATE.md by the hook (Claude handles this)
- Task scope glob matching in the hook (Claude matches files to task scopes)
- `git merge` / `git rebase` / `git cherry-pick` detection (only `git commit`)
- Changes to dev-wiki-hooks.md rules (already correct)

## Approach

**PostToolUse hook pattern (like detect-loop.sh):** Parse Bash tool JSON stdin for command + exit_code via jq. Fast-path exit 0 if not a `git commit` with exit_code 0. On match: capture commit hash, message, and changed files via `git diff-tree`. Write `.dev-wiki/.pending-commit` as one-line JSON (overwrite, not append). Emit `[dev-wiki:post-commit]` to stdout. Opt-in via `$HOME/.claude/enforce` marker.

**`.pending-commit` format:** One-line JSON: `{"hash":"<sha>","message":"<subject>","files":["path/a","path/b"]}`. Machine-parseable by Claude via jq or direct read. Overwritten on each commit (no append).

**session-start.sh integration:** Check for `.dev-wiki/.pending-commit` at session start. If present, warn: `[post-commit] Unprocessed commit detected. Run task matching.` Delete the file after warning.

**install.sh registration:** Add `post-commit.sh` to dev-wiki hooks module. Register as PostToolUse hook with `Bash` matcher in settings.json merge.

## Constraints (CRITICAL)

- **Hook MUST NOT modify tasks.md or _CURRENT_STATE.md.** It writes .pending-commit and emits the trigger tag. Claude handles state updates via existing rules. Prevents: race condition with concurrent edits, format corruption, false-positive task completion.
- **Overwrite .pending-commit, never append.** Only the most recent commit matters. Prevents: stale entry accumulation, unbounded file growth.
- **Fast-path exit for non-commit commands.** The hook fires on every Bash PostToolUse. Non-commit commands must exit in <5ms (parse command, check substring, exit). Prevents: latency regression on all Bash tool uses.
- **Match `git commit` substring, not exact command.** Commands appear as `git commit -m "..."`, `git commit --amend`, etc. Prevents: missing commits due to flag variations.
- **Skip `--amend`, `--fixup`, and `--squash` commits.** These rewrite/prepare history, not new work. Emitting a trigger could cause double-counting. Prevents: false task matches on non-primary commits.
- **jq for JSON parsing, fail-open guard.** Consistent with Phase 24 convention. Missing jq = exit 0 with warning. Prevents: hook blocking all Bash commands when jq is absent.
- **Opt-in via enforce marker.** Like all enforcement hooks, check `$HOME/.claude/enforce`. Prevents: unexpected behavior in projects that haven't opted in.
- **.pending-commit format is one-line JSON.** `{"hash":"...","message":"...","files":["..."]}`. Prevents: format ambiguity between hook and Claude-side consumer.

## Deliverables

1. `templates/.claude/hooks/post-commit.sh` — PostToolUse hook (~40-60 lines)
2. Modified `templates/.claude/hooks/session-start.sh` — stale .pending-commit check (~5 lines)
3. Modified `install.sh` — hook copy + PostToolUse Bash registration
4. Modified `templates/.claude/settings.json` — PostToolUse Bash matcher entry for post-commit.sh
5. 3-4 eval scenarios in `eval/corpus/hook-post-commit-*`
6. Test assertions in `tests/test_templates.sh` and `tests/test_install.sh`

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/hooks/post-commit.sh`
- [ ] `bash -n templates/.claude/hooks/post-commit.sh`
- [ ] `grep -q 'pending-commit' templates/.claude/hooks/post-commit.sh`
- [ ] `grep -q 'dev-wiki:post-commit' templates/.claude/hooks/post-commit.sh`
- [ ] `grep -q 'post-commit' templates/.claude/hooks/session-start.sh`
- [ ] `grep -q 'post-commit' install.sh`
- [ ] `jq -e '.hooks.PostToolUse[] | select(.hooks[].command | test("post-commit"))' templates/.claude/settings.json`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After writing post-commit.sh: verify it correctly parses a mock `git commit` PostToolUse JSON and writes .pending-commit with valid JSON
- After eval scenarios: run `make eval` to verify hook detection + .pending-commit format
- After install.sh changes: verify `bash install.sh --dry-run` shows post-commit.sh and settings.json registration includes it
- If .pending-commit format doesn't provide enough info for task matching: STOP and discuss with user

## Assumptions

- Claude Code PostToolUse hooks on Bash receive the command string in `tool_input.command` JSON field. If false: check actual stdin schema via eval fixture and adjust field path.
- `git diff-tree --no-commit-id --name-only -r HEAD` returns changed files for the most recent commit. If false: use `git show --name-only --format=` as fallback.
- The `[dev-wiki:post-commit]` trigger tag in stdout is sufficient for Claude to act on the rules in dev-wiki-hooks.md. If false: the rules may need updating (out of scope — escalate).
- detect-loop.sh and post-commit.sh can coexist as PostToolUse Bash hooks without ordering issues. If false: investigate Claude Code's hook execution order guarantees.
