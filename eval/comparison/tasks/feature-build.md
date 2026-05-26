# Task: Build a CLI Task Tracker

## Starter Integrity
SHA256 (composite): `324035c789637b00dc561303fa7f60aa55c6d731820e416b9ee00d76035f087b`
Verify: `find eval/comparison/starters/feature-build -type f | sort | xargs shasum -a 256 | shasum -a 256`

## Prompt

You are working in a Python project scaffolded with pyproject.toml, an empty src/tasktracker/ package, and an empty tests/ directory. Read the README.md for full requirements.

Build a CLI task tracker called `tasktracker` with these commands:

- `tasktracker add "description"` — Add a new task, print its ID
- `tasktracker list` — List all tasks (ID, status, description) in a readable table
- `tasktracker complete <id>` — Mark a task as complete
- `tasktracker delete <id>` — Delete a task

Requirements:
- Tasks persist to `tasks.json` in the current directory
- Each task has: id (int, auto-increment), description (str), status ("pending" or "complete"), created_at (ISO timestamp)
- All commands exit 0 on success, non-zero on error
- Python 3.10+, no external dependencies beyond stdlib
- Use argparse for CLI parsing
- Write comprehensive pytest tests covering all commands and edge cases

## Acceptance Criteria

1. `python -m pytest tests/` passes with all tests green
2. `python -m tasktracker add "test"` creates a tasks.json and prints an ID
3. `python -m tasktracker list` shows the added task
4. `python -m tasktracker complete 1` marks it as complete
5. `python -m tasktracker delete 1` removes it
6. Error cases handled: complete/delete non-existent ID, list when no tasks.json

## Time Budget

Expected completion: 30-60 minutes for an experienced agent.
