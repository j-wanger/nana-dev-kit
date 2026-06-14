---
title: "Codebase Snapshot (Phase 91 ready for completion)"
aliases: []
category: status
tags: [snapshot, phase-91, memory, enforce-assumption-gate]
parents: [phase-91-memory-e2e-and-gate-forcing-function]
created: 2026-06-14
updated: 2026-06-14
source: debrief
---

# Codebase Snapshot — 2026-06-14

## Metrics
- Test suite: `make test` ALL-PASS (per substance) — 28 scripts (Phase 91 added test_enforce_assumption_gate.sh, 7 firing cases)
- Eval: `make eval` 50/50 (denominator unchanged — Phase 91 added no eval scenarios)
- Hooks: 18 template .sh (+3 session-start.d); modules.json hooks array = 17 project-scoped + 1 global (context-size-check). +enforce-assumption-gate.sh (Phase 91, PreToolUse Write|Edit|MultiEdit)
- MCP: modules.json memory mcp block gained `env: {PYTHONPATH: ~/.claude}` (register-settings.py cmd_mcp now emits env); landed in ~/.claude/settings.json + ~/.claude.json
- MANIFEST: 4 checksums regenerated (the new hook + edited dev-plan companions)
- Assumption-ledger: Phase-91 block — A1/A2/A3 held, A4 open (deferred don't-know); `--revisit 91` clean, `--schema` valid

## Structure Changes (Phase 91)
- NEW `templates/.claude/hooks/enforce-assumption-gate.sh` + `~/.claude/hooks/` (18th project hook) — blocks impl writes when the active phase has no valid assumption-ledger block (`check-assumption-ledger.sh --gate` ONLY; whole-file `--schema` false-locks properly-gated projects with prior-block drift)
- NEW `tests/test_enforce_assumption_gate.sh` (7 firing cases)
- `scripts/register-settings.py` — cmd_mcp emits an `env` dict (was command/args/cwd only)
- `modules.json` — hook entry + mcp `env` {PYTHONPATH}
- `templates/.claude/skills/dev-plan/{SKILL.md,assumption-gate.md}` — HARD-GATE names enforce-assumption-gate.sh as the enforcement
- `.claude/rules/working-knowledge.md` — gate-now-hook-bound supersession note
- Consumer propagation (USER OVERRIDE): 6 consumers' .gitignore (.memory/), 5 consumers' .claude/hooks+scripts+settings, ~/.claude.json, py-init/ts-init scaffold — gate armed in kit + aml-substrate, staged in 4, signal-watch deferred

## Test Status
make test: ALL PASS (per substance). make eval: 50/50. Review gate 4/10 reject (caught the missing register-settings env support) → revised → 8/10.

## Recent Commits
- 9d8244d Record assumption-gate hardening + session follow-ons (debrief)
- 9309fe0 Harden dev-plan assumption-gate: drop direction-choices masquerading as assumptions (Phase-90 follow-on)
- 09f2a71 Phase 91 setup: renumber memory-prune 91->92; point next-action at install re-sync + drift-detection phase
- f05280d Phase 90 — delivery accepted; flip delivery gate
- f2d3658 Phase 90 — Fable-5 Distillation
(Phase-91 implementation + debrief artifacts are in the working tree, pending the delivery commit.)
