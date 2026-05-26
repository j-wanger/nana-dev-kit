# Harness Effectiveness Validation — Methodology

## Overview

A controlled clean-room comparison measuring whether nana-dev-kit improves development outcomes when used with Claude Code. Three conditions, two tasks, parallel execution.

## Tasks

### Feature Build (multi-step, ~30-60 min)
Build a Python CLI task tracker with add/list/complete/delete commands, JSON persistence, and pytest tests. Exercises: project scaffolding, multi-file implementation, test writing, CLI design.

### Bug Fix (short, ~5-15 min)
Find and fix a pre-seeded bug in a unit conversion library. Exercises: code reading, debugging, minimal intervention. Tests exist and define correct behavior.

Both tasks are Python to exercise the harness's Python-specific skills (py-lint, py-review, py-test, py-init).

## Conditions

| Condition | Label | What's present | What's absent |
|-----------|-------|---------------|---------------|
| A | Bare baseline | Claude Code defaults | All harness artifacts |
| B | Context injection | .claude/rules/ (nana-soul.md, file-lifecycle.md, nana-personal.md), AGENTS.md | Hooks, skills, memory, enforcement |
| C | Full harness | Everything from install.sh | Nothing — full installation |

### Pairwise comparisons

- **A vs B**: Value of context injection (rules, cognitive identity, workflow guidance)
- **A vs C**: Value of full harness (context + hooks + skills + memory)
- **B vs C**: Marginal value of active features (hooks, enforcement, memory) beyond context

## Metrics

### Primary (quality)
1. **Test pass rate**: `test_pass / test_total` — does the code work?
2. **Test count**: How many tests were written? (feature-build only)
3. **Ruff findings**: Lint violations (if ruff available)
4. **Mypy errors**: Type checking errors (if mypy available)

### Secondary (efficiency)
5. **Commits**: Number of work commits (excluding scaffold)
6. **Python lines**: Total lines of Python code produced
7. **Python files**: Number of .py files created
8. **Completion**: Did the agent finish the task? (binary)

### Tertiary (friction — condition C only)
9. **Hook events**: Total hook invocations
10. **Hook blocks**: Times a hook blocked an action (exit code 2)

## Controls

- **Model**: Same Claude Code version and model for all conditions, same day
- **Task integrity**: SHA256 checksums of task definition files verified by collect-metrics.sh; any modification invalidates the trial
- **Starter integrity**: Same starter codebase copied to each condition's repo
- **Isolation**: Each condition runs in a separate directory with its own git history
- **Execution**: Conditions A and B run as parallel Agent subagents (identical tool access, no learning effect); condition C runs as a separate manual Claude Code session
- **No human guidance**: Subagent conditions receive only the task prompt — no interactive clarification

## Scoring Rubric

### Feature Build
| Metric | Excellent | Good | Poor |
|--------|-----------|------|------|
| Tests pass rate | 100% | ≥80% | <80% |
| Test count | ≥10 | 5-9 | <5 |
| Ruff findings | 0 | 1-5 | >5 |
| Completion | Yes | Partial | No |

### Bug Fix
| Metric | Excellent | Good | Poor |
|--------|-----------|------|------|
| Tests pass rate | 100% | ≥90% | <90% |
| Fix minimal | ≤5 lines changed | ≤15 lines | >15 lines |
| Completion | Yes | — | No |

### Composite Score
No weighted composite — report each metric separately. Qualitative comparison narrative supplements the numbers.

## Limitations

### Self-grading bias
The same LLM (Claude) that builds the starter code also solves the tasks. The bug-fix task's tests define correctness independently, but the feature-build task relies on the agent writing its own tests — inflating apparent pass rates. Mitigation: compare test COUNT and test QUALITY (manual review) alongside pass rate.

### Single-run variance
N=1 per condition. Any observed difference could be stochastic — LLM outputs vary between runs. Results are directional, not statistically significant. Mitigation: report qualitative observations (what the harness caught or prevented) alongside quantitative metrics.

### Subagent capability gap
Agent subagents (conditions A and B) have limited tool access compared to full Claude Code sessions. They cannot use Skill tool, MCP tools, or hooks. The A-vs-B comparison is clean (identical tool access), but A-vs-C comparisons are confounded by this capability gap.

### Task domain bias
Both tasks are Python — the harness's strongest language. Results may not generalize to TypeScript, Rust, or other languages where the harness has fewer skills.

### Operator knowledge
The person designing the tasks has deep knowledge of the harness. Task design may unconsciously favor the harness condition. Mitigation: task definitions are frozen with SHA256 checksums before trials.
