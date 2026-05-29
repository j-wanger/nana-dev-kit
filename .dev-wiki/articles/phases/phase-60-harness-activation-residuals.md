---
title: "Phase 60: Harness Activation Residuals"
aliases: ["harness-activation-residuals", "agents-trim-init-nudge"]
category: phases
tags: [harness, agents-md, instruction-budget, session-start, nana-init, cognitive-readiness, deterministic, subtraction-test]
parents: [phase-57-hook-consolidation-and-enforcement-activation]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope: ["templates/AGENTS.md", "templates/.claude/hooks/session-start.d/cognitive-readiness.sh", "tests/test_templates.sh", "tests/test_cognitive_readiness.sh", "Makefile"]
entry_criteria: "Phase 59 complete + committed (CUT verdict); approved spec specs/phase-60-harness-activation-residuals.md (reviewer 9/10, accept); user combined Fix 3 + Fix 5 into one phase and waived the direction gate (autonomy grant) — closes the Phase 57+ harness-activation roadmap."
exit_criteria: "templates/AGENTS.md trimmed below 86 lines with the lint/type/test triplet (ruff + pytest lines) stated once, Hard Rules before Project Structure, placeholders + 'Pre-commit sequence' section preserved, a line-cap assertion added to test_templates.sh; cognitive-readiness.sh emits a /nana-init nudge when .dev-wiki/ is missing and is silent when present, proven by a bidirectional firing test wired into make test; make test green + make eval 100%."
---

# Phase 60: Harness Activation Residuals

## Objective

Close out the Phase 57+ harness-activation roadmap with its two remaining residual fixes, each shipped with a deterministic, test-backed success criterion (no "looks better" rewrite, no manufactured judge-eval):

- **Fix 3 — AGENTS.md budget + salience trim:** reshape `templates/AGENTS.md` so the highest-leverage rules lead, every command sequence is stated once (the lint/type/test triplet is duplicated at lines 9–11 and 77–79), and the always-loaded line budget becomes a test assertion instead of an unenforced comment.
- **Fix 5 — kit-uninitialized nudge:** when session-start runs in a project with no `.dev-wiki/`, emit a single actionable "run `/nana-init`" line via `cognitive-readiness.sh`'s existing recommended-action path, verified by a firing test.

## Scope

- `templates/AGENTS.md` — dedup + reorder + shrink (below 86 lines); preserve placeholders + `Pre-commit sequence` section
- `templates/.claude/hooks/session-start.d/cognitive-readiness.sh` — add uninitialized-project detection + nudge, reuse `needs_attention`
- `tests/test_templates.sh` — add dedup + line-cap + ordering assertions
- `tests/test_cognitive_readiness.sh` (new) — bidirectional firing test; wire into Makefile
- `Makefile` — wire the new test script

## Exit Criteria

- [ ] `templates/AGENTS.md` is < 86 lines, with `uv run pytest` and `uv run ruff check --fix` each appearing exactly once (whole-triplet dedup).
- [ ] `Pre-commit sequence` section + the three `{{...}}` placeholders preserved (existing tests stay green).
- [ ] Hard Rules precede the Project Structure block (salience ordering), asserted in `test_templates.sh`.
- [ ] A line-cap assertion for `templates/AGENTS.md` exists in `tests/test_templates.sh`.
- [ ] `cognitive-readiness.sh` emits a `/nana-init` nudge when `.dev-wiki/` is absent and does NOT when it is present (bidirectional firing test green).
- [ ] The firing test is wired into the Makefile `test` target; `bash -n` on the hook is clean.
- [ ] `make test` exits 0; `make eval` reports 100%.

## Constraints

- Over-trim deletes a real rule — Guard: every removed/changed line traces to dedup, reorder, or the budget goal; the set of distinct rules is preserved, only de-duplicated and reordered.
- Trim breaks the existing template tests — Guard: placeholders + `Pre-commit sequence` section name stay; RED (new asserts) → GREEN (existing asserts still pass).
- Fix 5 false positive (nudges when initialized) — Guard: firing test asserts ABSENT when `.dev-wiki/` exists, PRESENT when missing — both directions.
- Fix 5 parallel emit path / contradictory advice — Guard: reuse `needs_attention`; when uninitialized, suppress the moot enforce/wiki/memory recommendations so the user sees one root action.
- Manufacturing an eval for a deterministic change (process theatre) — Guard: success is structural/firing only; no judge A/B; the unverified instruction-budget claim is flagged as a future research candidate, not fake-tested.
- Line cap too loose to guard — Guard: cap sits just above the trimmed size; trimmed file strictly < 86 ("caps need assertions, not docs", Phase 55).
- CLAUDE.md / agent-surface drift — Guard: `sync-rules.sh` regenerates copies verbatim from AGENTS.md, no structural dependency (verified).

## Checkpoints

- After Fix 5 firing test GREEN: confirm both directions and that bare-dir output is a net noise reduction, not an addition.
- After Fix 3 trim: confirm the diff removes only duplicated/reordered lines — no distinct rule lost.
- Before debrief: full suite + eval green; report before/after AGENTS.md line count. Delivery accepted at the delivery gate.

## Assumptions

- `cognitive-readiness.sh` is sourceable in isolation (pure function, no top-level side effects — verified by spec review). If false: test via full `session-start.sh` with a temp HOME; do not skip the firing test.
- "Any missing `.dev-wiki/`" is the intended trigger semantic (user choice after I flagged the false-positive). If a bare-dir nudge proves genuinely disruptive beyond the one-line cost measured, surface at the delivery gate — do not silently narrow the chosen trigger.
- `make test` / `make eval` run clean modulo the known optional-`sqlite-vec` memory path (guarded to skip since Phase 58 maintenance). A new halt is a regression of this phase.

## Notes

- Deliberately deterministic, not measured: Phases 58–59 used judge A/B because they changed reasoning behavior with an unknown effect size; these changes produce byte-identical output for identical inputs, so the rigorous instrument is structural assertions + bidirectional firing tests, not a judge whose variance would launder rather than reveal signal ([[cut-active-research-step-2-7]] is the precedent for killing un-earned complexity; the same subtraction-test lens says don't add eval ceremony a deterministic change can't benefit from).
- The deeper open question — does ~300 lines of always-loaded instruction degrade instruction-following? (the unverified claim at `templates/AGENTS.md:84`) — is a genuine research phase, NOT this trim. Flagged as a future candidate.
- Spec reviewer: 9/10, accept, 0 CRITICAL/0 MAJOR; one MINOR (whole-triplet dedup assertion) incorporated.
