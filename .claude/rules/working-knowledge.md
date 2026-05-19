# Working Knowledge
<!-- Cross-phase knowledge. Auto-managed by dev-debrief and wiki-query. -->

- [uses: 1] install.sh performs 4 actions: copies py-init skill, nana-soul rule, kit path marker, memory_server/ + registers MCP server in settings.json
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-15
- [uses: 1] README targets ~58 lines with install + usage + 5-layer table + memory/dev-wiki section; self-test.md is the detailed reference
  source: [[wiki:readme-concise-format]] | activated: 2026-05-15
- [uses: 1] .dev-wiki/ is committed as project lifecycle artifact; .claude/settings.local.json is excluded via .gitignore
  source: [[wiki:commit-dev-wiki-in-initial-commit]] | activated: 2026-05-15
- [uses: 1] install.sh is idempotent: copies 3 files + memory_server + JSON merge; running twice produces identical results
  source: [[file:install]] | activated: 2026-05-15
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
- [uses: 1] session-start.sh reads 4 sources: PROJECT_STATE.md, py-session-state.md, dev-wiki/_CURRENT_STATE.md, .memory/MEMORY.md; all with graceful silent skip
  source: [[journal:2026-05-15-phase-4-dev-wiki-and-memory-integration-complete]] | activated: 2026-05-15
- [uses: 1] MCP registration uses idempotent python3 JSON merge; handles 3 cases: no settings.json, existing without mcpServers, existing with mcpServers
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-15
- [uses: 1] memory_server pip deps (mcp, pydantic, etc.) not auto-installed by install.sh; user must pip install manually
  source: [[journal:2026-05-15-phase-4-dev-wiki-and-memory-integration-complete]] | activated: 2026-05-15
