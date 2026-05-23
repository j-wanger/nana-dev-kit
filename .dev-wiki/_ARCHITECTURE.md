# Architecture: nana-dev-kit

> Last updated: 2026-05-22 by /dev-debrief (Phase 24 completed)

## Project Shape

Shell/Markdown/Python scaffolding kit (175+ files: 17 .sh, 107 skill .md, 20+ template .md, 14 memory_server .py, 4 wiki-index .py, 38 eval scenarios, 4 eval schemas, 4 eval validators, 2 .json, 2 .txt, 1 .yaml, 1 .yml, 1 .toml, 1 Makefile, 1 VERSION, 1 kit-ci.yml, 1 .gitignore). Runtime: bash + python3 + jq (hooks + eval). Scaffolds a 5-layer Python dev harness + dev-wiki lifecycle + knowledge-wiki pipeline into new/existing projects via two operational modes: `install.sh` (one-time global, module-group architecture with --all/--core-only/--no-python/--dry-run flags) and `make sync-rules` (per-project). 150 automated tests via `make test` + 38 eval scenarios via `make eval`. v0.4.0 on GitHub.

## Directory Layout

nana-dev-kit/
  install.sh                           # Module-group installer (~270 lines, --all/--core-only/--no-python/--dry-run, hooks module, PreCompact)
  Makefile, VERSION, README.md         # Build targets, v0.4.0, docs (93 lines, 7 sections)
  .github/workflows/kit-ci.yml        # Kit CI: shellcheck + make test
  memory_server/                       # Vendored MCP memory server (12 .py, nanaclaw)
  docs/                                # Generated HTML reports (report.html, workflow.html)
  eval/                                # Eval harness: corpus, schemas, validators
    corpus/                            # Scenario directories (hook-*, skill-*, lifecycle-*)
    schemas/                           # JSON input schemas for hook contracts
    validators/                        # Bash validators for skill artifact contracts
    README.md                          # Corpus structure + scoring documentation
  scripts/                             # sync-rules.sh, generate-report.py, generate-workflow.py, eval-runner.sh (~270 lines)
  tests/                               # 6 scripts, 142 tests (helpers.sh + test_*.sh)
  templates/
    AGENTS.md, pyproject.toml, .pre-commit-config.yaml
    .claude/
      hooks/                           # 11 lifecycle hooks (session-start, pre-compact, audit-log, enforce-spec, enforce-loop, detect-loop, etc.)
        session-start.d/               # Sourced modules (wk-prune.sh, memory-nudge.sh)
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
| scripts/eval-runner.sh | `make eval` | Runs eval corpus (38 scenarios in 4 categories), produces scored report. Requires jq. |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh, Makefile, VERSION | templates/.claude/ | ~/.claude/skills/ (22 dirs), ~/.claude/rules/ (3 files), ~/.claude/hooks/ (enforcement: enforce-spec.sh, enforce-loop.sh; advisory: detect-loop.sh), ~/.claude/memory_server/, ~/.claude/memory_server/.venv/, .claude/enforce (marker) |
| memory_server/ | Vendored MCP memory server (nanaclaw, 2,373 LOC) | server.py, storage.py, embedding.py, *.py | MCP stdio | Memory CRUD via MCP protocol |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| eval/ | Eval harness: benchmark corpus + scoring | corpus/*/scenario.json, schemas/*.json, validators/*.sh | templates/.claude/hooks/*, skill outputs | Scored eval report (text) |
| docs/ | Generated reports | report.html, workflow.html | Project files (scanned) | HTML package inventory + workflow breakdown |
| scripts/ | Multi-agent sync + report generation + eval | sync-rules.sh, generate-report.py, generate-workflow.py, eval-runner.sh | AGENTS.md, project tree, eval/corpus/ | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md, docs/report.html, docs/workflow.html, eval report (text) |
| tests/ | Automated bash test suite (150 tests) | helpers.sh, test_*.sh | install.sh, scripts/, templates/ | stdout (pass/fail) |
| templates/.claude/hooks/ | Claude Code lifecycle hook templates (11 files + session-start.d/ with 2 modules). 6 hooks use jq for JSON parsing; detect-loop.sh is pure bash; others have no JSON parsing. | session-start.sh, session-start.d/{wk-prune,memory-nudge}.sh, pre-compact.sh, audit-log.sh, enforce-spec.sh, enforce-loop.sh, detect-loop.sh, scan-secrets.sh, etc. | .dev-wiki/ state, .claude/rules/, specs/*.md, .claude/enforce | stdout (context injection, safety gates, enforcement blocking, loop detection) |
| templates/.claude/rules/ | Identity + lifecycle rules (4 files) | nana-soul.md (59 lines), nana-personal.md, file-lifecycle.md, py-session-state.md | -- | -- |
| templates/.claude/skills/ | 22 skill directories + MANIFEST (115 files) | SKILL.md files + companion .md files | -- | -- |
| templates/.github/ | GitHub config templates (5 files) | workflows/ci.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh`. All shell scripts standalone. install.sh references templates/.claude/skills/ directories by name for module-group iteration.

## Dependencies

Bash + python3 + jq (hooks + eval). memory_server requires pip deps (mcp, pydantic, pyyaml, nanoid, httpx); optional deps (fastembed, sqlite-vec) gracefully degrade. wiki-index ships .py files needing runtime deps. 6 hooks use jq for JSON parsing (audit-log, auto-ruff, block-dangerous-bash, scan-secrets, enforce-spec, check-tests-were-run); detect-loop.sh uses pure bash.

## Data Flow

| Module | Reads | Writes | Notes |
|--------|-------|--------|-------|
| install.sh | templates/.claude/* | ~/.claude/* (22 skill dirs, 3 rules, hooks/, memory_server, settings.json) | Module-group, flag-controlled |
| sync-rules.sh | AGENTS.md | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | Per-project |
| session-start.sh | py-session-state.md, _CURRENT_STATE.md, active-phase.md | stdout | Context + memory guidance |
| pre-compact.sh | _CURRENT_STATE.md, tasks.md, active-phase.md | stdout | Structured summary |

## Test Organization

150 automated tests (6 scripts) + 38 eval scenarios (4 categories). `make test` runs regression tests fail-fast in temp dirs. `make eval` runs scored eval separately (requires jq).

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir
- LOW: wiki-index ships Python files (.py) alongside .md -- needs accounting in language-neutrality audit

## Related

- None yet
