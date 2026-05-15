---
name: py-lint
description: Run linting, formatting, and type checking. Use after writing or modifying Python code, before committing, or when the user asks to lint.
---

Run this sequence — all three must pass:

```bash
uv run ruff check --fix .
uv run ruff format .
uv run mypy
```

## Ruff (lint + format)

- `ruff check --fix` auto-fixes what it can. Show remaining violations concisely.
- `ruff format` enforces consistent style. No manual intervention needed.
- If ruff finds issues it can't auto-fix, show the violation with a one-line fix suggestion.
- Common AI-authored issues to watch for: unused imports (F401), undefined names (F821), mutable default args (B006), broad exception handling (E722).

## mypy (strict types)

- Run with `--strict` (configured in pyproject.toml).
- Show errors grouped by file, one line each.
- For each error, propose the fix — don't just report the type mismatch.
- Common AI-authored type issues: missing `Optional` on nullable returns, wrong generic params, Pydantic v1 vs v2 type annotations.
- Never add `# type: ignore` without an inline comment explaining why.

## If everything passes

Report "Lint clean" and move on. Don't enumerate what passed.

## Graceful degradation

- **No uv:** Fall back to `python -m ruff` / `python -m mypy` (warn: "uv not found, using system Python")
- **No ruff:** STOP — formatting is non-negotiable. Tell the user to install: `uv add --dev ruff`
- **No mypy:** Skip type checking. Warn: "mypy not installed — type errors will only be caught in CI. Install: `uv add --dev mypy`"
