---
name: py-review
description: Review code changes against the 8-point AI PR checklist. Use before committing, before creating a PR, or when the user asks for a review. Also runs automatically as a Stop prompt hook.
---

Review the current diff (`git diff` for unstaged, `git diff --cached` for staged, or `git diff main...HEAD` for full branch).

Apply this 8-point checklist. Report only findings — skip points that pass.

## 1. Duplicate code

Search for similar function names and logic in the codebase before approving. AI agents tend to re-implement utilities that exist nearby rather than reusing them.

## 2. Real imports and pinned dependencies

Verify every new import references a real, maintained package. Check `uv.lock` diff — any new package must exist on PyPI. Watch for hallucinated package names (slopsquatting).

## 3. Swallowed exceptions

Flag any `except Exception: pass`, bare `except:`, or exception handlers that log but don't re-raise or return an error. Over-broad exception handling is the canonical AI code smell.

## 4. Failure-path tests

Check whether tests cover failure paths (bad input, missing data, network errors, concurrent access). If only happy-path tests exist, list the missing negative cases.

## 5. Right version of the API

Verify API usage matches the version in use:
- Pydantic: `model_config` (v2), not `class Config` (v1)
- SQLAlchemy: 2.x patterns, not 1.x implicit sessions
- Other libraries: check imports against installed version in `uv.lock`

## 6. Codebase idioms

Does the code match this project's style? Repository idioms beat textbook idioms. Check naming conventions, import style, error handling patterns.

## 7. Secrets and hardcoded paths

Look for hardcoded API keys, tokens, credentials, database URLs, file paths with `~`, or paths containing usernames. Flag any `.env` values that leaked into code.

## 8. Complexity

Flag functions longer than ~40 lines or with cyclomatic complexity that could be reduced by extracting helpers. AI agents tend to inline more than humans.

## Output format

For each finding, use this structured format:
```
[FAIL] N. Category — file:line — description + suggested fix
```
Severity levels: `[FAIL]` (must fix before merge), `[WARN]` (should fix, not blocking), `[PASS]` (only if explicitly asked for full report).

If all 8 pass: "Review clean."

## Graceful degradation

- **No git history:** Fall back to reviewing all Python files in the project. Warn: "No git diff available — reviewing full source tree."
- **No uv.lock:** Skip check 2 (dependency verification). Warn: "No lockfile found — cannot verify dependency pinning."
