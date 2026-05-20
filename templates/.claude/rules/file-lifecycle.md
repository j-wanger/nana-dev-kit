<!-- Global reference — applies to all scaffolded projects. -->
# File Lifecycle

## Who updates what

### User updates (manual)
- `AGENTS.md` — when project conventions, toolchain, or structure change.
  Pre-commit hook auto-syncs to CLAUDE.md/Copilot/Cursor/Gemini.
- `.claude/rules/nana-personal.md` — when personal preferences change.

### Agent updates (via convention)
- `py-session-state.md` — update when focus shifts, decisions are made,
  before batch work, every 15-20 exchanges. Read on session resume.
- `memory_store` (MCP tool) — call when: user corrects you, a decision is
  made worth preserving cross-session, a preference is learned.
  Do NOT write to .memory/MEMORY.md directly.

### Skills update (via invocation)
- `.dev-wiki/*` — managed by /dev-plan, /dev-debrief. Don't hand-edit.
- `specs/<slug>.md` — created by /spec. Persist after approval.

### Hooks update (automatic)
- `CLAUDE.md` etc — sync-rules.sh on AGENTS.md commit (pre-commit hook)
- `.nana/audit.jsonl` — audit-log.sh on every file write (PostToolUse hook)

## Decision routing

Made a decision? Route it:
- Project convention (how we work) → AGENTS.md (user edits, syncs automatically)
- Session context (what we're doing now) → py-session-state.md (agent updates)
- Persistent fact (survives across sessions) → memory_store MCP tool
- Project decision with rationale → /spec or dev-wiki decision article
