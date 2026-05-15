# Active Phase Context

Phase: 4 - Dev-Wiki & Memory Integration
Status: Active, 0/5 tasks done, ~0%
Objective: Vendor memory_server, register MCP in install.sh, enhance session-start, update docs.

Scope globs: memory_server/, install.sh, tests/test_install.sh, templates/.claude/hooks/session-start.sh, templates/.claude/skills/py-init/SKILL.md, README.md

Key constraints:
- Frozen-snapshot pattern: session-start reads MEMORY.md once at boot, never edits mid-session
- Graceful degradation: all file reads silently skip when missing (no hard failures)
- DEPENDENCY escape hatch: install.sh evolves beyond 3-file copy (supersedes install-sh-stays-minimal)
- Idempotent JSON merge: python3 json module, handles missing/partial/complete settings.json

Exit criteria: memory vendored + install registers MCP + session-start enhanced + SKILL.md updated + README updated

Abort: if blocked >3 attempts on any task, ask user: skip or abort phase
