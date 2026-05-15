# Working Knowledge
<!-- Cross-phase knowledge. Auto-managed by dev-debrief and wiki-query. -->

- [uses: 1] install.sh copies exactly 3 things: py-init skill, nana-soul rule, kit path marker -- hooks are NOT global
  source: [[wiki:install-sh-stays-minimal]] | activated: 2026-05-15
- [uses: 1] README targets ~40-50 lines with install + usage + 5-layer table; self-test.md is the detailed reference
  source: [[wiki:readme-concise-format]] | activated: 2026-05-15
- [uses: 1] .dev-wiki/ is committed as project lifecycle artifact; .claude/settings.local.json is excluded via .gitignore
  source: [[wiki:commit-dev-wiki-in-initial-commit]] | activated: 2026-05-15
- [uses: 1] install.sh is idempotent: copies 3 files (py-init/SKILL.md, nana-soul.md, .nana-dev-kit-path); running twice produces identical results
  source: [[file:install]] | activated: 2026-05-15
- [uses: 1] sync-rules.sh writes 4 outputs (CLAUDE.md, GEMINI.md, copilot-instructions.md, .cursor/rules/main.mdc) with AUTO-GENERATED headers; missing AGENTS.md exits non-zero
  source: [[file:scripts-sync-rules]] | activated: 2026-05-15
- [uses: 1] Templates use {{PACKAGE_NAME}}, {{PROJECT_DESCRIPTION}}, {{PROJECT_NAME}} placeholders; tests verify presence via grep, not substitution
  source: [[decision:structural-placeholder-verification]] | activated: 2026-05-15
