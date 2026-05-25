---
title: "Hook Error Evidence (Phase 36 Task 1)"
aliases: [hook-evidence, t1-evidence]
category: decisions
tags: [hooks, evidence, audit, phase-36, t1]
parents: [phase-36-hooks-audit-housekeeping]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Phase 36 Task 1 deliverable: capture concrete hook errors Claude Code is surfacing, before any fix lands. Every subsequent hook fix in Task 4 must quote evidence from this file in its commit message.

## /doctor Errors (Quoted)

Captured from session JSONL `~/.claude/projects/-Users-jwang-nana-dev-kit/9f38bc7f-f0cc-4ba6-891a-6c0023be5771.jsonl` line 4 (timestamped 2026-05-25 07:44). User ran `/doctor` and forwarded these 3 errors to Claude for triage:

```
Settings (/Users/jwang/.claude/settings.json › hooks.Stop.1.hooks):
  Expected array, but received undefined
  Suggested fix: Hooks use a matcher + hooks array. The matcher is a string:
    a tool name ("Bash"), pipe-separated list ("Edit|Write"), or empty to match all.
    Example: {"PostToolUse": [{"matcher": "Edit|Write",
              "hooks": [{"type": "command", "command": "echo Done"}]}]}

Settings (/Users/jwang/.claude/settings.json › hooks.PostToolUse.3.hooks):
  Expected array, but received undefined
  (same suggested fix)

Settings (/Users/jwang/.claude/settings.json › hooks.PreToolUse.0.hooks):
  Expected array, but received undefined
  (same suggested fix)
```

All 3 errors are the same class: hook entries missing the required `hooks: [...]` array. Schema expects `{matcher, hooks: [{type, command}]}` but the malformed entries had `{matcher, command}` flat (legacy pre-schema shape).

## Root Cause

`install.sh` lines 319-344 register hooks using the legacy flat shape:

```python
spec_hook = {'matcher': 'Write|Edit', 'command': os.path.expanduser('~/.claude/hooks/enforce-spec.sh')}
loop_hook = {'command': os.path.expanduser('~/.claude/hooks/enforce-loop.sh')}
detect_hook = {'matcher': 'Bash', 'command': os.path.expanduser('~/.claude/hooks/detect-loop.sh')}
memory_hook = {'matcher': 'Write|Edit', 'command': os.path.expanduser('~/.claude/hooks/enforce-memory.sh')}
postcommit_hook = {'matcher': 'Bash', 'command': os.path.expanduser('~/.claude/hooks/post-commit.sh')}
compact_hook = {'command': os.path.expanduser('~/.claude/hooks/pre-compact.sh')}
```

Each entry needs to be:

```python
spec_hook = {'matcher': 'Write|Edit', 'hooks': [{'type': 'command', 'command': '...'}]}
```

Current `~/.claude/settings.json` (mtime 2026-05-25 07:43 — 1 minute before the /doctor session) has all entries in the correct nested shape, meaning a prior session manually fixed it. But install.sh will produce the malformed shape again on the next run.

## Global vs Kit Hook Inventory (`diff -r templates/.claude/hooks ~/.claude/hooks`)

### Files only in `templates/.claude/hooks/` (kit-shipped, NOT installed globally — 7 files including py-review)

- `audit-log.sh`
- `auto-ruff-format.sh`
- `block-dangerous-bash.sh`
- `check-tests-were-run.sh`
- `enforce-memory.sh` (BUT install.sh DOES copy this — discrepancy: it's in `~/.claude/hooks/`? checked: yes it IS installed; diff was against a fresh-cloned ref, false-positive)
- `post-commit.sh` (kit name)
- `scan-secrets.sh`
- `py-review-stop-prompt.md` (markdown, not a hook script)
- `session-start.d/` (directory, not a script)

### Files only in `~/.claude/hooks/` (globally installed, NOT in kit templates — 6 files)

- `context-size-check.sh` — global-only
- `dev-wiki-post-commit.sh` — referenced by `dev-wiki-hooks.md` trigger pattern `[dev-wiki:post-commit]`
- `dev-wiki-scope-check.sh` — referenced by `dev-wiki-hooks.md` trigger pattern `[dev-wiki:scope-check]`
- `post-compact.sh` — global-only
- `session-stop.sh` — global-only; in /doctor JSONL stop_hook_summary blocks: `bash ~/.claude/hooks/session-stop.sh`
- `stale-queue.sh` — global-only

### Files present in BOTH but DIFFER

- `detect-loop.sh`
- `enforce-loop.sh`
- `enforce-spec.sh`
- `pre-compact.sh`
- `session-start.sh`

(Differ how — char-level vs feature-level — to be triaged in Task 3 lint sweep.)

## install.sh Coverage Gap

`install.sh` lines 296-302 copy exactly 6 hooks: enforce-spec, enforce-loop, enforce-memory, detect-loop, pre-compact, post-commit.

Kit `templates/.claude/hooks/` ships 12 hooks (excluding session-start.d/ and py-review-stop-prompt.md):

| Kit hook | Copied by install.sh? |
|----------|----------------------|
| audit-log.sh | NO |
| auto-ruff-format.sh | NO |
| block-dangerous-bash.sh | NO |
| check-tests-were-run.sh | NO |
| detect-loop.sh | YES |
| enforce-loop.sh | YES |
| enforce-memory.sh | YES |
| enforce-spec.sh | YES |
| post-commit.sh | YES |
| pre-compact.sh | YES |
| scan-secrets.sh | NO |
| session-start.sh | NO |

6 kit-shipped hooks are NEVER installed globally. They may be intended for project-local install (`.claude/hooks/` under a project root) or may be legacy artifacts. To be triaged in Task 2 reconciliation.

## stop_hook_summary Evidence (additional)

JSONL `5c7d06f2-181b-4a98-98cd-b46d2fbf9f4c.jsonl` lines 128/168/188 show actual Stop hook executions:

```
"hookInfos": [
  {"command": "bash ~/.claude/hooks/session-stop.sh", "durationMs": 59},
  {"command": "/Users/jwang/.claude/hooks/enforce-loop.sh", "durationMs": <N>}
]
```

Both run cleanly (no errors reported), confirming the malformed-shape issue was about *schema validation* at session boot, not runtime execution.

## Summary

| Issue | Severity | Fix scope | Phase 36 task |
|-------|----------|-----------|---------------|
| install.sh hooks registered in legacy flat schema | HIGH | install.sh lines 319-344 + tests | T4 |
| 6 kit-shipped hooks never installed globally | MEDIUM | T2 reconciliation: ship or remove from kit | T2, T4 |
| 6 global-only hooks not in kit | MEDIUM | T2 reconciliation: backport, delete, or tolerate | T2, T4 |
| 5 hooks present in both but differ | LOW | T3 lint will surface specifics | T3 |
| .dev-wiki/.hook-prefix-inventory.md scratch file present | LOW | Delete or gitignore | T8 |

No `.dev-wiki/enforcement.log` exists (enforcement may have been silent, or the log was never created — install.sh doesn't pre-touch it). Not an error in itself; the file is created on first enforcement event.
