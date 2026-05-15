---
name: py-test
description: Run the full test suite with coverage and report failures concisely. Use whenever the user asks to run tests, after writing code, or when verifying a change.
---

Run: `uv run pytest`

Pytest reads `testpaths`, `addopts`, and coverage config from `pyproject.toml` — do not pass path-specific flags here.

## On failure

1. Show the failure summary only — not the full traceback unless asked.
2. Read the failing test and the code under test.
3. Propose a fix for the **first** failure. Don't fix multiple at once.
4. Apply the fix, then re-run `uv run pytest -x` (drop coverage flags for speed).
5. Once green, re-run with full coverage flags to confirm threshold.

## On coverage drop

If coverage drops below 85%, show the uncovered lines from `--cov-report=term-missing`.
Identify which functions lack tests. Suggest concrete test cases — prioritize:
- Failure/edge-case paths (bad input, missing data, empty collections)
- Error handling branches
- Boundary conditions

Do NOT write tests that only confirm the happy path the implementation already handles.

## Test quality checks

After tests pass, verify:
- Every test name reads as a specification (`test_returns_empty_when_no_records`)
- At least one negative test per public function
- No bare `assert True` or `assert result is not None` without checking the actual value
- Fixtures are in `conftest.py`, not duplicated across test files
- If you wrote both the test and the implementation, verify the test would fail with a plausible wrong implementation — not just that it passes with the current one

## Graceful degradation

- **No uv:** Fall back to `python -m pytest` (warn: "uv not found, using system Python")
- **No pytest:** STOP — testing is non-negotiable. Tell the user to install: `uv add --dev pytest pytest-cov`
- **No coverage plugin:** Run `pytest -x` without coverage flags. Warn about missing threshold enforcement.
