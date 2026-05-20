# Dev Wiki Index

## By Category

### Phases
- [[phase-01-foundation-and-packaging|Phase 1: Foundation & Packaging]] -- completed
- [[phase-02-automated-testing|Phase 2: Automated Testing]] -- completed
- [[phase-03-distribution-and-polish|Phase 3: Distribution & Polish]] -- completed
- [[phase-04-dev-wiki-and-memory-integration|Phase 4: Dev-Wiki & Memory Integration]] -- completed
- [[phase-05-memory-bootstrap-and-report|Phase 5: Memory Bootstrap & Package Report]] -- completed
- [[phase-06-ship-and-workflow-assessment|Phase 6: Ship & Workflow Assessment]] -- completed
- [[phase-07-soul-and-instructions-enhancement|Phase 7: Soul & Instructions Enhancement]] -- completed
- [[phase-08-spec-skill|Phase 8: Spec Skill]] -- completed
- [[phase-09-file-lifecycle-reference|Phase 9: File Lifecycle Reference]] -- completed
- [[phase-10-memory-lifecycle-convergence|Phase 10: Memory Lifecycle Convergence]] -- completed
- [[phase-11-process-hardening|Phase 11: Process Hardening]] -- active

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
- [[layered-gate-enforcement-automated|Layered gate enforcement (automated)]] -- high confidence
- [[gate-enforcement-checklist-plus-log|Gate enforcement: checklist + log]] -- high confidence
- [[memory-convergence-mcp-only|Memory convergence: MCP-only]] -- high confidence
- [[spec-two-tier-review-gate|Spec two-tier review gate]] -- high confidence
- [[spec-persistence-adaptive|Spec persistence adaptive routing]] -- high confidence
- [[soul-vs-agents-delineation|Soul vs AGENTS.md delineation]] -- high confidence
- [[vendor-memory-server|Vendor memory server]] -- medium confidence
- [[install-sh-scope-expansion|install.sh scope expansion]] -- medium confidence
- [[v0-versioning-strategy|v0 versioning strategy]] -- medium confidence
- [[kit-ci-separate-from-template|Kit CI separate from template]] -- medium confidence
- [[venv-isolated-memory-deps|Venv-isolated memory deps]] -- medium confidence
- [[install-sh-stays-minimal|install.sh stays minimal]] -- high confidence (superseded by install-sh-scope-expansion)
- [[readme-concise-format|README concise format]] -- high confidence
- [[commit-dev-wiki-in-initial-commit|Commit .dev-wiki/ in initial commit]] -- high confidence
- [[pure-bash-test-harness|Pure bash test harness]] -- high confidence
- [[structural-placeholder-verification|Structural placeholder verification]] -- high confidence

### Journal
- [[2026-05-19-phase-10-memory-lifecycle-convergence-complete|Phase 10 complete]] -- 2026-05-19
- [[2026-05-19-phase-9-file-lifecycle-reference-complete|Phase 9 complete]] -- 2026-05-19
- [[2026-05-19-phase-8-spec-skill-complete|Phase 8 complete]] -- 2026-05-19
- [[2026-05-19-phase-7-soul-and-instructions-complete|Phase 7 complete]] -- 2026-05-19
- [[2026-05-19-phase-5-and-6-complete|Phase 5 & 6 complete]] -- 2026-05-19
- [[2026-05-15-phase-4-dev-wiki-and-memory-integration-complete|Phase 4 complete]] -- 2026-05-15
- [[2026-05-15-phase-3-distribution-and-polish-complete|Phase 3 complete]] -- 2026-05-15
- [[2026-05-15-phase-2-automated-testing-complete|Phase 2 complete]] -- 2026-05-15
- [[2026-05-15-phase-1-foundation-and-packaging-complete|Phase 1 complete]] -- 2026-05-15

### Status
- [[2026-05-19-codebase-snapshot|Codebase Snapshot]] -- 2026-05-19
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

- 2026-05-19: Phase 11 planned -- 5 tasks, 1 decision, process hardening (layered gate enforcement)
- 2026-05-19: Phase 10 completed -- memory MCP-only, gate enforcement, retro check (Phases 1-10), budget 229/300
- 2026-05-19: Phase 10 planned -- 2 tasks, memory lifecycle convergence
- 2026-05-19: Phase 9 completed -- file lifecycle routing table, orphan removed, 59 tests, budget 227/300
- 2026-05-19: Phase 9 planned -- 3 tasks, file lifecycle reference + orphan cleanup
- 2026-05-19: Phase 8 completed -- spec skill + two-tier review gate, 55 tests, 2 decisions
- 2026-05-19: Phase 8 planned -- 4 tasks, spec skill + two-tier review gate
- 2026-05-19: Phase 7 completed -- soul restructured, personal extracted, 48 tests, budget 191/300
- 2026-05-19: Phase 7 planned -- 5 tasks, soul/instructions enhancement + delineation
- 2026-05-19: Phase 5 & 6 completed -- venv bootstrap, HTML reports, v0.2.0 shipped to GitHub
- 2026-05-19: Phase 6 planned -- 3 tasks, workflow assessment + GitHub ship
