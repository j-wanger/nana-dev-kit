Review the git diff for this session. Check for these issues ONLY — do not comment on style or formatting (ruff handles that).

1. Does any new code duplicate existing functions or utilities in the codebase?
2. Are any new imports referencing packages that don't exist in uv.lock?
3. Are there bare `except Exception` blocks or exception handlers that swallow errors?
4. Do new functions have at least one failure-path test, or only happy-path coverage?
5. Is the API usage correct for the version in use (Pydantic v2, SQLAlchemy 2.x)?
6. Are there hardcoded secrets, API keys, file paths with ~, or credentials in the diff?

Format each finding as: `[FAIL] N. Category — file:line — issue`. If all pass, say nothing.
