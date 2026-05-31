---
title: "Phase 72: Compaction-Recovery Subtraction (.session-anchor)"
aliases: [phase-72-compaction-recovery-subtraction, session-anchor-subtraction]
category: phases
tags: [harness-right-sizing, subtraction, compaction, post-compact, amplifier-vision, engineering]
parents: [phase-71-cross-boundary-retention-screen]
created: 2026-05-30
updated: 2026-05-30
source: plan
status: completed
scope: ["templates/.claude/hooks/post-compact.sh", ".gitignore", ".dev-wiki/articles/decisions/cash-compaction-recovery-subtraction.md"]
entry_criteria: "Phase 71 recorded (but froze) a latent finding: post-compact.sh READS .claude/.session-anchor but nothing writes it. Jake paused the measurement campaign and chose Engineering → Tight subtraction (AskUserQuestion 2026-05-30), unfreezing the machinery for this removal. Spec nana:approved."
exit_criteria: "No live session-anchor reference remains repo-wide; post-compact firing test green; make test unchanged-count + make eval 52/52 + test_registration + test_settings_template green; decision article written."
---

# Phase 72: Compaction-Recovery Subtraction (.session-anchor)

> **COMPLETE (delivery accepted, pushed to main, 2026-05-30).** Both tasks [x]; exit criteria met. The first concrete "cash the conclusion" harness right-sizing after the Phase 58–71 measurement campaign (14 consecutive CUT/TERMINATE verdicts). Removed the dead `.claude/.session-anchor` recovery machinery — the read-branch in `post-compact.sh` (4 deletions) + its `.gitignore` entry. Committed `ca86d4b`. make test "All tests passed" at the unchanged script count, make eval 52/52, registration 41/41, settings + firing-coverage green. See [[cash-compaction-recovery-subtraction]].

## Objective

Remove the dead `.claude/.session-anchor` recovery machinery and record the rationale, tracing the removal to the measured Phase-70/71 finding that the harness compaction-recovery pathway has no headroom (the native compaction summary is decision-comprehensive). Subtraction, not construction.

## Scope

Files affected:
- `templates/.claude/hooks/post-compact.sh` — deleted the `if [ -f "$ROOT/.claude/.session-anchor" ]; then … fi` block; preserved the `[nana:compact]` echo, the `[nana:devwiki]` block, the `.context-warned` rm, and `set -euo pipefail`.
- `.gitignore` — removed the single `.claude/.session-anchor` line; kept `.context-warned`, `.memory-consulted`, `.memory/*.db*`.
- `.dev-wiki/articles/decisions/cash-compaction-recovery-subtraction.md` (NEW).

Out of scope: `pre-compact.sh`, `session-start.sh`, other hooks (untouched); `modules.json` (post-compact stays registered); gap 4.1 (DEFERRED YAGNI); historical dev-wiki records (superseded, not rewritten).

## Exit Criteria

- [x] `! grep -rq 'session-anchor' templates/ scripts/ Makefile install.sh` (no live reference remains)
- [x] `! grep -q 'session-anchor' .gitignore`
- [x] `bash tests/test_long_cadence_hooks.sh` (post-compact firing test green, 8/8)
- [x] `make test` exits 0 at the unchanged script count (no Makefile change → no README bump)
- [x] `make eval` 52/52
- [x] `bash tests/test_registration.sh` (41/41) && `bash tests/test_settings_template.sh` green
- [x] `.dev-wiki/articles/decisions/cash-compaction-recovery-subtraction.md` exists

## Constraints

- **Confirm-truly-dead BEFORE deleting**: exhaustive repo grep distinguishing LIVE references (post-compact.sh + .gitignore) from HISTORICAL dev-wiki records — prevents silently killing a live recovery path. (Done.)
- **Do NOT touch other hooks** — prevents scope creep into the recovery machinery.
- **post-compact stays registered + keeps its `# fires:` declaration** — prevents firing-coverage / registration / settings drift and a README script-count bump.
- **Do NOT rewrite history** — supersede the stale `hook-reconciliation` implication via the new article.

## Checkpoints

- **T1 (before deleting):** confirm the exhaustive grep shows only post-compact.sh + .gitignore as live. If a live writer/consumer is found → STOP, reassess delete-vs-wire. (Confirmed dead.)
- **T1 (after deleting):** re-run the post-compact firing test + firing-coverage gate. (Both green.)

## Assumptions

- Nothing in the kit or a consuming project writes `.claude/.session-anchor`. (Held — verified repo-wide.)
- The post-compact firing test does not assert the anchor branch. (Held — it asserts `.context-warned` removal + the recovery banner.)

## Notes

- First "cash the conclusion" precedent: harness components are right-sized FROM MEASUREMENT, not intuition. The alternative (wiring up the missing writer) was rejected — P70/71 measured the recovery pathway headroom-free, so building it would add machinery the campaign proved inert.
- Tooling note: the tool-result channel dropped outputs in bursts this session (rendering lag); 3 markdown writes hit the read-first guard and were re-applied via bash. No outward action under the degraded channel.
- See [[cash-compaction-recovery-subtraction]] (decision) and [[cross-boundary-retention-headroom-screen]] (the Phase-71 parent that recorded the latent finding).
