---
title: "Phase 78: Skill-Crystallization Headroom Screen"
aliases: ["skill-crystallization-headroom-screen", "phase-78-skill-screen", "skill-screen"]
category: phases
tags: [eval-validity, amplifier-vision, measurement, headroom, skills, crystallization, tooling, verifier-independence, edge-screener]
parents: []
created: 2026-06-04
updated: 2026-06-04
source: plan
status: active
scope: ["eval/amplifier/skill-screen/**", ".dev-wiki/articles/decisions/**", ".dev-wiki/articles/journal/**", "specs/phase-78-skill-crystallization-headroom-screen.md"]
entry_criteria: "Phase 77 closed (decision-retention line null across all 3 regimes). Real-usage gap surfaced: no capability→skill capture route, and crystallization never happens in consuming projects. Burden-of-proof discipline requires a screen before building any module. Subjects (a nana-dev-kit tooling artifact + a real edge-screener domain artifact, both with test suites) exist."
exit_criteria: "check.sh --selftest flips both ways; pre-registration committed before runs (ancestor guard) with the spec-implied/unstated test partition + n-floor; classification.md records per-candidate tally + SPEC-INCOMPLETE + cost-delta; screen-record.md carries a closed-vocabulary ^PROGRAM-VERDICT; controls validated (pos fails OFF, neg passes OFF) else INSTRUMENT-DEAD; assert-subject-untouched.sh green; make test + make eval green at unchanged surface; decision article RESULT + journal written."
---

# Phase 78: Skill-Crystallization Headroom Screen

## Objective
Measure whether crystallizing a phase's TOOLING into a reusable skill adds value over bare re-derivation — i.e. whether a candidate tooling artifact embeds *non-recoverable correctness* a bare frontier model reproduces plausibly-but-wrongly from the artifact's own brief. Deliver a deterministic, verifier-independent instrument plus a pre-registered `PROGRAM-VERDICT` gating whether a capability→skill module is worth building.

## Scope
- `eval/amplifier/skill-screen/*` — new repo-only apparatus (sibling to `anchor-screen/`, `retention-screen/`, `xsession-screen/`), frozen on completion, NOT wired into install.sh / Makefile / make test / make eval.
- `specs/phase-78-skill-crystallization-headroom-screen.md` — the nana:approved contract.
- `.dev-wiki/articles/decisions/skill-crystallization-headroom-screen.md`, `.dev-wiki/articles/journal/*` — decision article (RESULT appended) + phase journal.
- READ-ONLY subjects: a nana-dev-kit tooling artifact (`scripts/check-install-drift.sh` + its drift tests) and a real edge-screener domain artifact (point-in-time survivorship membership filter + its tests) copied as frozen fixtures; assert byte-identical pre/post.

