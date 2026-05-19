# Project: {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Toolchain

- Python 3.12+. Package manager: uv (never pip or poetry).
- Install: `uv sync`. Run: `uv run <cmd>`. Add dep: `uv add <pkg>`.
- Lint/format: `uv run ruff check --fix . && uv run ruff format .`
- Types: `uv run mypy` (strict mode, no untyped defs — reads config from pyproject.toml).
- Tests: `uv run pytest` (reads testpaths, coverage, and fail-under from pyproject.toml).
- Lock: `uv.lock` is committed. Never run `uv add` without checking the package exists on PyPI.

## Conventions

- All public API boundaries use Pydantic v2 models (`model_config`, not `class Config`).
- Database access through `src/repositories/`; routers never import SQLAlchemy directly.
- Logging via `structlog`; never `print()`.
- Config via environment variables loaded through `pydantic-settings`.
- Imports: absolute from `src/`. No relative imports across packages.
- Error handling: let exceptions propagate. No bare `except Exception`. No `pass` in except blocks.
- One function, one job. If a docstring needs "and", split the function.

## Testing

- Tests live in `tests/unit/` and `tests/integration/`.
- Every public function has at least one positive and one negative test.
- Test names are specifications: `test_returns_empty_list_when_no_matching_records`.
- Fixtures in `tests/conftest.py`. No test-specific database setup outside fixtures.
- Mock external services only. Never mock the database — use a test database.

## Branch + Commit

- Branch names: `feat/<ticket>-slug`, `fix/<ticket>-slug`, `chore/<ticket>-slug`.
- Conventional Commits required. Subject ≤ 72 chars. Body explains why, not what.
- AI-authored commits include trailer: `AI-Author: <tool> (<model>)`

## Hard Rules

- Never commit secrets. `.env*` is gitignored and contains placeholders only.
- Never modify migration files after merge — generate new migrations.
- Run `pre-commit run --all-files` before declaring any task done.
- Never add a dependency without verifying it exists on PyPI and is actively maintained.
- Never use `# type: ignore` without an inline comment explaining why.

## Project Structure

```
{{PROJECT_NAME}}/
  src/
    {{PACKAGE_NAME}}/
      __init__.py
      models/          # Pydantic models (domain + API)
      repositories/    # Database access layer
      services/        # Business logic
      api/             # FastAPI routers
  tests/
    unit/
    integration/
    conftest.py
  pyproject.toml
  uv.lock
```

## Where to Look

- Architecture: `docs/architecture.md`
- Testing patterns: `docs/testing.md`
- API conventions: `docs/api.md`
- Security checklist: `docs/security.md`

## Pre-commit sequence

Before declaring any task complete, run this sequence:

```bash
uv run ruff check --fix . && uv run ruff format .
uv run mypy
uv run pytest
```

All three must pass. If any fails, fix before proceeding.

<!-- Instruction budget: this file + nana identity + workflow instructions ≈ 170 lines always-loaded.
     Ceiling before instruction-following degrades: ~300 lines total across all always-loaded files.
     If agent stops following rules, audit total line count across AGENTS.md + .claude/rules/ + .github/instructions/. -->
