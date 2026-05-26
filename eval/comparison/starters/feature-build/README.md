# Task Tracker CLI

Build a command-line task tracker with the following requirements:

## Commands

- `tasktracker add "description"` — Add a new task, print its ID
- `tasktracker list` — List all tasks (ID, status, description)
- `tasktracker complete <id>` — Mark a task as complete
- `tasktracker delete <id>` — Delete a task

## Requirements

- Tasks are persisted to `tasks.json` in the current directory
- Each task has: id (int, auto-increment), description (str), status ("pending" or "complete"), created_at (ISO timestamp)
- `list` shows tasks in a readable table format
- All commands exit 0 on success, non-zero on error (e.g., completing a non-existent task)
- Write pytest tests covering all commands and edge cases

## Technical Constraints

- Python 3.10+, no external dependencies beyond stdlib
- Use argparse for CLI parsing
- JSON file as the persistence layer