## Exit Criteria
- [ ] `test -x eval/amplifier/skill-screen/check.sh && bash eval/amplifier/skill-screen/check.sh --selftest` (scorer flips both ways: real artifact passes, planted-buggy fails; n=5/threshold=4)
- [ ] `test -x eval/amplifier/skill-screen/leak-check.sh && bash eval/amplifier/skill-screen/leak-check.sh` (every candidate's `R_A` is leak-clean against its `.offleak`)
- [ ] `test -f eval/amplifier/skill-screen/pre-registration.md && git merge-base --is-ancestor "$(cat eval/amplifier/skill-screen/.prereg-commit)" HEAD` (prereg incl. quoted candidate tests + entailment-cited partition + n=5 precedes runs)
- [ ] `test -f eval/amplifier/skill-screen/classification.md` (per-candidate tally + SPEC-INCOMPLETE + cost-delta)
- [ ] `grep -Eq '^PROGRAM-VERDICT: (TERMINATE|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)' eval/amplifier/skill-screen/screen-record.md`
- [ ] Controls recorded: negative passed OFF, positive-unknowable failed OFF, recoverable-fully-specified passed OFF — else verdict reads `INSTRUMENT-DEAD`
- [ ] `bash eval/amplifier/skill-screen/assert-subject-untouched.sh` (subjects byte-identical pre/post)
- [ ] `make test` green and `make eval` green (apparatus repo-only → no registration/settings/README/firing-coverage churn)
- [ ] Decision article RESULT appended + journal written

## Constraints
> Hardened by an agent-internal adversarial review (2026-06-04) — findings C1–C4/M1–M5 folded in.
- **No LLM in the scoring path** — `check.sh` runs pinned tests, pass/fail only; `--selftest` flips on a known-correct/known-buggy pair; n=5/threshold=4 cloned from `anchor-screen/` (review M1).
- **OFF gets the recoverable corpus `R_A`, never the implementation or tests** (review C2) — `R_A` = interface + docstring + call sites + task (the same recoverable-inputs bar the prior screens used, NOT a lossy brief); subagent has no repo/tool access; `R_A` shasum-pinned.
- **`.offleak` leak guard** (review C4/M5) — `R_A` must contain none of the answer-tokens the spec-implied tests assert nor the tests' fixture literals; `leak-check.sh` fails closed.
- **Spec-implied = entailed-by-`R_A`, with a quoted entailing sentence per test** (review C3) — pinned before runs; un-citable → unstated-edge by rule; `check.sh` counts only spec-implied tests; unstated-edge failures → SPEC-INCOMPLETE.
- **Four controls gate the verdict** (review M3) — negative (pass), positive-unknowable (fail), recoverable-fully-specified (pass), + per-candidate `.offleak`; any violation → `INSTRUMENT-DEAD`.
- **Candidate correctness located in `T_A`, not asserted in prose** (review C1) — prereg quotes the test function encoding each candidate's non-obvious correctness; un-locatable → dropped.
- **n=5 + threshold=4; UNSTABLE counts as not-measurable, never votes toward TERMINATE** (review M1/M2); <2 real candidates measurable → `INCONCLUSIVE`.
- **Subjects read-only** — `assert-subject-untouched.sh` byte-identical pre/post, fail closed.
- **Pre-registration before runs, ancestor-guarded** — `git merge-base --is-ancestor`.
- **Apparatus repo-only, frozen** — unchanged make test/eval/registration/firing-coverage counts.

## Checkpoints
- After T1: `check.sh --selftest` must flip both ways before any OFF run.
- After the T2 prereg commit, BEFORE any OFF run: ancestor guard passes; partition + controls committed.
- After T3 controls: pos passes OFF OR neg fails OFF ⇒ STOP, `INSTRUMENT-DEAD`, report.
- `assert-subject-untouched.sh` drift ⇒ STOP, contaminated, discard + report.

## Assumptions
- edge-screener source is stable/read-only for the window; else pin a commit + copy that snapshot as the fixture.
- A bare clean subagent is a faithful OFF/no-skill baseline (Phase-43 finding); else assert the OFF prompt is the complete input with no repo/tool access.
- ≥2 real candidates + working controls are constructible; else `INCONCLUSIVE` (itself the deliverable).
- The candidate's own tests are a valid oracle; a tautological/weak test is excluded from the spec-implied subset (the screen must not inherit the TTDD anti-pattern it measures).

## Notes
Successor to the decision-retention line (Ph70/71/77, all null). Honest prior is SPLIT — general tooling DEGENERATE, domain tooling HAS-HEADROOM; the split is the finding. A HAS-HEADROOM verdict does NOT auto-imply "build a skill" — the router reframe (regression test / lint rule vs skill) is recorded as the live Phase-79 fork. A TERMINATE closes the capability-crystallization line as dead-on-arrival the same way the decision-retention regimes closed; existing capture routes kept on operational grounds. KNOWLEDGE GAP resolved only by running T3: whether bare re-derivation of the domain artifact passes its hidden spec-implied tests is unknown until the OFF runs complete — that is the gate.
