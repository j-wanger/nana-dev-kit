# Task: Fix the Unit Converter Bug

## Starter Integrity
SHA256 (composite): `05027c278f56fa1c6bf4849f53a1db650a60b8e49f6090f9a76a39945107fb0e`
Verify: `find eval/comparison/starters/bug-fix -type f | sort | xargs shasum -a 256 | shasum -a 256`

## Prompt

You are working in a Python unit conversion library. Some tests are failing due to a bug in the source code.

1. Run the tests to see which are failing
2. Read the source code to find the bug
3. Fix the bug so all tests pass
4. Do NOT modify the tests — they define the correct behavior

## Acceptance Criteria

1. All tests pass: `PYTHONPATH=src python -m pytest tests/ -v` shows 0 failures
2. Only source files modified (not test files)
3. The fix is minimal — no unnecessary refactoring

## Time Budget

Expected completion: 5-15 minutes for an experienced agent.
