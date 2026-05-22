# Architecture: nana-dev-kit

> Last updated: 2026-05-22 by /dev-plan (Phase 16 planned)

## Project Shape

Shell/Markdown/Python scaffolding kit (150+ files: 12 .sh, 107 skill .md, 20+ template .md, 14 memory_server .py, 4 wiki-index .py, 2 .json, 2 .txt, 1 .yaml, 1 .yml, 1 .toml, 1 Makefile, 1 VERSION, 1 kit-ci.yml, 1 .gitignore). Runtime: bash + python3. Scaffolds a 5-layer Python dev harness + dev-wiki lifecycle + knowledge-wiki pipeline into new/existing projects via two operational modes: `install.sh` (one-time global, module-group architecture with --all/--core-only/--no-python/--dry-run flags) and `make sync-rules` (per-project). 92 automated tests via `make test`. v0.3.0 on GitHub.

## Directory Layout

nana-dev-kit/
  install.sh                           # Module-group installer (~240 lines, --all/--core-only/--no-python/--dry-run)
  Makefile, VERSION, README.md         # Build targets, v0.3.0, docs
  .github/workflows/kit-ci.yml        # Kit CI: shellcheck + make test
  memory_server/                       # Vendored MCP memory server (12 .py, nanaclaw)
  docs/                                # Generated HTML reports (report.html, workflow.html)
  scripts/                             # sync-rules.sh, generate-report.py, generate-workflow.py
  tests/                               # 4 scripts, 92 tests (helpers.sh + test_*.sh)
  templates/
    AGENTS.md, pyproject.toml, .pre-commit-config.yaml
    .claude/
      hooks/                           # 10 lifecycle hooks (session-start, pre-compact, audit-log, enforce-*, etc.)
      rules/                           # 4 identity + lifecycle rules (soul, personal, lifecycle, session-state)
      skills/                          # 22 dirs + MANIFEST (115 files, ~630KB)
        dev-{check,debrief,init,plan,scan,wiki}/  # Dev-wiki lifecycle (6 dirs)
        wiki-{absorb,add,bootstrap,consolidate,health,index,init,query,registry,reorg}/  # Knowledge-wiki (10 dirs)
        knowledge-wiki/                # Knowledge-wiki routing
        py-{init,lint,review,test}/    # Python quality (4 dirs)
        spec/                          # Spec creation + adversarial
    .github/                           # CI, PR template, CODEOWNERS, instructions

## Entry Points

| Entry Point | Invocation | Purpose |
|-------------|-----------|---------|
| install.sh | `bash install.sh [--all\|--core-only\|--no-python\|--dry-run]` | Module-group global install: core (rules + memory), python (py-init + spec), dev-wiki (6 skill dirs), knowledge-wiki (11 skill dirs). Flags control which modules install. |
| scripts/sync-rules.sh | `make sync-rules` | Per-project: syncs AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh, Makefile, VERSION | templates/.claude/ | ~/.claude/skills/ (22 dirs), ~/.claude/rules/ (3 files), ~/.claude/hooks/ (enforcement), ~/.claude/memory_server/, ~/.claude/memory_server/.venv/ |
| memory_server/ | Vendored MCP memory server (nanaclaw, 2,373 LOC) | server.py, storage.py, embedding.py, *.py | MCP stdio | Memory CRUD via MCP protocol |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| docs/ | Generated reports | report.html, workflow.html | Project files (scanned) | HTML package inventory + workflow breakdown |
| scripts/ | Multi-agent sync + report generation | sync-rules.sh, generate-report.py, generate-workflow.py | AGENTS.md, project tree | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md, docs/report.html, docs/workflow.html |
| tests/ | Automated bash test suite (92 tests) | helpers.sh, test_*.sh | install.sh, scripts/, templates/ | stdout (pass/fail) |
| templates/.claude/hooks/ | Claude Code lifecycle hook templates (8 files) | session-start.sh, pre-compact.sh, audit-log.sh, etc. | .dev-wiki/ state, .claude/rules/ | stdout (context injection, safety gates) |
| templates/.claude/rules/ | Identity + lifecycle rules (4 files) | nana-soul.md (59 lines), nana-personal.md, file-lifecycle.md, py-session-state.md | -- | -- |
| templates/.claude/skills/ | 22 skill directories + MANIFEST (115 files) | SKILL.md files + companion .md files | -- | -- |
| templates/.github/ | GitHub config templates (5 files) | workflows/ci.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh`. All shell scripts standalone. install.sh references templates/.claude/skills/ directories by name for module-group iteration.

## Dependencies

Bash + python3. memory_server requires pip deps (mcp, pydantic, pyyaml, nanoid, httpx); optional deps (fastembed, sqlite-vec) gracefully degrade. wiki-index ships .py files needing runtime deps.

## Data Flow

| Module | Reads | Writes | Notes |
|--------|-------|--------|-------|
| install.sh | templates/.claude/* | ~/.claude/* (22 skill dirs, 3 rules, hooks/, memory_server, settings.json) | Module-group, flag-controlled |
| sync-rules.sh | AGENTS.md | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | Per-project |
| session-start.sh | py-session-state.md, _CURRENT_STATE.md, active-phase.md | stdout | Context + memory guidance |
| pre-compact.sh | _CURRENT_STATE.md, tasks.md, active-phase.md | stdout | Structured summary |

## Test Organization

92 automated tests (4 scripts) + 13 manual smoke tests. `make test` runs all fail-fast in temp dirs (~5.2s).

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir
- LOW: wiki-index ships Python files (.py) alongside .md -- needs accounting in language-neutrality audit

## Related

- None yet
