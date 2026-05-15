---
applyTo: "**/*.py"
---

# Python Workflow Procedures

These procedures encode the verification workflows for this project. Follow them when modifying Python code.

## After writing or modifying code

Run this sequence. All three must pass before declaring the task complete:

```bash
uv run ruff check --fix . && uv run ruff format .
uv run mypy src/
uv run pytest -x --cov=src --cov-fail-under=85
```

If any step fails: fix the issue, re-run from that step. Do not skip to the next.

## Before committing

Review your changes against this checklist. Report only failures:

1. **Duplicates** — Search for similar functions. Don't re-implement what exists.
2. **Real imports** — Every new package must exist in `uv.lock`. No hallucinated packages.
3. **Exception handling** — No bare `except Exception: pass`. Errors must propagate or be handled meaningfully.
4. **Failure tests** — Every new public function needs at least one negative test.
5. **API version** — Use Pydantic v2 (`model_config`), SQLAlchemy 2.x patterns.
6. **Secrets** — No hardcoded keys, tokens, or file paths with `~`.

## Test quality

- Test names are specifications: `test_returns_empty_list_when_no_records`
- At least one positive and one negative test per public function
- Fixtures in `conftest.py`, not duplicated across files
- Mock external services only — never mock the database
