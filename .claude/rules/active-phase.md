# Active Phase Context

Phase: 80 — Assumption-Surfacer Completeness Screen
Status: COMPLETE (6/6 tasks) — `^PROGRAM-VERDICT: INSTRUMENT-DEAD`; make test green; delivery gate PENDING.

Result: pivoted (post-spike) to the SILENT class via the project's REAL silent failures (mcp-cwd,
line-cap, cascade), not synthetic plants. T1 GATE → GO; prereg `86d8584` BEFORE runs, ancestor-guarded.
The 50-run screen (5 fixtures × 2 conditions × n5, NO-LLM scoring) returned INSTRUMENT-DEAD: a CONTROL
FAILED — the workflow subagents ran INSIDE nana-dev-kit and inherited always-loaded working-knowledge,
which documents all 3 fixtures' buried assumptions; SURFACER leaked them 4/5,5/5,5/5 on real cases vs 0/5
on the 2 invented (NAIVE clean ~0/5). The headline SURFACER>NAIVE is a leak artifact — the amplifier-null
caught in the act (5th null). Clean signal points DEGENERATE (NAIVE recovered 3/4 by reasoning; silent
failures were silent because nobody ASKED). FORWARD (Phase 81): ship the SIMPLEST gate (naive cost-sorted
surfacer + accept/reject/don't-know + A3 ledger detect-after + all-accept block), NOT the scope-anchored
machinery. Residual (parked): accretion/budget class unmeasured — needs a CLEAN consuming-project context.

Objective: EARN the right to build the assumption-approval gate. Jake's live A2 reject ("can't trust the
agent-CHOSEN assumption set; solve set-completeness first") made Phase 80 a SCREEN, not a build.

Scope (repo-only, NOT wired into install.sh/Makefile/make test/make eval):
- `eval/assumption-screen/` — spike (T1 GATE), pre-registration + `.prereg-commit`, surfacer.md +
  coverage-check.sh, fixtures (3 real silent + cost-sort-adversarial + negative) + checks, check.sh
  (cloned from anchor-screen, NO LLM, `--selftest`), runs/ (50), verdicts/summary.md, screen-record.md.
- UNTOUCHED: dev-plan SKILL.md, any ledger, the all-accept block (all Phase 81).

Key constraints:
- T1 is a HARD GATE (INSTRUMENT-DEAD stops cheap). Prereg committed BEFORE runs, ancestor-guarded.
- NO LLM in the scoring path. Cost-sort-adversarial control mandatory. Amplifier program closed — NEW line.
- Cannot measure assumption-surfacing INSIDE the kit (always-loaded working-knowledge leaks the answers).

Tasks (all [x]): T1 spike (GATE→GO) → T2 prereg → T3 surfacer spec → T4 fixtures + check.sh → T5 50-run
scored → T6 screen-record + `^PROGRAM-VERDICT`.

Decision: [[assumption-surfacer-completeness-screen]] (high). Abort rule: if blocked >3 attempts, mark
[blocked] + ask user skip/abort (T1 INSTRUMENT-DEAD is a valid cheap terminal, not a block).

Gates:
- [x] Direction confirmed by user (revised spike-first design approved 2026-06-09 — "yes lets go")
- [ ] Delivery accepted (post-implementation report — orchestrator flips at D3 after the commit lands)
