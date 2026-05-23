# Nana Dev Kit

End-to-end development harness for Claude Code. Installs 22 skills, 11 hooks, identity rules, and a persistent memory server. Covers the full lifecycle: scaffold → spec → plan → execute → debrief.

## Quick Start

```bash
git clone https://github.com/j-wanger/nana-dev-kit.git ~/nana-dev-kit
~/nana-dev-kit/install.sh          # one-time, installs everything
```

Then in any project:

```
/dev-init     # bootstrap dev-wiki lifecycle tracking
/py-init      # scaffold Python toolchain (or use /dev-init alone for non-Python)
```

### Installer Flags

| Flag | What it installs |
|------|-----------------|
| `--all` (default) | Everything: identity, memory, Python skills, lifecycle, knowledge wiki, hooks |
| `--core-only` | Identity rules + memory server only |
| `--no-python` | Everything except Python-specific skills (py-init, py-lint, py-test, py-review) |
| `--dry-run` | Preview what would be installed |

## The 7 Layers

| Layer | What | Key Files |
|-------|------|-----------|
| 1. Instructions | Agent config synced to CLAUDE.md, Copilot, Cursor, Gemini | `AGENTS.md`, `scripts/sync-rules.sh` |
| 2. Identity | Development personality and technical posture | `.claude/rules/nana-soul.md` |
| 3. Hooks | 11 lifecycle hooks (session-start, pre-compact, audit, format, secrets, review, test gate) | `.claude/hooks/`, `.claude/settings.json` |
| 4. Enforcement | Spec enforcement, deliverable checks, loop detection — opt-in via `~/.claude/enforce` | `enforce-spec.sh`, `enforce-loop.sh`, `detect-loop.sh` |
| 5. Pre-commit | Commit-time guardrails (ruff, mypy, gitleaks, sync-rules) | `.pre-commit-config.yaml` |
| 6. CI | GitHub Actions (lint, typecheck, test, security audit) | `.github/workflows/ci.yml` |
| 7. Eval | 38-scenario harness across 4 categories (hook, skill, lifecycle, context) | `eval/corpus/`, `scripts/eval-runner.sh` |

## Skills by Module

**Python Quality** — `/py-init`, `/py-lint`, `/py-test`, `/py-review`
Scaffold, lint (ruff + mypy), test (pytest + coverage), and review (8-point PR checklist).

**Development Lifecycle** — `/dev-init`, `/dev-plan`, `/dev-debrief`, `/dev-check`, `/dev-scan`, `/spec`
Phase-based planning with TDD task schemas, automated debriefs, spec contracts with adversarial constraints and two-tier review gates.

**Knowledge Wiki** — `/wiki-init`, `/wiki-add`, `/wiki-query`, `/wiki-absorb`, `/wiki-bootstrap`, `/wiki-health`, `/wiki-reorg`, `/wiki-consolidate`, `/wiki-index`, `/wiki-registry`
Project knowledge base with FTS5 search, episodic consolidation, and cross-wiki retrieval.

## Memory & Wiki Integration

The kit includes a persistent memory MCP server (registered globally by `install.sh`). Three bridge channels connect memory and wiki:

- **dev-plan → memory**: key phase decisions auto-stored after planning
- **spec → memory**: spec decisions stored for cross-session recall
- **memory → wiki-query**: memory results included in wiki query context

After scaffolding, run `/dev-init` to set up dev-wiki lifecycle tracking (phases, tasks, decisions). The session-start hook loads dev-wiki state, memory guidance, and enforcement status automatically.

## Eval

```bash
make eval    # runs 38 scenarios, binary scoring, requires jq
```

Four categories: hook fidelity (23), skill artifact validation (6), lifecycle compliance (5), context injection (4). Separate from `make test` — eval benchmarks the harness, tests verify the kit.

## Enforcement

Enforcement hooks install globally and activate per-project via a marker file:

```bash
touch .claude/enforce    # enable in current project
```

When active: `/spec` required before implementation (PreToolUse), deliverables checked at session end (Stop), repeated failures detected (PostToolUse).

## Per-Project Sync

`AGENTS.md` is the single source of truth. After editing: `make sync-rules`.

## Upgrading

Re-run `~/nana-dev-kit/install.sh` to update. Existing files are overwritten; `nana-personal.md` is preserved if it already exists.

## Testing

```bash
make test    # 133 tests across 6 scripts
make eval    # 38 eval scenarios (requires jq)
make report  # package inventory at docs/report.html
```
