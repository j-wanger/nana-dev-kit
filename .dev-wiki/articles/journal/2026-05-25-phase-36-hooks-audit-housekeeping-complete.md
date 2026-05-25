---
title: "Phase 36: Hooks Audit & Housekeeping Complete"
aliases: []
category: journal
tags: [hooks, audit, housekeeping, install, backport, reconciliation, nanaclaw, ts-init, readme]
parents: [phase-36-hooks-audit-housekeeping]
created: 2026-05-25
updated: 2026-05-25
source: debrief
---

# Phase 36: Hooks Audit & Housekeeping Complete

## What Happened
- Diagnosed Claude Code `/doctor` hook errors -- root cause was install.sh using legacy flat schema (`{matcher, command}`) instead of nested `{matcher, hooks:[{type, command}]}` format
- Per-hook reconciliation for 6 global-only hooks: 5 backport (context-size-check, dev-wiki-scope-check, post-compact, session-stop, stale-queue) + 1 delete (dev-wiki-post-commit, superseded by kit's post-commit.sh)
- Static lint sweep expanded kit hooks from 12 to 17, all passing `bash -n` + `set -euo pipefail` + jq guard
- install.sh major rewrite: flat-to-nested schema migration, 11 globally-installed hooks, `--project-local` flag for 6 per-project hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start)
- README ts-init coverage (117 lines), stale 201->240 test count sweep
- Nanaclaw upstream PR submitted: https://github.com/j-wanger/nanaclaw/pull/1
- TS polish spot-check: no issues found
- MANIFEST regenerated (142 lines, 25 skill dirs), full test/eval pass (240 tests, 47/47 eval)

## Decisions Made
- [[hook-reconciliation|Hook Reconciliation: 5 backport, 1 delete]] -- upgraded to high confidence (user approved all 3 questions)
- [[hook-reconciliation-approach|Hook Reconciliation Approach]] -- medium confidence (from planning, no change)
- [[hook-error-evidence|Hook Error Evidence]] -- high confidence (diagnostic captured)
- [[nanaclaw-upstream-pr|Nanaclaw Upstream PR]] -- high confidence (PR submitted)

## Problems Solved
- `/doctor` hook validation errors -- install.sh was writing flat schema `{matcher: "...", command: "..."}` instead of Claude Code's expected nested format `{matcher: "...", hooks: [{type: "command", command: "..."}]}`
- 6 global-only hooks with no kit representation -- 5 backported with convention polish, 1 deleted as superseded
- dev-wiki-post-commit.sh (global) was a weaker duplicate of kit's post-commit.sh -- install.sh now deletes the global file during upgrade

## Artifacts Changed
- `install.sh` (~330 -> ~508 lines: nested schema, 11 global hooks, --project-local flag, flat->nested migration)
- `templates/.claude/hooks/` (12 -> 17 scripts: +context-size-check, dev-wiki-scope-check, post-compact, session-stop, stale-queue)
- `README.md` (110 -> 117 lines: ts-init coverage, --no-typescript, --project-local)
- `tests/test_install.sh` (+16 assertions: nested schema, migration, project-local, backported hooks)
- `templates/.claude/skills/MANIFEST` (142 lines, 25 dirs)
- `.dev-wiki/articles/decisions/` (+4 articles: hook-error-evidence, hook-reconciliation, hook-reconciliation-approach, nanaclaw-upstream-pr)

## Escape Hatches Used
- **USER OVERRIDE**: Task 4 expanded from M to L scope -- user chose to fold project-local install mode into T4 this phase, documented per escape hatch protocol

## Soft Observations / Phase N+1 Candidates
- context-size-check.sh uses `python3` for JSON parsing -- inconsistent with jq-guard convention. Low priority, correct fail-open behavior.
- 6 kit-shipped hooks still not globally installed (available via `--project-local` only). Future phase could add `--hooks-only` flag or document per-project setup in README.
- `patches/nanaclaw-sanitize-fts.patch` uses stale `/tmp/` absolute paths, not `git format-patch` output. Future patches should use `git format-patch` for direct `git am` compatibility.

### Activation Quality
Active-knowledge had 4 entries (1 section). All 4 were used during implementation:
- mktemp -d tmpdir testing: used consistently through T3-T4
- 6 global-only hooks list: used in T1 inventory + T2 reconciliation + T4 backport
- Evidence-pinned fixes: used in T3 lint + T4 fix commit messages
- README test-count LAST: T5 ran after T4 (correct ordering)
Hit rate: 4/4 (100%)

## Related
- [[phase-36-hooks-audit-housekeeping|Phase 36: Hooks Audit & Housekeeping]]
