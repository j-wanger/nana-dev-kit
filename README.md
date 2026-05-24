# Nana Dev Kit

End-to-end development harness for Claude Code. Installs 22 skills, 11 hooks, identity rules, and a persistent memory server. Covers the full lifecycle: scaffold → spec → plan → execute → debrief.

## Requirements

Bash, [jq](https://jqlang.github.io/jq/) 1.5+, Python 3.8+ (for memory server). macOS or Linux — hooks are bash scripts, not portable to native Windows. **Windows users:** use WSL2 (recommended) or install [Git for Windows](https://git-scm.com/downloads/win) for Git Bash hook support.

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
| 4. Enforcement | Spec enforcement, deliverable checks, memory gating, loop detection — opt-in via markers | `enforce-spec.sh`, `enforce-loop.sh`, `enforce-memory.sh`, `detect-loop.sh` |
| 5. Pre-commit | Commit-time guardrails (ruff, mypy, gitleaks, sync-rules) | `.pre-commit-config.yaml` |
| 6. CI | GitHub Actions (lint, typecheck, test, security audit) | `.github/workflows/ci.yml` |
| 7. Eval | 47-scenario harness across 4 categories (hook, skill, lifecycle, context) | `eval/corpus/`, `scripts/eval-runner.sh` |

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

For memory maintenance, use `/memory-consolidate` to identify and merge duplicate entries. This uses Claude's own intelligence via MCP tools — no external LLM sidecar required.

## Eval

```bash
make eval    # runs 47 scenarios, binary scoring, requires jq
```

Four categories: hook fidelity (31), skill artifact validation (6), lifecycle compliance (6), context injection (4). Separate from `make test` — eval benchmarks the harness, tests verify the kit.

## Memory Benchmark

The vendored memory server's retrieval quality is benchmarked against [LongMemEval-S](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned) (500 questions, 6 categories). Each question indexes ~50 conversation sessions as memory entries and measures recall@5/recall@10.

```bash
benchmark/.venv/bin/python benchmark/longmemeval.py --smoke-test  # verify setup
benchmark/.venv/bin/python benchmark/longmemeval.py --full        # full run
```

Published baselines: BM25 86.2% recall@5, hybrid 95.2% recall@5. Note: baselines use different retrieval units (chunks vs. full sessions). See `benchmark/README.md` for interpretation guide.

## Enforcement

Enforcement hooks install globally and activate per-project via a marker file:

```bash
touch .claude/enforce    # enable in current project
```

When active: `/spec` required before implementation (PreToolUse), `memory_search` required before writes (PreToolUse, via `~/.claude/enforce-memory`), deliverables checked at session end (Stop), repeated failures detected (PostToolUse).

## Per-Project Sync

`AGENTS.md` is the single source of truth. After editing: `make sync-rules`.

## Upgrading

Re-run `~/nana-dev-kit/install.sh` to update. Existing files are overwritten; `nana-personal.md` is preserved if it already exists.

## Testing

```bash
make test    # 190 tests across 5 scripts
make eval    # 47 eval scenarios (requires jq)
make report  # package inventory at docs/report.html
```
