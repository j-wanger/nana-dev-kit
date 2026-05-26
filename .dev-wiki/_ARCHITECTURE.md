# Architecture: nana-dev-kit

> Last updated: 2026-05-25 by /dev-debrief (Phase 41 completed)

## Project Shape

Shell/Markdown/Python scaffolding kit (220+ files: 23 .sh hooks, 120+ skill .md, 22+ template .md, 14 memory_server .py, 4 wiki-index .py, 50 eval scenarios, 4 eval schemas, 4 eval validators, 2 benchmark .py/.md, 4 .json, 2 .txt, 1 .yaml, 2 .yml, 1 .toml, 1 Makefile, 1 VERSION, 1 kit-ci.yml, 1 .gitignore, 1 .patch, 2 scripts .py). Runtime: bash + jq (hooks + eval). Scaffolds a 5-layer Python dev harness + TypeScript dev harness + dev-wiki lifecycle + knowledge-wiki pipeline into new/existing projects via two operational modes: `install.sh` (one-time global, reads modules.json via jq, delegates JSON merges to scripts/register-settings.py, with --all/--core-only/--no-python/--no-typescript/--project-local/--dry-run/--status flags) and `make sync-rules` (per-project). 2-gate ceremony model (direction + delivery) with autonomous agent flow between gates. ~303 automated tests via `make test` + 50 eval scenarios via `make eval`. LongMemEval-S benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95%. v0.5.0 on GitHub.

## Directory Layout

nana-dev-kit/
  install.sh                           # Module-group installer (318 lines, zero inline Python, reads modules.json via jq, delegates JSON merges to register-settings.py)
  modules.json                         # Declarative module manifest (5 modules: core, python, typescript, dev-wiki, knowledge-wiki)
  Makefile, VERSION, README.md         # Build targets, v0.5.0, docs (~95 lines, 7 sections)
  .github/workflows/kit-ci.yml        # Kit CI: shellcheck + make test
  memory_server/                       # Vendored MCP memory server (12 .py, nanaclaw)
  docs/                                # Generated HTML reports (report.html, workflow.html)
  patches/                               # Upstream sync patches
    nanaclaw-sanitize-fts.patch        # Surgical _sanitize_fts_query fix for nanaclaw upstream
  benchmark/                             # LongMemEval-S memory retrieval benchmark
    longmemeval.py                     # Benchmark script (FTS5+hybrid, per-question DB isolation, recall@5/10)
    README.md                          # Usage instructions + interpretation guide
    data/, results.json, .venv/        # Gitignored: dataset cache, results, Python venv
  eval/                                # Eval harness: corpus, schemas, validators
    corpus/                            # Scenario directories (hook-*, skill-*, lifecycle-*)
    schemas/                           # JSON input schemas for hook contracts
    validators/                        # Bash validators for skill artifact contracts
    README.md                          # Corpus structure + scoring documentation
  scripts/                             # sync-rules.sh, generate-report.py (~350 lines), generate-workflow.py (~800 lines), eval-runner.sh (~310 lines), generate-delivery-report.py (196 lines), register-settings.py (~120 lines)
  tests/                               # 7 scripts, ~303 tests (helpers.sh + test_*.sh)
  templates/
    AGENTS.md, AGENTS-ts.md, pyproject.toml, .pre-commit-config.yaml
    .claude/
      hooks/                           # 13 lifecycle hooks (session-start, pre-compact, post-commit, audit-log, enforce-spec, enforce-loop, enforce-memory, detect-loop, etc.)
        session-start.d/               # Sourced modules (wk-prune.sh, memory-nudge.sh)
      rules/                           # 4 identity + lifecycle rules (soul, personal, lifecycle, session-state)
      skills/                          # 26 dirs + MANIFEST (~130 files)
        dev-{check,debrief,init,plan,scan,wiki}/  # Dev-wiki lifecycle (6 dirs)
        wiki-{absorb,add,bootstrap,consolidate,health,index,init,query,registry,reorg}/  # Knowledge-wiki (10 dirs)
        knowledge-wiki/                # Knowledge-wiki routing
        py-{init,lint,review,test}/    # Python quality (4 dirs)
        ts-init/                       # TypeScript scaffolding (SKILL.md + scanner.md + transform.md)
        init/                          # Language-agnostic router (detects markers, dispatches to py-init/ts-init)
        spec/                          # Spec creation + adversarial
        nana/                          # In-session skill discovery (reads MANIFEST)
        memory-consolidate/            # Claude-powered memory consolidation
    .github/                           # CI (ci.yml, ci-ts.yml), PR template, CODEOWNERS, instructions

## Entry Points

| Entry Point | Invocation | Purpose |
|-------------|-----------|---------|
| install.sh | `bash install.sh [--all\|--core-only\|--no-python\|--no-typescript\|--project-local\|--dry-run\|--status]` | Module-group global install: core (rules + memory), python (py-init + spec), typescript (ts-init), dev-wiki (6 skill dirs), knowledge-wiki (11 skill dirs). --project-local installs 6 per-project hooks. --status shows runtime inventory. |
| scripts/sync-rules.sh | `make sync-rules` | Per-project: syncs AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md |
| scripts/eval-runner.sh | `make eval` | Runs eval corpus (50 scenarios in 4 categories), produces scored report. Requires jq. |

## Module Responsibilities

