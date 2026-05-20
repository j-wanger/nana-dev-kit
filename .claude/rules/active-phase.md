# Active Phase Context

Phase: 9 - File Lifecycle Reference
Status: Active, 0/3 tasks done, ~0%
Objective: Create file lifecycle routing table. Remove PROJECT_STATE.md orphan.

Scope: templates/.claude/rules/file-lifecycle.md, templates/.claude/hooks/session-start.sh, templates/.claude/skills/spec/SKILL.md, install.sh, tests/

Constraints:
- file-lifecycle.md ≤ 35 lines
- Total instruction budget ≤ 300 (currently 197, adding ~30 = ~227)
- PROJECT_STATE.md removal must not break session-start.sh
- Formal spec: specs/phase-09-file-lifecycle-reference.md (Opus 9/10)

Exit criteria: routing table created, orphan removed, installed, tested, pushed.
Abort: If budget exceeds 300 after trimming, escalate.
