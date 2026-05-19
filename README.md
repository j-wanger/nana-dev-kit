# Nana Dev Kit

Scaffolds a 5-layer Python development harness into new or existing projects. One install, then `/py-init` in any Python project to get linting, type checking, tests, hooks, and CI — configured and wired together.

## Install

```bash
git clone https://github.com/YOUR_USER/nana-dev-kit.git ~/nana-dev-kit
~/nana-dev-kit/install.sh
```

This copies the `/py-init` skill, Nana identity rule, and memory MCP server to `~/.claude/`. Memory deps are auto-installed in an isolated venv. Run once per machine.

## Upgrading

Re-run `~/nana-dev-kit/install.sh` to update. It overwrites existing files with the latest versions.

## Usage

In any Python project directory, open Claude Code and run:

```
/py-init
```

**New projects** get the full scaffold: `pyproject.toml`, pre-commit hooks, CI workflow, agent instructions, and Claude Code hooks.

**Existing projects** go through a feasibility scan, then an approval-gated transform that upgrades your toolchain in place.

After scaffolding:

- `/py-lint` — ruff + mypy
- `/py-test` — pytest with coverage
- `/py-review` — 8-point PR checklist

## The 5 Layers

| Layer | What | Where |
|-------|------|-------|
| 1. Instructions | Agent-surface config (synced to CLAUDE.md, Copilot, Cursor, Gemini) | `AGENTS.md`, `scripts/sync-rules.sh` |
| 2. Identity | Development personality and technical posture | `.claude/rules/nana-soul.md` |
| 3. Hooks | Claude Code lifecycle hooks (format, block, audit, review, test gate) | `.claude/hooks/`, `.claude/settings.json` |
| 4. Pre-commit | Commit-time guardrails (ruff, mypy, gitleaks, sync-rules) | `.pre-commit-config.yaml` |
| 5. CI | GitHub Actions (lint, typecheck, test, security audit) | `.github/workflows/ci.yml` |

## Memory & Dev-Wiki

The kit includes a persistent memory MCP server (registered globally by `install.sh`). Each project can store decisions, conventions, and context in `.memory/` — available to every Claude Code session via the session-start hook.

After scaffolding, run `/dev-init` to set up dev-wiki lifecycle tracking (phases, tasks, decisions). The session-start hook loads dev-wiki state and memory snapshots automatically.

## Per-Project Sync

AGENTS.md is the single source of truth. After editing: `make sync-rules`.

## Testing

Run `make test` for the automated suite. Run `make report` for a package inventory at `docs/report.html`. Run `make workflow` for a detailed workflow breakdown at `docs/workflow.html`. See [self-test.md](self-test.md) for manual smoke tests.
