# Scope Exploration Protocol

Explore the phase scope to understand files, dependencies, and blast radius. Called from dev-plan Step 3.

## Inputs

- Phase article `scope` field (file globs)
- `$WIKI/articles/files/*.md` and `$WIKI/articles/modules/*.md` (if they exist)

## Code Article Path (preferred)

Glob `$WIKI/articles/files/*.md` and `$WIKI/articles/modules/*.md`. If articles exist, use them instead of raw file reads:

1. Read module articles matching the phase scope — extract `internal_deps`, `dependents`, `files` for structural overview
2. Read file article frontmatter for scope files — extract `exports`, `imports`, `imported_by` for dependency data
3. **Blast radius (bidirectional, 2-level):** Follow both `imports` (upstream risk: could dependencies break us?) and `imported_by` (downstream risk: will changes break consumers?) chains 2 levels deep. Include files whose `data_reads` overlap with scope files' `data_writes`. Flag high-fanout files (5+ in either direction) for careful task ordering.
4. **Refactor advisory + task priorities:** If any scope file has imports≥5 AND imported_by≥5, emit: *"Coupling nexus: <file> (N upstream, M downstream). Consider splitting before modifying."* Cross-reference module `## Key Patterns` and `## Issues` for task ordering (HIGH issues → early tasks).

## Raw File Fallback

If no code articles exist, Read at most 10 files, 150 lines each. Note code structure, test coverage, naming conventions, dependencies. If greenfield, note "no existing code."

## Budget

Cap total exploration at ~5000 tokens.
