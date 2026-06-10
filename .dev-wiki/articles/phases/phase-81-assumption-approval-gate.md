---
title: "Phase 81: Assumption-Approval Gate"
aliases: ["phase-81-assumption-approval-gate", "phase-81-assumption-gate"]
category: phases
tags: [assumption-interrogation, gate, ledger, naive-surfacer, all-accept, dont-know, cost-of-error, mandatory-over-advisory, dogfood]
parents: []
created: 2026-06-09
updated: 2026-06-09
source: plan
status: completed
scope: ["scripts/check-assumption-ledger.sh", ".dev-wiki/assumption-ledger.md", "templates/.claude/skills/dev-plan/**", "templates/.claude/skills/dev-debrief/**", "tests/test_assumption_ledger.sh", "Makefile"]
entry_criteria: "Phase 80 complete/accepted (^PROGRAM-VERDICT INSTRUMENT-DEAD; the scope-anchored surfacer's only edge was a working-knowledge leak; the clean signal is DEGENERATE — a naive cost-sorted surfacer recovers load-bearing assumptions by reasoning). The screen's FORWARD recommendation is exactly this phase: ship the simplest gate."
exit_criteria: "scripts/check-assumption-ledger.sh --selftest exits 0 (NO LLM, both directions); make test green with a new tests/test_assumption_ledger.sh asserting the firing behaviour (flags a blank-revisit/no-positions/non-monotonic/schema-missing entry, passes a conformant one); dev-plan wires the gate companion (positions REPLACE approach-approval) within the 350-line cap; the gate companion defines accept/reject/don't-know + all-accept warn+track+restate + append; dev-debrief wires the revisit forcing-function within cap; ONE documented ledger-schema source referenced by both skills + the check; a frozen with/without example artifact exists; make eval shows Score: 52/52 (no new scenario); a decision article records the build + the efficacy-not-claimed disclaimer."
---

# Phase 81: Assumption-Approval Gate

## Objective
Replace the dev-plan direction gate's "approve the approach?" step with the maintainer taking explicit
accept / reject / don't-know positions on the plan's load-bearing assumptions, recorded in an append-only
cross-phase ledger whose unfilled revisit-status is mechanically surfaced at debrief — so the human's role
shifts from rubber-stamp to interrogator.

## Scope
Files and modules affected:
- `scripts/check-assumption-ledger.sh` (NEW — deterministic NO-LLM ledger validator, `--selftest`)
- `.dev-wiki/assumption-ledger.md` (NEW — append-only cross-phase ledger, Phase-80 A1-A4 seed)
- `templates/.claude/skills/dev-plan/**` (assumption-gate.md + assumption-gate-example.md companions; Step-13 + Step-15f rewrites)
- `templates/.claude/skills/dev-debrief/**` (revisit-status forcing-function + finalization check)
- `tests/test_assumption_ledger.sh` (NEW — firing assertions + schema-consistency)
- `Makefile`, `README.md`, `scripts/check-install-drift.sh`, `modules.json`

## Exit Criteria
- [ ] `bash scripts/check-assumption-ledger.sh --selftest` exits 0 (NO LLM; flags blank-revisit, no-positions, non-monotonic, schema-missing; passes a conformant entry — both directions)
- [ ] `make test` green with `tests/test_assumption_ledger.sh` asserting firing (not presence)
- [ ] dev-plan wires the gate via a companion, positions REPLACE approach-approval, SKILL.md ≤ 350
- [ ] gate companion defines accept/reject/don't-know + all-accept warn+track+restate + append
- [ ] dev-debrief wires the revisit forcing-function within cap (re-scans prior-phase unrevisited rows)
- [ ] ONE documented ledger-schema source referenced by both skills + the check (no split-brain)
- [ ] frozen with/without example artifact (mixed-positions WITH a reject + all-accept WITH a restatement)
- [ ] `make eval 2>&1 | grep -qE 'Score: 52/52'` (no new scenario; no regression)
- [ ] decision article records the build + the efficacy-not-claimed disclaimer

## Constraints
- All-accept must not silently reproduce blind-approve — warn + track `all_accept:true` + restate (NOT a hard block; Jake's choice).
- The gate must not degenerate to theatre (narrated, never taken) — the ledger row is the firing evidence; the check flags an in-implementation phase with no positions.
- The agent must not bury the load-bearing assumption low in its self-chosen cost ranking — the ledger records the FULL surfaced set so a revisit catches a low-ranked-but-bit assumption.
- The cross-phase ledger must not be silently truncated — `.dev-wiki/assumption-ledger.md` is append-only; a structural test asserts monotonic non-decreasing entry count.
- "Don't-know" must not equal accept for gate closure — resolved at the gate (defend/down-scope) or recorded as a deferred don't-know routed to Blockers + must-revisit.
- Revisit-status must not stay `unrevisited` forever — the debrief-finalization check flags any `unrevisited` row across ALL phases.
- No LLM in the deterministic check; skill files stay within the 350-line cap.

## Assumptions
- The dev-plan direction gate (Step 13) is the right insertion point. If false (surfacing belongs upstream at approach-proposal): fold the surfacer into Step 10's T0 output and keep Step 13 as the position-taking gate only.
- The ledger belongs in `.dev-wiki/` as its own append-only file. If false (a later skill run truncates it): relocate to a non-skill-managed path or add an append-only guard hook.
- The debrief-finalization deterministic check is sufficient mechanical bite for the (judgment-laden) revisit-status. If false (debrief is skipped in real use): add the deferred session-start advisory backstop ([[HEU-012]] firing point).
- Phase 81 itself is planned/implemented with the PRE-feature dev-plan, so it records no ledger entry from its own planning; the ledger begins populating from the next phase planned with the new gate.
- The frozen NAIVE surfacer prompt in `eval/assumption-screen/surfacer.md` (condition NAIVE) is the surfacer of record. If it is later edited: the gate companion must inline its own frozen copy so the gate prompt cannot drift.

## Notes
The earned consequence of Phase 80's `^PROGRAM-VERDICT: INSTRUMENT-DEAD`
([[assumption-surfacer-completeness-screen]]). The Phase-80 plan was itself interrogated through this
mechanism — Jake's live verdicts A1 accept / A2 reject (made Ph80 a screen) / A3 accept / A4 accept, plus
three direction-gate decisions for this plan (positions REPLACE the click; all-accept → warn+track+restate;
build the ledger now). Decision [[assumption-approval-gate]] (high). The efficacy of the intervention
cannot be measured inside the kit (the amplifier-null + Ph66/69/80 representativeness) and is NOT claimed —
the value is the human role-change; tests assert MECHANICS only. NO new hook (the debrief-finalization check
is the firing point; a session-start advisory is deferred). `eval/assumption-screen/` is the frozen
Phase-80 apparatus and is NOT touched.
