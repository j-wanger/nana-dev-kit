# Architecture: nana-dev-kit

> Last updated: 2026-05-15 by /dev-debrief

## Project Shape

Shell/Markdown/Python scaffolding kit (36+ files: 12 .sh, 15 .md, 12 .py, 2 .json, 1 .yaml, 1 .yml, 1 .toml, 1 Makefile, 1 VERSION, 1 kit-ci.yml, 1 .gitignore). Runtime: bash + python3. Scaffolds a 5-layer Python dev harness into new/existing projects via two operational modes: `install.sh` (one-time global, includes memory MCP server) and `make sync-rules` (per-project). 34 automated tests via `make test`.

## Directory Layout

nana-dev-kit/
  install.sh                           # Global installer (source validation)
  Makefile                             # Project targets (sync-rules, test)
  VERSION                              # Semantic version: 0.1.0
  README.md                            # Install + usage + upgrading (52 lines)
  self-test.md                         # Manual smoke test (13 cases)
  .github/
    workflows/
      kit-ci.yml                       # Kit CI: shellcheck + make test
  memory_server/                        # Vendored MCP memory server (12 .py files from nanaclaw)
    server.py                          # MCP server entry point (python -m memory_server)
    storage.py                         # Memory storage backend
    requirements.txt                   # Required deps: mcp, pydantic, pyyaml, nanoid, httpx
    requirements-optional.txt          # Optional: fastembed, sqlite-vec
  scripts/
    sync-rules.sh                      # Syncs AGENTS.md to 4 agent surfaces (writability check)
  tests/
    helpers.sh                         # Shared assertions (assert_eq, assert_file_exists, etc.)
    test_install.sh                    # install.sh tests (12)
    test_sync_rules.sh                 # sync-rules.sh tests (16)
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
| install.sh | `bash install.sh` | One-time global install: copies py-init skill + nana-soul rule + memory_server to ~/.claude/, registers MCP server, stores kit path |
| scripts/sync-rules.sh | `make sync-rules` | Per-project: syncs AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh, Makefile, VERSION | templates/.claude/ | ~/.claude/skills/, ~/.claude/rules/, ~/.claude/memory_server/ |
| memory_server/ | Vendored MCP memory server (nanaclaw) | server.py, storage.py, *.py | MCP stdio | Memory CRUD via MCP protocol |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| scripts/ | Multi-agent sync utility | sync-rules.sh | AGENTS.md | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |
| tests/ | Automated bash test suite (34 tests) | helpers.sh, test_*.sh | install.sh, scripts/, templates/ | stdout (pass/fail) |
| templates/.claude/ | Claude Code config templates (16 files) | hooks/*, rules/*, skills/*, settings.json | -- | -- |
| templates/.github/ | GitHub config templates (5 files) | workflows/ci.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh` for shared assertions. All other shell scripts are standalone with no internal imports.

## Dependencies

Bash + python3. Hook scripts and install.sh use python3 for JSON parsing. memory_server requires pip dependencies (mcp, pydantic, pyyaml, nanoid, httpx); optional deps (fastembed, sqlite-vec) gracefully degrade.

## Data Flow

| Module | Reads (data) | Writes (data) | Env Vars | Notes |
|--------|-------------|---------------|----------|-------|
| install.sh | templates/.claude/skills/py-init/SKILL.md, templates/.claude/rules/nana-soul.md, memory_server/ | ~/.claude/skills/py-init/SKILL.md, ~/.claude/rules/nana-soul.md, ~/.claude/.nana-dev-kit-path, ~/.claude/memory_server/, ~/.claude/settings.json | -- | One-time global install + MCP registration |
| scripts/sync-rules.sh | AGENTS.md (in target project) | CLAUDE.md, .github/copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | -- | Run per-project |
| hooks/audit-log.sh | stdin (JSON from Claude Code) | .nana/audit.jsonl | CLAUDE_MODEL | PostToolUse |
| hooks/session-start.sh | PROJECT_STATE.md, .claude/rules/py-session-state.md | stdout | -- | SessionStart |

## Test Organization

| Directory | What It Tests | Count |
|-----------|---------------|-------|
| self-test.md | Manual smoke tests for all 5 layers | 13 cases (manual) |
| tests/ | Automated bash test suite | 4 scripts, 34 tests |

Test harness: `tests/helpers.sh` provides assert functions (assert_eq, assert_file_exists, assert_contains, assert_exit_code) + summary reporting. Each `tests/test_*.sh` sources it. `make test` runs all scripts fail-fast. Tests use temp dirs (mktemp -d) for isolation. Breakdown: test_install.sh (12), test_sync_rules.sh (16), test_templates.sh (6).

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir

## Related

- None yet
