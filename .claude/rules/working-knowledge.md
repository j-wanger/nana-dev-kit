# Working Knowledge
<!-- Cross-phase knowledge. Auto-managed by dev-debrief and wiki-query. -->

- [uses: 1] install.sh performs 6 actions: copies py-init + spec skills, nana-soul + nana-personal + file-lifecycle rules, kit path marker, memory_server/ + registers MCP server in settings.json
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-19
- [uses: 1] README targets ~58 lines with install + usage + 5-layer table + memory/dev-wiki section; self-test.md is the detailed reference
  source: [[wiki:readme-concise-format]] | activated: 2026-05-15
- [uses: 1] .dev-wiki/ is committed as project lifecycle artifact; .claude/settings.local.json is excluded via .gitignore
  source: [[wiki:commit-dev-wiki-in-initial-commit]] | activated: 2026-05-15
- [uses: 1] install.sh is idempotent: copies 6 items + memory_server + JSON merge; running twice produces identical results
  source: [[file:install]] | activated: 2026-05-19
- [uses: 1] sync-rules.sh writes 4 outputs (CLAUDE.md, GEMINI.md, copilot-instructions.md, .cursor/rules/main.mdc) with AUTO-GENERATED headers; missing AGENTS.md exits non-zero
  source: [[file:scripts-sync-rules]] | activated: 2026-05-15
- [uses: 1] Templates use {{PACKAGE_NAME}}, {{PROJECT_DESCRIPTION}}, {{PROJECT_NAME}} placeholders; tests verify presence via grep, not substitution
  source: [[decision:structural-placeholder-verification]] | activated: 2026-05-15
- [uses: 1] install.sh has upfront source validation; asymmetric error handling (2>/dev/null || true) removed in Phase 3
  source: [[journal:2026-05-15-phase-3-distribution-and-polish-complete]] | activated: 2026-05-15
- [uses: 1] sync-rules.sh has writability pre-check; exits non-zero with clear error if target dir is unwritable
  source: [[journal:2026-05-15-phase-3-distribution-and-polish-complete]] | activated: 2026-05-15
- [uses: 1] VERSION file at repo root is single source of truth for semantic versioning; install.sh has no version-awareness at v0.x
  source: [[decision:v0-versioning-strategy]] | activated: 2026-05-15
- [uses: 1] Kit CI at .github/workflows/kit-ci.yml is distinct from templates/.github/workflows/ci.yml; shellcheck is CI-only
  source: [[decision:kit-ci-separate-from-template]] | activated: 2026-05-15
- [uses: 1] memory_server/ vendored from nanaclaw (12 .py, 2,373 LOC); runs via MCP stdio (python -m memory_server)
  source: [[decision:vendor-memory-server]] | activated: 2026-05-15
- [uses: 1] session-start.sh reads 2 sources: py-session-state.md, dev-wiki/_CURRENT_STATE.md; memory access is MCP-only (memory_search); MEMORY.md removed in Phase 10
  source: [[decision:memory-convergence-mcp-only]] | activated: 2026-05-19
- [uses: 1] MCP registration uses idempotent python3 JSON merge; handles 3 cases: no settings.json, existing without mcpServers, existing with mcpServers
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-15
- [uses: 1] memory_server pip deps auto-installed by install.sh in venv at ~/.claude/memory_server/.venv/ (updated Phase 5)
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] scripts/generate-workflow.py (738 lines) generates docs/workflow.html; distinct from generate-report.py (package inventory)
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] Venv bootstrap at ~/.claude/memory_server/.venv/ with graceful fallback; MCP config uses venv Python after deps installed
  source: [[decision:venv-isolated-memory-deps]] | activated: 2026-05-19
- [uses: 1] VERSION bumped to 0.2.0; Makefile has 4 targets: sync-rules, test, report, workflow
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] GitHub remote: origin -> https://github.com/j-wanger/nana-dev-kit.git; v0.2.0 tagged and pushed
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] Soul vs AGENTS.md delineation: soul = cognitive identity (universal, all projects/languages), AGENTS.md = operational contract (project-specific). Litmus: "would this apply in a Rust project?" Yes → soul, No → AGENTS.md
  source: [[decision:soul-vs-agents-delineation]] | activated: 2026-05-19
- [uses: 1] nana-soul.md Thinking protocol has trigger clause (trade-offs/design/advisory), cost-of-error proportionality, 3 moves (read subtext, challenge frame, delay commitment); 51 lines total
  source: [[journal:2026-05-19-phase-7-soul-and-instructions-complete]] | activated: 2026-05-19
- [uses: 1] Instruction budget: soul (52) + personal + lifecycle + AGENTS.md + nana.instructions.md = 229/300 lines; regression test in test_templates.sh enforces ceiling
  source: [[journal:2026-05-19-phase-10-memory-lifecycle-convergence-complete]] | activated: 2026-05-19
- [uses: 1] install.sh copies 6 items: py-init SKILL.md, spec/ skill, nana-soul.md, nana-personal.md, file-lifecycle.md, kit path marker + memory_server/ + MCP registration
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 1] /spec skill has two-tier review gate: Tier 0 structural lint (inline, deterministic) + Tier 1 semantic subagent (6 dimensions); adaptive persistence (dev-wiki -> /dev-plan, standalone -> specs/)
  source: [[decision:spec-two-tier-review-gate]] | activated: 2026-05-19
- [uses: 1] specs/ directory at project root for standalone spec persistence; phase-08-spec-skill.md is the exemplar (Opus-reviewed 8/10)
  source: [[decision:spec-persistence-adaptive]] | activated: 2026-05-19
- [uses: 1] Phase template has 3 optional sections (Constraints, Checkpoints, Assumptions) backported from /spec; dev-plan Step 6 has spec-field coverage note
  source: [[journal:2026-05-19-phase-8-spec-skill-complete]] | activated: 2026-05-19
- [uses: 1] templates/.claude/rules/file-lifecycle.md (32 lines) is a routing table with 4 categories (user, agent, skill, hook) + decision routing section
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 1] specs/phase-09-file-lifecycle-reference.md is the second formal spec (Opus 9/10); first was phase-08-spec-skill.md (8/10)
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 3] Gate enforcement uses two layers: active-phase.md Gates section (5 checkpoints, preventive) + tasks.md gate log HTML comments (detective, auditable)
  source: [[decision:gate-enforcement-checklist-plus-log]] | activated: 2026-05-19
- [uses: 1] Memory access is MCP-only: memory_store to write, memory_search to read; .memory/MEMORY.md files are inert legacy (not deleted, just not read)
  source: [[decision:memory-convergence-mcp-only]] | activated: 2026-05-19
- [uses: 1] nana-soul.md now 52 lines (+1 from Phase 9: memory_search at session start in Memory discipline section)
  source: [[journal:2026-05-19-phase-10-memory-lifecycle-convergence-complete]] | activated: 2026-05-19
- [uses: 1] Layered gate enforcement: preventive (implementation-guide.md pre-flight refusal) + detective (dev-debrief gate-compliance audit) + template (session-start.sh gate-check warning); mirrors Tier 0/1 review pattern
  source: [[decision:layered-gate-enforcement-automated]] | activated: 2026-05-19
- [uses: 1] Standard ceremony expects 4 gates (spec, approach, plan-review, tasks); Lite expects 2 (approach, tasks); n/a with justification is valid; SKIPPED without justification is flagged
  source: [[journal:2026-05-19-phase-11-process-hardening-complete]] | activated: 2026-05-19
