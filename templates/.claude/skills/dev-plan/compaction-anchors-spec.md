---
parent: dev-plan
referenced_at: "Step 17"
---

# Compaction Anchors and Error Handling

Companion to `dev-plan/SKILL.md`. Behavioral reference for compaction anchor design and error handling. Steps 15f-15g in SKILL.md contain the orchestration logic; this companion provides the specification and rationale.

---

## Anchor Types

Three anchors survive context compaction and restore session state:

### 1. Phase Context Anchor — `active-phase.md`

**Location:** `$ROOT/.claude/rules/active-phase.md` (rules layer, auto-loaded every turn)
**Owner:** `/dev-plan` (writes), `/dev-debrief` (updates status)
**Contents:** Phase number, objective, scope (file globs), key constraints, exit criteria, abort rule.
**Budget:** 10-15 lines, ~50 tokens/turn.

The agent reads this after compaction to know what phase it is in and what constraints apply, without re-reading the full phase article.

### 2. (removed — Phase 88 ak-ride-along trim-trial; was the active-knowledge knowledge anchor)

### 3. Task State Anchor — TodoWrite

**Location:** Harness-managed task list (re-injected automatically after compaction)
**Owner:** `/dev-plan` (creates at Step 15g), implementation workflow (updates status)
**Contents:** Each task description embeds scope, constraints, and TDD cycle.
**Budget:** ~8 tasks, ~100 tokens/turn.

## Size Budgets

| Anchor | Target Lines | Hard Cap | Per-Turn Cost |
|--------|-------------|----------|---------------|
| `active-phase.md` | 10-15 | 20 lines | ~50 tokens |
| TodoWrite tasks | N/A | ~8 tasks | ~100 tokens |
| **Combined** | | | **~300 tokens/turn** |

Design principle: every line must carry information the agent cannot derive from code or git history. Phase identity: yes. Full task list: no (use TodoWrite). Architecture overview: no (read the file).

## Recovery Protocol

After context compaction, the agent restores working context in ~5 tool calls:

1. **Read** `active-phase.md` — phase identity, scope, constraints
2. **Read** `_CURRENT_STATE.md` — project state, next action, blockers
3. **Read** `tasks.md` — find next uncompleted task for active phase
5. **Check** TodoWrite — in-progress task state

This sequence fully restores working context. The agent then states: "Resuming task: <description>. Scope: <scope>. TDD: <test spec>."

## Error Handling

| Error | Response |
|-------|----------|
| No `.dev-wiki/` | "Run `/dev init` first." STOP. |
| Open tasks exist | "Phase N has X open tasks. Continue implementation." STOP. |
| User rejects approach | Revise and re-present (max 3 rounds). |
| No phases defined | "Run `/dev init`." STOP. |
| Approach reviewer timeout | Proceed without critique. Warn: "Approach reviewer unavailable." |
| Plan reviewer timeout | Accept draft tasks without review score. Warn: "Plan reviewer unavailable." |
| working-knowledge >100 entries or >210 lines | Tolerated until next session-start; the deterministic curator enforces the cap (see `~/.claude/skills/dev-wiki/working-knowledge-spec.md`). Do not hand-prune. |
