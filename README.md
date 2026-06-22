# Nana Dev Kit

End-to-end development harness for Claude Code. Installs 25 skills, 18 hooks (17 project-scoped + 1 global), identity rules, and a persistent memory server. Covers the full lifecycle: scaffold → spec → plan → execute → debrief.

## Requirements

Bash, [jq](https://jqlang.github.io/jq/) 1.5+, Python 3.8+ (for memory server). Node ≥20 + pnpm only if you use `/ts-init` (TypeScript scaffolding). macOS or Linux — hooks are bash scripts, not portable to native Windows. **Windows users:** use WSL2 (recommended) or install [Git for Windows](https://git-scm.com/downloads/win) for Git Bash hook support.

## Quick Start

```bash
git clone https://github.com/j-wanger/nana-dev-kit.git ~/nana-dev-kit
~/nana-dev-kit/install.sh          # one-time, installs everything
```

Then in any project:

```
/nana-init    # full bootstrap: language scaffold + dev-wiki + optional knowledge wiki
/py-init      # scaffold Python toolchain only
/ts-init      # scaffold TypeScript toolchain only (pnpm/Biome/Vitest/tsc)
/dev-init     # bootstrap dev-wiki lifecycle tracking only
```

### Installer Flags

| Flag | What it installs |
|------|-----------------|
| `--all` (default) | Everything: identity, memory, Python + TypeScript skills, lifecycle, knowledge wiki, hooks |
| `--core-only` | Identity rules + memory server only |
| `--no-python` | Everything except Python-specific skills (py-init, py-lint, py-test, py-review) |
| `--no-typescript` | Everything except `/ts-init` |
| `--project-local` | All 17 project-scoped hooks from modules.json into `./.claude/hooks/`. No global writes. |
| `--dry-run` | Preview what would be installed |
| `--status` | Show runtime inventory (skills, hooks, rules, memory venv, enforcement markers) |

## The 7 Layers

| Layer | What | Key Files |
|-------|------|-----------|
| 1. Instructions | Agent config synced to CLAUDE.md, Copilot, Cursor, Gemini | `AGENTS.md`, `scripts/sync-rules.sh` |
| 2. Identity | Development personality and technical posture | `.claude/rules/nana-soul.md` |
| 3. Hooks | 11 lifecycle hooks (session-start, pre-compact, audit, format, secrets, review, test gate) | `.claude/hooks/`, `.claude/settings.json` |
| 4. Enforcement | Spec enforcement, deliverable checks, memory gating, loop detection — opt-in via markers | `enforce-spec.sh`, `enforce-loop.sh`, `enforce-memory.sh`, `detect-loop.sh` |
| 5. Pre-commit | Commit-time guardrails (ruff, mypy, gitleaks, sync-rules) | `.pre-commit-config.yaml` |
| 6. CI | GitHub Actions (lint, typecheck, test, security audit) | `.github/workflows/ci.yml` |
| 7. Eval | 50-scenario harness across 4 categories (hook, skill, lifecycle, context) | `eval/corpus/`, `scripts/eval-runner.sh` |

## Skills by Module

**Python Quality** — `/py-init`, `/py-lint`, `/py-test`, `/py-review`
Scaffold, lint (ruff + mypy), test (pytest + coverage), and review (8-point PR checklist).

**TypeScript Quality** — `/ts-init`
Scaffold the Nana 5-layer TS dev harness: pnpm + Biome (lint + format) + tsc (typecheck) + Vitest (test). Two modes: new-project scaffold or existing-project retrofit via 10-dimension scanner.

**Development Lifecycle** — `/dev-init`, `/dev-plan`, `/dev-debrief`, `/dev-check`, `/dev-scan`, `/spec`
Phase-based planning with TDD task schemas, automated debriefs, spec contracts with adversarial constraints and two-tier review gates.

**Knowledge Wiki** — `/wiki-init`, `/wiki-add`, `/wiki-query`, `/wiki-absorb`, `/wiki-bootstrap`, `/wiki-health`, `/wiki-reorg`, `/wiki-index`, `/wiki-registry`
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
make eval    # runs 52 scenarios, binary scoring, requires jq
```

Four categories: hook fidelity (32), skill artifact validation (6), lifecycle compliance (6), context injection (6). Separate from `make test` — eval benchmarks the harness, tests verify the kit.

## Memory Benchmark

The memory server's retrieval quality is benchmarked against [LongMemEval-S](https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned) (500 questions, 6 categories).

| Mode | recall@5 | recall@10 |
|------|----------|-----------|
| FTS5 (session-level, 500 questions) | 91.0% | 95.2% |
| Hybrid RRF (turn-level, 40-question diagnostic) | +27.6% lift on failures | no degradation on easy |

Turn-level indexing (each conversation turn as a separate entry) produces high-quality embeddings that lift recall on hard multi-session questions without degrading easy ones. See `benchmark/README.md` for the full analysis.

## Enforcement

Enforcement hooks install per-project (via `--project-local` or `/py-init`/`/ts-init` scaffolding) and activate via a marker file:

```bash
touch .claude/enforce    # enable in current project
```

When active: `/spec` required before implementation (PreToolUse), `memory_search` required before writes (PreToolUse, via `~/.claude/enforce-memory`), deliverables checked at session end (Stop), repeated failures detected (PostToolUse).

## Per-Project Sync

`AGENTS.md` is the single source of truth. After editing: `make sync-rules`.

## Upgrading

Re-run `~/nana-dev-kit/install.sh` to refresh the global install (`nana-personal.md` preserved). To re-sync a **consuming project** to the current kit, run `install.sh --update` from its root: it ADD/UPDATEs hooks, dedupes registrations by basename, and deregisters cut hooks (timestamped backup → survivor smoke → revert-on-failure). Idempotent; arming is decoupled (`.claude/enforce` untouched unless `--arm`); non-kit settings, `.dev-wiki`, and `.gitignore` are preserved. Preview with `--update --dry-run`; report drift read-only with `scripts/check-install-drift.sh --consumer .`. A consumer that registered its kit hooks in the project-scope `.claude/settings.json` (rather than gitignored `settings.local.json`) is first consolidated onto the canonical local topology with `install.sh --migrate-to-local` (relocates kit regs to `settings.local.json`, deregisters kit/cut hooks from `settings.json`; both settings files backed up → survivor smoke → revert), then `--update` refreshes it — so each hook is registered in exactly one file (no DRQ-1 cross-file double-fire).

## Testing

```bash
make test    # ~550 tests across 30 scripts
make eval    # 52 eval scenarios (requires jq)
make report  # package inventory at docs/report.html
```
