---
parent: dev-plan
referenced_at: "Step 14"
---

# Plan Review Protocol

Extracted from dev-plan Step 14. Contains plan quality review mechanics — task drafting, reviewer dispatch, and verdict handling.

## Draft Tasks (Step 14.1)

Draft tasks in conversation context (do NOT write to files yet). Follow `~/.claude/skills/dev-plan/task-schema.md` enriched task schema *(Lite: simplified — description+scope+success only)*: each task needs description, TDD cycle, scope, success, size.

## Dispatch Plan Reviewer (Step 14.2)

Read `~/.claude/skills/dev-plan/plan-reviewer-prompt.md`. Launch Agent with the prompt + phase article (objective, exit criteria) + retrieved wiki articles + drafted tasks. Collect Score/Issues/Verdict. **Timeout:** 120 seconds. If subagent fails or times out: accept draft tasks without review score. Warn: `"Plan reviewer unavailable — proceeding without quality gate."`

## Handle Verdict (Step 14.3)

- Score 9-10 (accept): Proceed with tasks as-is.
- Score 6-8 (revise): Fix flagged issues in the draft, re-review once. If still ≤8, accept best version.
- Score 1-5 (reject): Surface specific CRITICAL issues. Do NOT auto-accept without acknowledging gaps.

## Presentation (Step 14.4)

Present the drafted tasks AND the reviewer's findings as a single report. Under the 2-gate ceremony model, this step is **agent-internal** — the orchestrator incorporates findings and proceeds to Step 15 without blocking on user approval. The direction gate (Step 13) already confirmed the approach; task details are an implementation concern.

Under the old 4-gate model (pre-Phase 37), this was a second user approval gate. Preserved here for reference and backward compatibility with projects using `ceremony: legacy` in config.md.
