# Architecture: nana-dev-kit

> Last updated: 2026-05-15 by /dev-debrief

## Project Shape

Shell/Markdown scaffolding kit (34 files: 12 .sh, 15 .md, 2 .json, 1 .yaml, 1 .yml, 1 .toml, 1 Makefile). No runtime dependencies -- bash only. Scaffolds a 5-layer Python dev harness into new/existing projects via two operational modes: `install.sh` (one-time global) and `make sync-rules` (per-project). 30 automated tests via `make test`.

## Directory Layout

nana-dev-kit/
  install.sh                           # Global installer
  Makefile                             # Project targets (sync-rules, test)
  VERSION                              # Semantic version (single source of truth)
  self-test.md                         # Manual smoke test (13 cases)
  .github/
    workflows/
      kit-ci.yml                       # Kit CI: shellcheck + make test
  scripts/
    sync-rules.sh                      # Syncs AGENTS.md to 4 agent surfaces
  tests/
    helpers.sh                         # Shared assertions (assert_eq, assert_file_exists, etc.)
    test_install.sh                    # install.sh idempotency tests (10)
    test_sync_rules.sh                 # sync-rules.sh correctness tests (14)
    test_templates.sh                  # Template placeholder tests (6)
  templates/
    AGENTS.md                          # Agent instruction template (single source of truth)
    pyproject.toml                     # Python project config template
    .pre-commit-config.yaml            # Pre-commit hooks template
    .claude/                           # Claude Code config (hooks, rules, skills, settings)
    .github/                           # GitHub config (CI, PR template, CODEOWNERS, instructions)

## Entry Points

| Entry Point | Invocation | Purpose |
|-------------|-----------|---------|
| install.sh | `bash install.sh` | One-time global install: copies py-init skill + nana-soul rule to ~/.claude/, stores kit path |
| scripts/sync-rules.sh | `make sync-rules` | Per-project: syncs AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh, Makefile, VERSION | templates/.claude/ | ~/.claude/skills/, ~/.claude/rules/ |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| scripts/ | Multi-agent sync utility | sync-rules.sh | AGENTS.md | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |
| tests/ | Automated bash test suite (30 tests) | helpers.sh, test_*.sh | install.sh, scripts/, templates/ | stdout (pass/fail) |
| templates/.claude/ | Claude Code config templates (16 files) | hooks/*, rules/*, skills/*, settings.json | -- | -- |
| templates/.github/ | GitHub config templates (5 files) | workflows/ci.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh` for shared assertions. All other shell scripts are standalone with no internal imports.

## Dependencies

No runtime dependencies. Bash only. Hook scripts use `python3` for JSON parsing (expected on target systems).

## Data Flow

| Module | Reads (data) | Writes (data) | Env Vars | Notes |
|--------|-------------|---------------|----------|-------|
| install.sh | templates/.claude/skills/py-init/SKILL.md, templates/.claude/rules/nana-soul.md | ~/.claude/skills/py-init/SKILL.md, ~/.claude/rules/nana-soul.md, ~/.claude/.nana-dev-kit-path | -- | One-time global install |
| scripts/sync-rules.sh | AGENTS.md (in target project) | CLAUDE.md, .github/copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | -- | Run per-project |
| hooks/audit-log.sh | stdin (JSON from Claude Code) | .nana/audit.jsonl | CLAUDE_MODEL | PostToolUse |
| hooks/session-start.sh | PROJECT_STATE.md, .claude/rules/py-session-state.md | stdout | -- | SessionStart |

## Test Organization

| Directory | What It Tests | Count |
|-----------|---------------|-------|
| self-test.md | Manual smoke tests for all 5 layers | 13 cases (manual) |
| tests/ | Automated bash test suite | 4 scripts, 30 tests |

Test harness: `tests/helpers.sh` provides assert functions (assert_eq, assert_file_exists, assert_contains, assert_exit_code) + summary reporting. Each `tests/test_*.sh` sources it. `make test` runs all scripts fail-fast. Tests use temp dirs (mktemp -d) for isolation.

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir

## Related

- None yet
