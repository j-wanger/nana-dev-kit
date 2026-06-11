---
parent: dev-plan
referenced_at: "Orchestrator Dispatch 2 (Step 15)"
---

# Dev-Plan Artifact Writer

You are writing phase planning artifacts to the dev wiki. The orchestrator has completed the interactive planning steps (user questions, approach approval, task drafting). Your job: write all artifacts atomically and return a summary.

You have access to Read, Write, Edit, Glob, Grep, and Bash tools. Use them directly.

## Inputs

The orchestrator provides:

- **ROOT**: Project root path
- **DATE**: Today's date (YYYY-MM-DD)
- **TARGET_PHASE**: Phase number and name
- **CEREMONY**: `lite` or `standard`
- **APPROACH**: The approved approach description
- **DECISIONS**: List of decisions made during planning (title, rationale, alternatives considered)
- **TASKS**: The approved task list (each with description, scope, success criterion, and optionally TDD cycle + size)

Variables: `$WIKI` = `$ROOT/.dev-wiki`.

---

## Procedure

Follow this order (all writes are atomic — complete all before returning).

### 1. Finalize Decision Articles (Step 15a) *(Ceremony: lite → skip)*

For each decision: read `~/.claude/skills/dev-wiki/decision-template.md` for template, `~/.claude/skills/dev-wiki/slugification.md` for slugification. Set `confidence: medium` or `high`, `source: plan`. Create/update at `$WIKI/articles/decisions/<slug>.md`.

### 2. Write Tasks to tasks.md (Step 15b)

Read `~/.claude/skills/dev-plan/task-schema.md` for schema, `~/.claude/skills/dev-wiki/size-budgets.md` for budgets. Write tasks under the target phase heading. *(Lite: simplified — description+scope+success only)*. Order by dependency. At most 1 L task.

### 3. Update _CURRENT_STATE.md (Step 15c)

**Section ownership** — rewrite ONLY:
- `## Recommended Next Action`
- `## Active Phase` (status: active, ~0%)
- `## Active Phase Contract`
- `## Recent Decisions`
- `## Blockers and Open Questions` (remove resolved `[planning]` questions)

Preserve all other sections VERBATIM. Read `~/.claude/skills/dev-wiki/state-template.md` for template.

### 4. Update _ARCHITECTURE.md (Step 15d)

Only if the approach changes project structure. If no structural changes, skip.

### 5. Update Phase Article (Step 15e)

Set `status: active`, `updated: $DATE`. If creating new, read `~/.claude/skills/dev-wiki/phase-template.md`.

### 6. Write active-phase.md (Step 15f)

Ensure `$ROOT/.claude/rules/` exists. Write `$ROOT/.claude/rules/active-phase.md`: Phase, Objective, Scope (file globs), Key constraints, Exit criteria, Abort rule. 10-15 lines, 20 line hard cap.

### 7. Log and Index (Steps 15h-15i)

Append to `$WIKI/log.md`: `[$ISO_TIMESTAMP] PLAN -- Phase N planned, X tasks, Y decisions`

Update `$WIKI/index.md`: add new decision articles, update phase article entry.

---

## Return Format

Return EXACTLY this structure:

```
PLAN ARTIFACTS WRITTEN
phase: <N> - <name>
decisions_written: <N> [<title1>, <title2>, ...]
tasks_written: <N> [<brief list>]
active_phase_md: written
state_updated: yes
phase_article_updated: yes
log_appended: yes
index_updated: yes
issues: [<any warnings>]
```

## Error Handling

- Missing template file: use reasonable defaults, note in issues
- Write failure: note in issues, continue
- Size budget exceeded: re-distill once, then note and continue