| Module | Purpose | Key Files | Inputs | Outputs |
|--------|---------|-----------|--------|---------|
| root | Global installer and project targets | install.sh (318 lines), modules.json, scripts/register-settings.py, Makefile, VERSION | templates/.claude/, modules.json | ~/.claude/skills/ (26 dirs), ~/.claude/rules/ (3 files), ~/.claude/hooks/ (11 global hooks), ~/.claude/memory_server/, ~/.claude/memory_server/.venv/, .claude/enforce (marker), ~/.claude/enforce-memory (marker) |
| memory_server/ | Vendored MCP memory server (nanaclaw, 2,373 LOC, near-zero divergence from upstream) | server.py, storage.py, embedding.py, *.py | MCP stdio | Memory CRUD via MCP protocol |
| .github/workflows/ | Kit CI (shellcheck + make test) | kit-ci.yml | .sh files, Makefile | CI pass/fail |
| benchmark/ | LongMemEval-S retrieval benchmark (FTS5 recall@5 91.0%, hybrid/turn ~95%, turn-level indexing) | longmemeval.py, README.md | memory_server/storage.py, HuggingFace dataset, fastembed (optional) | benchmark/results.json, stdout summary |
| eval/ | Eval harness: benchmark corpus + scoring (50 scenarios) | corpus/*/scenario.json, schemas/*.json, validators/*.sh | templates/.claude/hooks/*, skill outputs | Scored eval report (text) |
| docs/ | Generated reports (7-Layer architecture) | report.html (package inventory, Eval/Specs categories), workflow.html (12-hook table, Enforcement + Memory Bridge sections) | Project files, templates/.claude/skills/MANIFEST, templates/.claude/settings.json | HTML package inventory + workflow breakdown |
| scripts/ | Multi-agent sync + report generation + eval + delivery + settings registration | sync-rules.sh, generate-report.py (~350 lines), generate-workflow.py (~800 lines), eval-runner.sh (~310 lines), generate-delivery-report.py (196 lines), register-settings.py (~120 lines, hooks + mcp subcommands for JSON merge) | AGENTS.md, project tree, eval/corpus/, templates/.claude/skills/MANIFEST, templates/.claude/settings.json, modules.json | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md, docs/report.html, docs/workflow.html, eval report (text), delivery report (HTML), settings.json (hook + MCP registration) |
| tests/ | Automated bash test suite (~303 tests, including 3 README accuracy + 6 report staleness + 23 functional verification + ~10 register-settings.py tests + 2 companion validation) | helpers.sh, test_*.sh | install.sh, scripts/, templates/, docs/, modules.json | stdout (pass/fail) |
| templates/.claude/hooks/ | Claude Code lifecycle hook templates (17 files + session-start.d/ with 2 modules). All hooks use `[nana:<hook>]` message prefix (exception: `[dev-wiki:post-commit]` kept as semantic trigger). All use jq for JSON parsing (detect-loop.sh is pure bash exception). enforce-spec.sh, enforce-loop.sh, enforce-memory.sh write enforcement.log (JSONL, 500-line cap). PostToolUse hooks use `.tool_input.file_path // .input.file_path` canonical path with defensive fallback. | session-start.sh, session-start.d/{wk-prune,memory-nudge}.sh, pre-compact.sh, post-compact.sh, post-commit.sh, context-size-check.sh, dev-wiki-scope-check.sh, session-stop.sh, stale-queue.sh, audit-log.sh, enforce-spec.sh, enforce-loop.sh, enforce-memory.sh, detect-loop.sh, scan-secrets.sh, etc. | .dev-wiki/ state, .claude/rules/, specs/*.md, .claude/enforce, ~/.claude/enforce-memory | stdout (context injection, safety gates, enforcement blocking, loop detection, commit notification, memory gate, scope check, stale queue), .dev-wiki/enforcement.log |
| templates/.claude/rules/ | Identity + lifecycle rules (4 files) | nana-soul.md (59 lines), nana-personal.md, file-lifecycle.md, py-session-state.md | -- | -- |
| templates/.claude/skills/ | 26 skill directories + MANIFEST with descriptions (~130 files) | SKILL.md files + companion .md files (incl. plan-review-companion.md, delivery-flow.md) | -- | -- |
| templates/.github/ | GitHub config templates (6 files) | workflows/ci.yml, workflows/ci-ts.yml, PULL_REQUEST_TEMPLATE.md, CODEOWNERS, instructions/* | -- | -- |

## Cross-File Dependencies

Test scripts source `tests/helpers.sh`. All shell scripts standalone. install.sh reads module definitions from modules.json via jq and delegates JSON merge operations to scripts/register-settings.py.

## Dependencies

Bash + jq (hooks + eval). memory_server requires python3 + pip deps (mcp, pydantic, pyyaml, nanoid, httpx); optional deps (fastembed, sqlite-vec) gracefully degrade. wiki-index ships .py files needing runtime deps. All hooks use jq for JSON parsing; detect-loop.sh uses pure bash (no JSON parsing).

## Data Flow

| Module | Reads | Writes | Notes |
|--------|-------|--------|-------|
| install.sh | templates/.claude/*, modules.json | ~/.claude/* (26 skill dirs, 3 rules, hooks/, memory_server, settings.json) | Reads modules.json via jq, calls register-settings.py for JSON merges |
| sync-rules.sh | AGENTS.md | CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md | Per-project |
| session-start.sh | py-session-state.md, _CURRENT_STATE.md, active-phase.md | stdout | Context + memory guidance |
| pre-compact.sh | _CURRENT_STATE.md, tasks.md, active-phase.md | stdout | Structured summary |

## Test Organization

~303 automated tests (7 scripts) + 50 eval scenarios (4 categories). `make test` runs regression tests fail-fast in temp dirs. `make eval` runs scored eval separately (requires jq).

## Known Issues

- MEDIUM: `templates/.github/workflows/ci.yml:29` hardcodes `src/` for mypy -- acceptable since /py-init replaces it based on detected source_dir
- LOW: wiki-index ships Python files (.py) alongside .md -- needs accounting in language-neutrality audit

## Related
