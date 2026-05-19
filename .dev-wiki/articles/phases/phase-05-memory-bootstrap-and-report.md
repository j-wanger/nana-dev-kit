---
title: "Phase 5: Memory Bootstrap & Package Report"
aliases: []
category: phases
tags: [memory, bootstrap, pip, venv, report, html]
parents: []
created: 2026-05-15
updated: 2026-05-19
source: plan
status: completed
scope: ["install.sh", "scripts/generate-report.py", "docs/report.html", "tests/test_install.sh", "Makefile", "README.md"]
entry_criteria: "Phase 4 complete, memory_server vendored, MCP registered"
exit_criteria: "Venv bootstrap in install.sh with graceful fallback, HTML report generator covering all components, README updated"
---

# Phase 5: Memory Bootstrap & Package Report

## Objective

Make the memory MCP server functional end-to-end by auto-installing pip deps in an isolated venv, and generate a comprehensive HTML report documenting the full kit.

## Approach

1. **install.sh venv bootstrap**: Create venv at ~/.claude/memory_server/.venv/, install required deps via pip, update MCP config to use venv Python. Graceful fallback if venv creation fails (memory is optional).

2. **HTML package report**: Python script at scripts/generate-report.py generates docs/report.html -- comprehensive single-page assessment of all kit components (5 layers, memory system, dev-wiki integration, file tree, workflows, template inventory, test coverage, dependencies). Add `make report` target.

3. **README update**: Note memory deps auto-installed via venv, add `make report` mention, stay within line budget.

## Scope

- `install.sh` -- venv creation + pip install + MCP config update to venv Python
- `tests/test_install.sh` -- new test cases for venv creation and MCP config
- `scripts/generate-report.py` -- new Python script for HTML report generation
- `docs/report.html` -- generated output
- `Makefile` -- new `report` target
- `README.md` -- auto-install note + make report mention

**NOT in scope:** memory_server code changes, fastembed installation, memory server functional tests (MCP protocol), dev-wiki structural changes.

## Tasks (3 total: 1S + 2M)

1. **[M]** Bootstrap memory server deps in install.sh (venv + pip install + MCP config)
2. **[M]** Create HTML package report generator (scripts/generate-report.py + make report)
3. **[S]** Update README.md (auto-install note + make report mention)

## Key Decisions

- [[venv-isolated-memory-deps]]: Isolated venv at ~/.claude/memory_server/.venv/, no system Python pollution, graceful fallback

## Exit Criteria

- [ ] install.sh creates venv and pip installs memory_server deps (graceful fallback on failure)
- [ ] MCP config uses venv Python interpreter path
- [ ] scripts/generate-report.py generates docs/report.html covering all kit components
- [ ] `make report` target works
- [ ] README documents auto-install and make report
- [ ] All existing tests continue to pass (no regression)
