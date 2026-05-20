# Spec: Phase 9 — File Lifecycle Reference

## Objective

Create a file lifecycle routing table that tells agents and users "I have information — where does it go?" and remove the orphaned PROJECT_STATE.md reference.

## Context

The kit manages 8+ files with lifecycles (AGENTS.md, session-state, memory, dev-wiki state, specs, audit log), but the routing rules are scattered across hooks, skill comments, and conventions with no single reference. An agent working in a scaffolded project doesn't know whether a decision should go to AGENTS.md, memory_store, py-session-state.md, or a dev-wiki decision article. The answer depends on information type and project setup, but that routing logic exists only in conversation history, not in the kit.

Additionally, `PROJECT_STATE.md` is read by session-start.sh but nothing creates or manages it — it's an orphan that should be removed.

### Current state (for post-compaction self-containment)

The session-start hook (`templates/.claude/hooks/session-start.sh`) reads 4 optional sources: `.dev-wiki/_CURRENT_STATE.md`, `.memory/MEMORY.md`, `PROJECT_STATE.md`, `.claude/rules/py-session-state.md`. The third source (PROJECT_STATE.md) has no creator, no updater, no documentation beyond the hook read.

The instruction budget is currently 195/300 lines across always-loaded files (nana-soul.md 51 + nana-personal.md 4 + nana.instructions.md 55 + AGENTS.md 87 = 197). Adding a ~30-line file-lifecycle.md brings it to ~227/300.

install.sh currently copies: py-init skill, spec skill, nana-soul.md, nana-personal.md, kit path marker, memory_server. A new rules file adds one more copy operation.

## Scope

### In scope
- `templates/.claude/rules/file-lifecycle.md` — new routing table (~30 lines)
- `templates/.claude/hooks/session-start.sh` — remove PROJECT_STATE.md read (orphan cleanup)
- `templates/.claude/skills/spec/SKILL.md` — remove PROJECT_STATE.md reference from context gathering
- `install.sh` — copy file-lifecycle.md to `~/.claude/rules/`
- `tests/test_install.sh` — assert file-lifecycle.md copied
- `tests/test_templates.sh` — assert file-lifecycle.md has routing sections + update budget test to include it

### Out of scope
- Creating a PROJECT_STATE.md replacement (deferred to a future `.project/` universal layer)
- Changing the memory MCP server or .memory/MEMORY.md lifecycle
- Changes to nana-soul.md, AGENTS.md, or other existing rules files
- Automation enforcement of the routing table (it's a reference document, not a hook)

## Approach

1. Create `file-lifecycle.md` using the user's draft as the base: "Who updates what" (4 categories: user manual, agent convention, skills, hooks) + "Decision routing" (4-line routing table: convention → AGENTS.md, session → session-state, persistent → memory_store, rationale → /spec or dev-wiki).

2. Remove PROJECT_STATE.md orphan from session-start.sh (lines 25-31) and from /spec SKILL.md context gathering.

3. Update install.sh to copy file-lifecycle.md. Update tests: install assertion + template content assertion + budget test includes file-lifecycle.md.

## Constraints (CRITICAL)

- **Budget**: file-lifecycle.md ≤ 35 lines. Total always-loaded budget must stay ≤ 300 (currently 197 + 35 = 232 max). Budget test in test_templates.sh must be updated to include file-lifecycle.md in the wc sum.
- **No behavioral enforcement**: file-lifecycle.md is a routing reference, not a hook or runtime check. It guides agent behavior through the soul's convention-following, not through automation.
- **Orphan removal is clean**: removing PROJECT_STATE.md read from session-start.sh must not break the hook. The `if [ -f "$STATE_FILE" ]` guard means it already no-ops when the file is absent, but removal is cleaner than leaving dead code.
- **Don't break existing tests**: session-start.sh has an existing test in test_install.sh that runs it in a temp directory. Removing the PROJECT_STATE.md block must not cause that test to fail.

## Deliverables

1. `templates/.claude/rules/file-lifecycle.md` (new, ≤35 lines)
2. `templates/.claude/hooks/session-start.sh` (updated: PROJECT_STATE.md block removed)
3. `templates/.claude/skills/spec/SKILL.md` (updated: PROJECT_STATE.md reference removed)
4. `install.sh` (updated: copies file-lifecycle.md)
5. `tests/test_install.sh` (updated: file-lifecycle.md copy assertion)
6. `tests/test_templates.sh` (updated: file-lifecycle.md content + budget test includes it)

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/rules/file-lifecycle.md && [ $(wc -l < templates/.claude/rules/file-lifecycle.md) -le 35 ]`
- [ ] `grep -qi 'decision routing\|who updates' templates/.claude/rules/file-lifecycle.md`
- [ ] `grep -qi 'AGENTS.md' templates/.claude/rules/file-lifecycle.md && grep -qi 'memory_store' templates/.claude/rules/file-lifecycle.md && grep -qi 'session.state\|py-session' templates/.claude/rules/file-lifecycle.md`
- [ ] `! grep -q 'PROJECT_STATE' templates/.claude/hooks/session-start.sh`
- [ ] `! grep -q 'PROJECT_STATE' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -q 'file-lifecycle' install.sh`
- [ ] `bash tests/test_install.sh && bash tests/test_templates.sh`
- [ ] `grep -qi 'file-lifecycle' tests/test_templates.sh`

## Checkpoints

- After file-lifecycle.md written: verify routing table covers all 4 categories (user, agent, skill, hook) and the decision routing section has clear one-line-per-type guidance.
- After session-start.sh edited: run `bash -n templates/.claude/hooks/session-start.sh` to verify no syntax errors from the removal.
- After install.sh + tests: run full test suite immediately. If fail: STOP before any commit.

## Assumptions

- `templates/.claude/hooks/session-start.sh` exists at the expected path with the PROJECT_STATE.md block at lines 25-31. If line numbers differ: find the block by grep and remove it. If absent: skip.
- `templates/.claude/skills/spec/SKILL.md` references PROJECT_STATE.md in the context gathering step. If absent: skip.
- The budget regression test in test_templates.sh sums files via a for-loop with explicit paths. Adding file-lifecycle.md to the loop is a one-line change. If the test structure differs: adapt.
- install.sh follows the existing pattern of `cp "$SRC" ~/.claude/rules/<name>.md` for rules files.
