---
title: "Phase 81 complete — Assumption-Approval Gate: positions REPLACE approach-approval + append-only ledger + debrief revisit forcing-function"
aliases: []
category: journal
tags: [assumption-interrogation, gate, ledger, naive-surfacer, all-accept, dont-know, dogfood, no-llm-check, mandatory-over-advisory]
parents: [phase-81-assumption-approval-gate]
created: 2026-06-09
updated: 2026-06-09
duration: long (~3h — full plan + 4-task implementation + unified review + inline fixes; post-compaction estimate, may undercount)
source: debrief
---

# Phase 81 complete — Assumption-Approval Gate

## What Happened
The earned consequence of Phase 80's `^PROGRAM-VERDICT: INSTRUMENT-DEAD` ([[assumption-surfacer-completeness-screen]]): the scope-anchored surfacer's only edge was a working-knowledge LEAK, and the clean signal was DEGENERATE (a naive cost-sorted surfacer recovers load-bearing assumptions by reasoning). So Phase 81 ships the SIMPLEST gate, NOT the elaborate machinery — the human's dev-plan role shifts from rubber-stamp ("approve the approach?") to interrogator (accept/reject/don't-know on the plan's cost-sorted load-bearing assumptions; positions ARE the gate).

- **T1 [M]** — append-only ledger schema + `.dev-wiki/assumption-ledger.md` (seeded with the Phase-80 A1-A4 verdicts as the first conformant entry; `all_accept:false`, 1 reject) + `scripts/check-assumption-ledger.sh` (4 modes `--schema/--revisit/--gate/--append-only` + `--selftest`, bash+awk, NO LLM). Awk uses a state-flag + END-flush pattern (NOT range syntax) to dodge the EOF-boundary bug; an EOF-equivalent fixture asserts it. RED-first `tests/test_assumption_ledger.sh` wired into the Makefile. README 19→20 scripts.
- **T2 [L]** — dev-plan `assumption-gate.md` companion (naive surfacer consuming Step-10 T0's weakest assumption as a required member; accept/reject/don't-know via AskUserQuestion; reject→revise+re-surface; don't-know→defend/down-scope else route-to-Blockers + must-revisit; all-accept→warn+track+restate; empty-set confirm; top-N-by-cost cap; ledger-append by-path) + frozen `assumption-gate-example.md` (mixed-positions+reject / all-accept+restate). SKILL.md Step 13 REWRITTEN so positions REPLACE approval (legacy approach-approval prose removed), + Step-15f Gates-template line + top-of-file Direction Gate updated. SKILL.md 313→312 (≤350).
- **T3 [M]** — dev-debrief "Assumption-Ledger Revisit" (added to `debrief-finalization.md`, non-numbered heading so `test_step_numbering` is unperturbed): fill the closing-phase revisit-status, re-scan prior unrevisited/late-bite rows, surface a bit→suggest a decision-confidence review (no auto-mutation), enforce via `check-assumption-ledger.sh --revisit`. Wired from SKILL.md Step 21; runs in Lite too. NO new hook.
- **T4 [S]** — single-schema-source consistency assertions (check script owns the canonical `## Ledger schema` block; both skills reference it by-path; no divergent heading anywhere) + a coverage note (scripts/ + .dev-wiki/ are outside `check-install-drift`; firing-coverage rides on this test + the Makefile) + full regression.

## Decisions Made
- [[assumption-approval-gate]] (high) — written during /dev-plan this session (the build + the efficacy-not-claimed disclaimer); NOT re-derived at debrief.

## Problems Solved
- Awk EOF-boundary correctness — state-flag + END-flush instead of range syntax; asserted with a last-entry-at-EOF fixture.
- Schema split-brain — exactly ONE `## Ledger schema` source (the check script); both skills and the ledger header reference it by path; a consistency assertion (anchored, pipefail-guarded) catches a divergent heading without tripping on a legit backtick prose reference.

## Open Questions
- Deferred: a session-start advisory backstop for unrevisited ledger rows. The debrief-finalization check is the chosen firing point ([[HEU-012]]: verify firing, not presence). Re-trigger: debrief-skip leaves `unrevisited` rows undetected in real use.
- Parked: the accretion/budget-class residual (where the Phase-80 naive surfacer cleanly MISSED — the line-cap class) is genuinely UNMEASURED. A clean test needs a CONSUMING-project context (Ph66/69/80 representativeness — the in-kit always-loaded working-knowledge leaks the answers). A separate user call whether to re-run.

## Artifacts Changed
- `scripts/check-assumption-ledger.sh` (NEW — deterministic NO-LLM ledger validator; 4 modes + `--selftest`; bash/awk; the canonical `## Ledger schema` source)
- `.dev-wiki/assumption-ledger.md` (NEW — append-only cross-phase ledger; one block per phase; Phase-80 A1-A4 seed)
- `tests/test_assumption_ledger.sh` (NEW — 22 firing assertions; 20th make-test script)
- `templates/.claude/skills/dev-plan/assumption-gate.md` + `assumption-gate-example.md` (NEW companions)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 13 rewritten — positions REPLACE approval; Step-15f Gates line; Direction Gate)
- `templates/.claude/skills/dev-debrief/debrief-finalization.md` + `SKILL.md` (Assumption-Ledger Revisit forcing-function at Step 21)
- `Makefile` (wires the new test), `README.md` (test-count 19→20)

