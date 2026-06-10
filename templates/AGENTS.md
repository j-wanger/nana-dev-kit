# Project: {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Toolchain

- Python 3.12+. Package manager: uv (never pip or poetry).
- Install: `uv sync` (add `--extra dev` if dev tools are an optional group). Run: `uv run <cmd>`. Add dep: `uv add <pkg>`.
- Lint, types, and tests run via the Pre-commit sequence below (ruff, mypy, pytest — all config in pyproject.toml).
- Lock: `uv.lock` is committed. Never run `uv add` without checking the package exists on PyPI.

## Hard Rules

- Never commit secrets. `.env*` is gitignored and contains placeholders only.
- Run `pre-commit run --all-files` before declaring any task done.
- Never add a dependency without verifying it exists on PyPI and is actively maintained.
- Never use `# type: ignore` without an inline comment explaining why.

## Conventions

- Validate at boundaries; keep core logic in pure, typed functions (no hidden I/O) so it is unit-testable.
- Logging via a structured logger; never `print()`.
- Config via environment / a typed settings object; no magic constants buried in logic.
- Imports: absolute from `src/`. No relative imports across packages.
- Error handling: let exceptions propagate. No bare `except Exception`. No `pass` in except blocks.
- One function, one job. If a docstring needs "and", split the function.

<!-- Replace the generic conventions above with your domain's real rules (e.g. for a web service:
     Pydantic v2 at API boundaries, DB access behind a repository layer, no SQLAlchemy in routers).
     The point is project-specific rules the agent must follow — not these defaults verbatim. -->

## Testing

- Tests live in `tests/unit/` and `tests/integration/`. Fixtures in `tests/conftest.py`.
- Every public function has at least one positive and one negative test.
- Test names are specifications: `test_returns_empty_list_when_no_matching_records`.
- Mock external services at the boundary only; prefer real implementations for your own code.

## Branch + Commit

- Branch names: `feat/<ticket>-slug`, `fix/<ticket>-slug`, `chore/<ticket>-slug`.
- Conventional Commits required. Subject ≤ 72 chars. Body explains why, not what.
- AI-authored commits include trailer: `AI-Author: <tool> (<model>)`

## Project Structure

```
{{PROJECT_NAME}}/
  src/
    {{PACKAGE_NAME}}/
      __init__.py
      ...              # organize modules by responsibility (one job each)
  tests/
    unit/
    integration/
    conftest.py
  pyproject.toml
  uv.lock
```

## Where to Look

- Project state and phase history: `.dev-wiki/_CURRENT_STATE.md`, `.dev-wiki/_ARCHITECTURE.md`
- Testing patterns: `tests/` and `pyproject.toml` tool config
- Conventions and rules: `.claude/rules/`

## Pre-commit sequence

Run before declaring any task complete — all three must pass:

```bash
uv run ruff check --fix . && uv run ruff format .
uv run mypy
uv run pytest
```

<!-- Instruction budget: this file + nana identity + workflow instructions ≈ 170 lines always-loaded.
     Ceiling before instruction-following degrades: ~300 lines total across all always-loaded files.
     If agent stops following rules, audit total line count across AGENTS.md + .claude/rules/ + .github/instructions/. -->
