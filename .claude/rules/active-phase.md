# Active Phase Context

Phase: 60 - Harness Activation Residuals
Status: COMPLETED (3/3 tasks; 2/2 gates; review 9/10 accept; delivery accepted + committed). Closed the Phase 57+ harness-activation roadmap (Fixes 1–5 all done). Next: /dev-plan for Phase 61.
Objective: Two deterministic residual fixes, each test-backed:
  - Fix 3: trim templates/AGENTS.md for instruction-budget + salience (dedup the doubled lint/type/test triplet, lead with Hard Rules, codify the line cap as a test assertion).
  - Fix 5: emit a "run /nana-init" nudge from cognitive-readiness.sh when .dev-wiki/ is missing (verify firing, not presence).

Scope: templates/AGENTS.md; templates/.claude/hooks/session-start.d/cognitive-readiness.sh; tests/test_templates.sh; tests/test_cognitive_readiness.sh (new); Makefile

Key constraints:
  - Deterministic phase — NO judge A/B eval (process theatre for a mechanical change); success = structural asserts + bidirectional firing tests.
  - Over-trim guard: every removed line traces to dedup/reorder; preserve all distinct rules, the {{...}} placeholders, and the 'Pre-commit sequence' section (existing tests).
  - Fix 5 reuses the existing needs_attention path (no parallel emit); suppress moot enforce/wiki/memory recs when uninitialized.
  - Trimmed AGENTS.md must be < 86 lines; line cap sits just above trimmed size.

Exit criteria: AGENTS.md < 86 lines, ruff + pytest lines each 1×, Hard Rules before Project Structure, line-cap assertion added, placeholders + Pre-commit sequence preserved; nudge fires when .dev-wiki/ absent + silent when present (firing test wired into make test); make test green + make eval 100%.

Abort: if either fix can't meet its deterministic success criterion after 3 attempts, mark [blocked:], report, ask skip/abort.

Next: implement T1 (Fix 5) → T2 (Fix 3) → T3 (integration), then /dev-debrief.

Gates:
- [x] Direction confirmed (USER OVERRIDE: user waived the direction gate — "no need to wait for my confirmation on direction... go through all the necessary steps to complete this phase"; Fix 3+5 combo + scopes chosen via AskUserQuestion)
- [x] Delivery accepted (user pre-authorized completion; delivery report generated, review gate 9/10, committed)
