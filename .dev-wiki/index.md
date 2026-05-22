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
- [[phase-11-process-hardening|Phase 11: Process Hardening]] -- completed
- [[phase-12-soul-enhancement-memory-harvest|Phase 12: Soul Enhancement & Memory Harvest]] -- completed
- [[phase-13-final-polish-and-ship|Phase 13: Final Polish & Ship]] -- completed
- [[phase-14-adversarial-thinking-and-review|Phase 14: Adversarial Thinking & Review]] -- completed
- [[phase-15-wire-the-lifecycle|Phase 15: Wire the Lifecycle]] -- completed
- [[phase-16-enforce-the-loop|Phase 16: Enforce the Loop]] -- completed
- [[phase-17-harden|Phase 17: Harden]] -- active

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
- [[pure-bash-loop-detection|Pure bash for detect-loop.sh]] -- high confidence, accepted
- [[sqlite3-memory-nudge|sqlite3 for memory nudge (not MCP)]] -- medium confidence, accepted
- [[staged-pruning-stale-queue|Staged pruning to .stale-queue]] -- high confidence, accepted
- [[global-hooks-project-opt-in|Global hooks with project-level opt-in]] -- high confidence, accepted
- [[lightweight-deliverable-check-stop|Lightweight deliverable check at Stop]] -- high confidence, accepted
- [[python-json-parsing-hooks|Python JSON parsing in hooks]] -- high confidence, accepted
- [[monorepo-skill-distribution|Monorepo Skill Distribution]] -- high confidence, accepted
- [[import-source-canonical-installed|Import Source -- Canonical Installed Versions]] -- high confidence, accepted
- [[t0-wording-over-structural-subagent|T0 wording over structural subagent]] -- high confidence
- [[adversarial-constraint-generation-as-spec-step|Adversarial constraint generation as spec Step 2.5]] -- high confidence
- [[personal-profile-template-for-shipping|Personal profile template for shipping]] -- high confidence
- [[skill-ceiling-250-to-350|SKILL.md ceiling 250 to 350]] -- high confidence
- [[soul-warmth-via-compression|Soul warmth via compression]] -- high confidence
- [[memory-harvest-in-debrief|Memory harvest in debrief]] -- high confidence
- [[spec-and-thinking-enforcement-in-devplan|Spec and thinking enforcement in dev-plan]] -- high confidence
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
- [[2026-05-22-phase-16-enforce-the-loop-complete|Phase 16 complete]] -- 2026-05-22
- [[2026-05-22-phase-15-wire-the-lifecycle-complete|Phase 15 complete]] -- 2026-05-22
- [[2026-05-21-phase-14-adversarial-thinking-and-review-complete|Phase 14 complete]] -- 2026-05-21
- [[2026-05-20-phase-13-final-polish-and-ship-complete|Phase 13 complete]] -- 2026-05-20
- [[2026-05-20-phase-12-soul-enhancement-memory-harvest-complete|Phase 12 complete]] -- 2026-05-20
- [[2026-05-19-phase-11-process-hardening-complete|Phase 11 complete]] -- 2026-05-19
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
- [[2026-05-22-codebase-snapshot|Codebase Snapshot]] -- 2026-05-22
- [[2026-05-21-codebase-snapshot|Codebase Snapshot]] -- 2026-05-21
- [[2026-05-20-codebase-snapshot|Codebase Snapshot]] -- 2026-05-20
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

- 2026-05-22: Phase 17 planned -- 4 tasks, 3 decisions, harden (loop detection + memory nudge + working-knowledge pruning)
- 2026-05-22: Phase 16 completed -- enforcement hooks (spec gate + deliverable check), global hooks + opt-in, tests 92 -> 107
- 2026-05-22: Phase 16 planned -- 6 tasks, 3 decisions, enforce the loop (spec gate + deliverable check + global hooks)
- 2026-05-22: Phase 15 completed -- monorepo skills (17 dirs), modular install flags, PreCompact hook, tests 67 -> 92, retro clean
- 2026-05-21: Phase 15 planned -- 7 tasks, 2 decisions, wire the lifecycle (monorepo + modular install)
- 2026-05-21: Phase 14 completed -- T0 output-format forcing, adversarial spec Step 2.5, tests 65 -> 67, soul/budget unchanged
- 2026-05-21: Phase 14 planned -- 3 tasks, 2 decisions, adversarial thinking (T0 wording + spec Step 2.5)
- 2026-05-20: Phase 13 completed -- H8+H9 heuristics, personal template, ceiling 350, v0.3.0 shipped, tests 63 -> 65, budget 245/300
- 2026-05-20: Phase 13 planned -- 5 tasks, 2 decisions, final polish + v0.3.0 ship
- 2026-05-20: Phase 12 completed -- soul warmth + memory-harvest + spec/thinking enforcement, tests 61 -> 63, budget 239/300
