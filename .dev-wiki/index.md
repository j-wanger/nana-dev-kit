# Dev Wiki Index

## By Category

### Phases
- [[phase-01-foundation-and-packaging|Phase 1: Foundation & Packaging]] -- completed
- [[phase-02-automated-testing|Phase 2: Automated Testing]] -- completed
- [[phase-03-distribution-and-polish|Phase 3: Distribution & Polish]] -- completed
- [[phase-04-dev-wiki-and-memory-integration|Phase 4: Dev-Wiki & Memory Integration]] -- active

### Modules
- [[scripts|scripts/]] -- Multi-agent sync utility
- [[templates-claude-hooks|templates/.claude/hooks/]] -- Claude Code lifecycle hook templates
- [[templates-claude-skills|templates/.claude/skills/]] -- Slash command skill definitions
- [[templates-github|templates/.github/]] -- GitHub platform config templates

### Files
- [[install|install.sh]] -- Global installer
- [[scripts-sync-rules|scripts/sync-rules.sh]] -- AGENTS.md sync script
- [[templates-claude-hooks-audit-log|audit-log.sh]] -- PostToolUse audit trail
- [[templates-claude-hooks-auto-ruff-format|auto-ruff-format.sh]] -- PostToolUse auto-format
- [[templates-claude-hooks-block-dangerous-bash|block-dangerous-bash.sh]] -- PreToolUse safety gate
- [[templates-claude-hooks-check-tests-were-run|check-tests-were-run.sh]] -- Stop hook test gate
- [[templates-claude-hooks-scan-secrets|scan-secrets.sh]] -- PostToolUse secret scanner
- [[templates-claude-hooks-session-start|session-start.sh]] -- SessionStart state loader

### Decisions
- [[vendor-memory-server|Vendor memory server]] -- medium confidence
- [[install-sh-scope-expansion|install.sh scope expansion]] -- medium confidence
- [[v0-versioning-strategy|v0 versioning strategy]] -- medium confidence
- [[kit-ci-separate-from-template|Kit CI separate from template]] -- medium confidence
- [[install-sh-stays-minimal|install.sh stays minimal]] -- high confidence
- [[readme-concise-format|README concise format]] -- high confidence
- [[commit-dev-wiki-in-initial-commit|Commit .dev-wiki/ in initial commit]] -- high confidence
- [[pure-bash-test-harness|Pure bash test harness]] -- high confidence
- [[structural-placeholder-verification|Structural placeholder verification]] -- high confidence

### Journal
- [[2026-05-15-phase-3-distribution-and-polish-complete|Phase 3 complete]] -- 2026-05-15
- [[2026-05-15-phase-2-automated-testing-complete|Phase 2 complete]] -- 2026-05-15
- [[2026-05-15-phase-1-foundation-and-packaging-complete|Phase 1 complete]] -- 2026-05-15

### Status
- [[2026-05-15-codebase-snapshot|Codebase Snapshot]] -- 2026-05-15

## By Hierarchy

- Living Documents
  - [[_CURRENT_STATE|Current State]]
  - [[_ARCHITECTURE|Architecture]]
  - [[tasks|Tasks]]
- Configuration
  - [[schema|Schema]]
  - [[config|Config]]

## Recent

- 2026-05-15: Phase 4 planned -- 5 tasks, 2 decisions (vendor-memory-server, install-sh-scope-expansion)
- 2026-05-15: Phase 3 completed -- 6 tasks done, v0.1.0 tagged, 34 tests
- 2026-05-15: Phase 3 planned -- 6 tasks, 2 decisions
- 2026-05-15: Phase 2 completed -- 30 tests, all pass, make test target working
- 2026-05-15: Phase 2 planned -- 5 tasks, 2 decisions
- 2026-05-15: Phase 1 completed -- all 5 tasks done, initial commit created
- 2026-05-15: Phase 1 planned -- 5 tasks, 3 decisions
- 2026-05-15: Code scan -- 4 modules, 8 file articles, _ARCHITECTURE.md rewritten
- 2026-05-15: Dev wiki bootstrapped with 3 phases
