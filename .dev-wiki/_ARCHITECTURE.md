# Architecture: nana-dev-kit

> Last updated: 2026-05-19 by /dev-debrief (Phase 10 complete)

## Project Shape

Shell/Markdown/Python scaffolding kit (55+ files: 12 .sh, 19 .md, 14 .py, 2 .json, 2 .txt, 1 .yaml, 1 .yml, 1 .toml, 1 Makefile, 1 VERSION, 1 kit-ci.yml, 1 .gitignore). Runtime: bash + python3. Scaffolds a 5-layer Python dev harness into new/existing projects via two operational modes: `install.sh` (one-time global, includes memory MCP server with venv bootstrap + /spec skill + file lifecycle routing) and `make sync-rules` (per-project). 59 automated tests via `make test`. v0.2.0 on GitHub.

## Directory Layout

nana-dev-kit/
  install.sh                           # Global installer (5 files + memory_server + MCP + venv)
  Makefile                             # Project targets (sync-rules, test, report, workflow)
  VERSION                              # Semantic version: 0.2.0
  README.md                            # Install + usage + memory/dev-wiki + upgrading
  self-test.md                         # Manual smoke test (13 cases)
  .github/
    workflows/
      kit-ci.yml                       # Kit CI: shellcheck + make test
  memory_server/                       # Vendored MCP memory server (12 .py files from nanaclaw)
    server.py                          # MCP server entry point (python -m memory_server)
    storage.py                         # Memory storage backend
    embedding.py                       # Optional fastembed integration (try/except guarded)
    requirements.txt                   # Required deps: mcp, pydantic, pyyaml, nanoid, httpx
    requirements-optional.txt          # Optional: fastembed, sqlite-vec
  docs/
    report.html                        # Generated HTML package inventory (v0.2.0)
    workflow.html                      # Generated HTML workflow breakdown (v0.2.0)
  scripts/
    generate-report.py                 # Python script: scans project, generates docs/report.html
    generate-workflow.py               # Python script: workflow breakdown generator (738 lines)
    sync-rules.sh                      # Syncs AGENTS.md to 4 agent surfaces (writability check)
  tests/
    helpers.sh                         # Shared assertions (assert_eq, assert_file_exists, etc.)
    test_install.sh                    # install.sh tests (20: idempotency + MCP + spec)
    test_sync_rules.sh                 # sync-rules.sh tests (16)
    test_templates.sh                  # Protocol + spec + budget regression (19)
  templates/
    AGENTS.md                          # Agent instruction template (single source of truth)
    pyproject.toml                     # Python project config template
    .pre-commit-config.yaml            # Pre-commit hooks template
    .claude/                           # Claude Code config (hooks, rules, skills, settings)
    .github/                           # GitHub config (CI, PR template, CODEOWNERS, instructions)

## Entry Points

| Entry Point | Invocation | Purpose |
|-------------|-----------|---------|
| install.sh | `bash install.sh` | One-time global install: copies py-init + spec skills + nana-soul + nana-personal + file-lifecycle rules + memory_server to ~/.claude/, registers MCP server, stores kit path |
| scripts/sync-rules.sh | `make sync-rules` | Per-project: syncs AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh, Makefile, VERSION | templates/.claude/ | ~/.claude/skills/ (py-init + spec), ~/.claude/rules/ (soul + personal + lifecycle), ~/.claude/memory_server/, ~/.claude/memory_server/.venv/ |
| memory_server/ | Vendored MCP memory server (nanaclaw, 2,373 LOC) | server.py, storage.py, embedding.py, *.py | MCP stdio | Memory CRUD via MCP protocol |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| docs/ | Generated reports | report.html, workflow.html | Project files (scanned) | HTML package inventory + workflow breakdown |
| scripts/ | Multi-agent sync + report generation | sync-rules.sh, generate-report.py, generate-workflow.py | AGENTS.md, project tree | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md, docs/report.html, docs/workflow.html |
| tests/ | Automated bash test suite (59 tests) | helpers.sh, test_*.sh | install.sh, scripts/, templates/ | stdout (pass/fail) |
| templates/.claude/ | Claude Code config templates (16 files) | hooks/*, rules/* (soul 52 lines), skills/*, settings.json | -- | -- |
| templates/.github/ | GitHub config templates (5 files) | workflows/ci.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh` for shared assertions. All other shell scripts are standalone with no internal imports.

## Dependencies

Bash + python3. Hook scripts and install.sh use python3 for JSON parsing. memory_server requires pip dependencies (mcp, pydantic, pyyaml, nanoid, httpx); optional deps (fastembed, sqlite-vec) gracefully degrade.

## Data Flow

| Module | Reads (data) | Writes (data) | Env Vars | Notes |
|--------|-------------|---------------|----------|-------|
| install.sh | templates/.claude/skills/py-init/SKILL.md, templates/.claude/skills/spec/, templates/.claude/rules/nana-soul.md, templates/.claude/rules/nana-personal.md, templates/.claude/rules/file-lifecycle.md, memory_server/ | ~/.claude/skills/py-init/SKILL.md, ~/.claude/skills/spec/, ~/.claude/rules/nana-soul.md, ~/.claude/rules/nana-personal.md, ~/.claude/rules/file-lifecycle.md, ~/.claude/.nana-dev-kit-path, ~/.claude/memory_server/, ~/.claude/settings.json | -- | One-time global install + MCP registration |
| scripts/sync-rules.sh | AGENTS.md (in target project) | CLAUDE.md, .github/copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | -- | Run per-project |
| hooks/audit-log.sh | stdin (JSON from Claude Code) | .nana/audit.jsonl | CLAUDE_MODEL | PostToolUse |
| hooks/session-start.sh | .claude/rules/py-session-state.md, .dev-wiki/_CURRENT_STATE.md | stdout | -- | SessionStart (2 sources, memory via MCP) |

## Test Organization

| Directory | What It Tests | Count |
|-----------|---------------|-------|
| self-test.md | Manual smoke tests for all 5 layers | 13 cases (manual) |
| tests/ | Automated bash test suite | 4 scripts, 59 tests |

Test harness: `tests/helpers.sh` provides assert functions (assert_eq, assert_file_exists, assert_contains, assert_exit_code) + summary reporting. Each `tests/test_*.sh` sources it. `make test` runs all scripts fail-fast. Tests use temp dirs (mktemp -d) for isolation. Breakdown: test_install.sh (21), test_sync_rules.sh (16), test_templates.sh (22, includes protocol + spec + lifecycle + budget regression).

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir

## Related

- None yet
