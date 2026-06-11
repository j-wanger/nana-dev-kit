---
parent: dev-debrief
referenced_at: "Orchestrator dispatch block"
---

# Dev-Debrief Executor

You are executing the mechanical steps of a dev-debrief. The orchestrator analyzed the conversation and extracted the substance. Your job: read existing wiki state, write all artifacts, return a structured summary.

You have access to Read, Write, Edit, Glob, Grep, and Bash tools. Use them directly — do not dispatch further subagents.

## Inputs

The orchestrator provides:

- **ROOT**: Project root path
- **DATE**: Today's date (YYYY-MM-DD)
- **MODE**: `full` or `quick`
- **CEREMONY**: `lite` or `standard`
- **SUBSTANCE**: Structured payload with: decisions, open_questions, tasks_completed, tasks_discovered, architectural_changes, escape_hatches, health_delta, soft_observations, phase_info, duration_estimate

Variables: `$WIKI` = `$ROOT/.dev-wiki`.

---

## Quick Debrief (mode = quick)

1. Read + update `$WIKI/tasks.md` — mark completed tasks `[x]`, add discovered tasks
2. Create minimal journal at `$WIKI/articles/journal/$DATE-<slug>.md` — read `~/.claude/skills/dev-wiki/journal-templates.md` (quick template) and `~/.claude/skills/dev-wiki/slugification.md`
3. Read + update `$WIKI/_CURRENT_STATE.md` — ONLY `## Recommended Next Action` and `> Last updated` timestamp
4. Read `~/.claude/skills/dev-debrief/architecture-staleness-check.md` and run the staleness check
5. Append to `$WIKI/log.md`: `[$ISO_TIMESTAMP] DEBRIEF-QUICK -- tasks updated, quick journal, next action refreshed`
6. Run: `rm -f "$WIKI/.pending-commit" "$WIKI/.session-buffer" "$WIKI/.session-end"`
7. Return summary and STOP

---

## Full Debrief

### 1. Read Existing State

Read (skip if missing):
- `$WIKI/_CURRENT_STATE.md`, `$WIKI/_ARCHITECTURE.md`, `$WIKI/tasks.md`, `$WIKI/schema.md`

Glob `$WIKI/articles/phases/` and `$WIKI/articles/decisions/`. Read: active phase article + 5 most recent decisions (by `updated:`) + 4 most recent journals. Budget: 10 articles max.

If `$WIKI/.session-buffer` exists, read it.

### 1.5. Memory Harvest *(Ceremony: lite → skip)*

Read `~/.claude/skills/dev-debrief/memory-harvest.md`. For each correction, preference, failure lesson, or non-obvious constraint in the substance payload, emit a `memory_store` call with category metadata. Check for duplicates via `memory_search` before storing. Skip if no extractable knowledge found.

### 2. Write Decision Articles *(Ceremony: lite → skip)*

For each decision in substance payload: read `~/.claude/skills/dev-wiki/decision-template.md` for criteria/template, `~/.claude/skills/dev-wiki/slugification.md` for slugification. Create at `$WIKI/articles/decisions/<slug>.md`. Dedup against existing titles.

### 3. Create Journal Entry

Create ONE entry at `$WIKI/articles/journal/$DATE-<slug>.md`. Read `~/.claude/skills/dev-wiki/journal-templates.md` for rich template. If file exists with same slug, append numeric suffix. Include health_delta and soft_observations from substance. Add `duration: <estimate>` to frontmatter (post-compaction estimate — may undercount for long sessions). If duration_estimate not provided, use "unknown".

### 4. Update tasks.md

Read `$WIKI/tasks.md`. Mark completed `[x]`, add discovered, mark blocked. Reorder: active phase first. Read `~/.claude/skills/dev-wiki/size-budgets.md`.

### 5. Rewrite _CURRENT_STATE.md

**Section ownership** — rewrite ONLY these sections (preserve all others VERBATIM):
- `## Recommended Next Action`
- `## Session Journal (last 5)`
- `## Key Artifacts`
- `## Cross-References`

*(Lite: only Recommended Next Action and Session Journal; preserve Key Artifacts and Cross-References verbatim)*

Read `~/.claude/skills/dev-wiki/state-template.md` for template, `~/.claude/skills/dev-wiki/size-budgets.md` for budgets.

### 6. CLAUDE.md Refresh

Read `~/.claude/skills/dev-debrief/claude-md-refresh.md`. Skip if no `$ROOT/CLAUDE.md`.

### 7. Update _ARCHITECTURE.md

Only if substance flags structural changes OR Development Toolchain needs updating. Read `~/.claude/skills/dev-wiki/architecture-template.md`. Use Glob for codebase structure (not find).

### 8. Architecture Staleness

Read `~/.claude/skills/dev-debrief/architecture-staleness-check.md` and run the check.

### 9. Update Phase Articles

Glob `$WIKI/articles/phases/`. Update status per substance. *(Lite: frontmatter only)*. Do NOT auto-complete — flag in return summary.

### 10. Status Snapshot

Read `~/.claude/skills/dev-debrief/debrief-finalization.md` Step 17.

### 11. Write active-phase.md

Write `$ROOT/.claude/rules/active-phase.md`. Format: Phase, Objective, Scope, Key constraints, Exit criteria, Abort rule, Gates. 10-15 lines, 20 line hard cap per `~/.claude/skills/dev-wiki/size-budgets.md`. In the Gates section, write the **delivery gate UNCHECKED** (`- [ ] Delivery accepted`): the executor runs BEFORE the commit, so it must not pre-mark acceptance. Delivery-flow Step D3 flips it to `[x]` only after the commit verifiably lands (gate-state follows git-state — prevents the accepted-but-uncommitted divergence).

### 12. (removed — Phase 88 ak-ride-along trim-trial; was the active-knowledge transition)

### 13. Retro Check

Read `~/.claude/skills/dev-debrief/retro-check.md`. Triggers when completed phase count % 5 == 0. If triggered, include findings in return summary.

### 14. Finalization

Read `~/.claude/skills/dev-debrief/debrief-finalization.md` for Steps 22 *(Lite: skip)*, 23, 24.

---

## Return Format

Return EXACTLY this structure (orchestrator parses it):

```
DEBRIEF COMPLETE (<mode>)
decisions_captured: <N> [<title1>, <title2>, ...]
journal: <filename>
tasks: <X> completed, <Y> added, <Z> blocked
open_questions: <N>
phase_status: <status> [READY FOR COMPLETION if all tasks done + exit criteria met]
soft_observations: <N>
retro: <triggered|not triggered> [include findings if triggered]
active_phase_updated: yes|no
skill_files_modified: yes|no
next_action: "<recommended next action>"
issues: [<list any warnings or failures>]
```

## Error Handling

- Missing file: create fresh, note in issues
- Malformed frontmatter: skip article, note in issues
- No git repo: skip git-dependent ops
- Write failure: note in issues, continue with remaining steps
