# Active Phase Context

Phase: 15 - Wire the Lifecycle
Status: Active, 0/7 tasks done, 0%
Objective: Merge dev-wiki + knowledge-wiki skills into monorepo, refactor install.sh with modular flags (--all/--core-only/--no-python/--dry-run), add PreCompact hook, enhance session-start with memory_search guidance.

Scope: templates/.claude/skills/dev-*/, templates/.claude/skills/wiki-*/, templates/.claude/skills/knowledge-wiki/, install.sh, templates/.claude/hooks/

Key constraints:
- Import verbatim from ~/.claude/skills/ (canonical source, ahead of repos)
- install.sh idempotent, <10s, module deps validated
- PreCompact hook: pure POSIX shell + git, no Python/MCP
- No SKILL.md content modifications

Exit criteria: 17 skill dirs imported, install flags work, PreCompact outputs state, session-start has memory guidance, make test passes
Abort: 3 failed attempts on any task → ask user

Gates: [x] spec [x] approach [x] plan-review [x] tasks
