# Active Phase Context

Phase: 10 - Memory Lifecycle Convergence
Status: Active, 0/2 tasks done, ~0%
Objective: Remove stale MEMORY.md from session-start, make memory access MCP-only.

Scope: templates/.claude/hooks/session-start.sh, templates/.claude/rules/nana-soul.md, templates/.claude/rules/file-lifecycle.md, templates/.github/instructions/nana.instructions.md

Constraints:
- No new stores — removes a read path only
- Legacy-safe: existing .memory/MEMORY.md becomes inert, not deleted
- Budget: ~228/300 after soul +1 line
- Formal spec: specs/phase-10-memory-lifecycle-convergence.md (Opus 8/10)

Exit criteria: MEMORY.md removed from session-start, soul has memory_search guidance, lifecycle updated, synced, tests pass.
