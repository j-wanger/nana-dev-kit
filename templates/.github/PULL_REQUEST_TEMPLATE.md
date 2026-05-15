## Summary

<!-- What does this PR do? 1-3 sentences. -->

## AI Authorship Disclosure

- [ ] This PR was authored or substantially assisted by an AI agent
- **Tool:** <!-- e.g., Claude Code, GitHub Copilot, Cursor -->
- **Model:** <!-- e.g., Claude Opus 4.6, GPT-4o -->
- **Spec:** <!-- Link to spec document if applicable, e.g., docs/specs/feature-name.md -->

## Test Plan

- [ ] Unit tests pass (`uv run pytest -x --cov=src --cov-fail-under=85`)
- [ ] Lint clean (`uv run ruff check . && uv run ruff format --check .`)
- [ ] Types clean (`uv run mypy src/`)
- [ ] No new dependencies without reviewer approval
- [ ] Negative/edge-case tests included for new public functions

## Checklist

- [ ] No hardcoded secrets or credentials
- [ ] No `except Exception: pass` or swallowed errors
- [ ] New code doesn't duplicate existing utilities
- [ ] API usage matches installed library versions