## Related
- [[phase-81-assumption-approval-gate|Phase 81: Assumption-Approval Gate]] — parent phase
- [[assumption-surfacer-completeness-screen|Phase 80 screen]] — the INSTRUMENT-DEAD that earned this build

## Review Gate
Unified reviewer **9/10 ACCEPT**. Findings, both FIXED inline:
- **[MEDIUM]** `--append-only` row-level guard — wording promised per-block row-count protection but the impl only guarded whole-block removal → extended to assert per-block row-count non-decreasing (catches within-block row deletion, not just whole-block removal; closes the section-rewrite truncation threat the `.dev-wiki/` location defends against).
- **[LOW]** dev-plan SKILL.md line 14 stale "approach approval" wording → updated to the new gate semantics.

## Soft Observations / Phase N+1 Candidates
- Phase 82's planning will be the FIRST live dogfood of the new gate — observe whether positions-as-gate actually changes the planning interaction, and whether all-accept becomes routine (the ledger's `all_accept` tracking is the cross-phase signal for that degeneration). | watch, don't build | this journal + [[assumption-approval-gate]] Consequences
- The gate's efficacy is UNMEASURABLE in-kit (Ph80 amplifier-null + Ph66/69 representativeness); the only real signal is Jake's lived experience + the ledger's all-accept pattern over phases. | no in-kit measurement phase | [[assumption-approval-gate]]
- Live evidence for the handover thesis (Phase 80/81): the agent's OWN buried assumption ("subagents are clean-context") was missed by self-check, caught only by an adversarial output audit; Phase 81's reviewer (9/10) then caught a MEDIUM self-check had passed. External forced checking beats self-triggered interrogation for the author's own load-bearing assumptions — exactly the role-change this gate institutionalizes. | (observed, not a phase) | mem_od8bxr2WxeXM

### Activation Quality
`.claude/rules/active-knowledge.md` carries 2 entries: [[assumption-approval-gate]] and [[HEU-012]]. Both were load-bearing this session — the gate decision drove all 4 tasks and HEU-012 (verify-firing-not-presence; the ledger row is the firing evidence) governed the NO-new-hook choice and the test design. Hit rate 2/2 (100%).

## Health Delta
- +22 test assertions (`tests/test_assumption_ledger.sh`, 22/22); make-test scripts 19→20.
- `make test` "All tests passed"; `bash scripts/check-assumption-ledger.sh --selftest` exit 0.
- `make eval` Score: 52/52 (unchanged — no new scenario).
- No new hook → firing-coverage / registration unchanged.
- All 10 spec exit criteria pass; reviewer 9/10 ACCEPT, both findings fixed inline.
