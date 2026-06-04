---
title: "Phase 77: Cross-Session Retention Headroom Screen (audit-gated ablation)"
aliases: ["cross-session-retention-screen", "phase-77-cross-session-retention-screen", "xsession-screen"]
category: phases
tags: [eval-validity, amplifier-vision, measurement, retention, cross-session, headroom, ablation, audit-gated, edge-screener]
parents: []
created: 2026-06-04
updated: 2026-06-04
source: plan
status: active
scope: ["eval/amplifier/xsession-screen/**", ".dev-wiki/articles/decisions/**", ".dev-wiki/articles/journal/**"]
entry_criteria: "Phase 76 closed; the amplifier program's last untested regime is cross-SESSION retention; the edge-screener substrate (Phase 73) has accrued real multi-session history (9 phases, 14 decision articles, 11 journals across 3 dates, 28 commits) — the deferred-measurement decidable-when gate is green."
exit_criteria: "residual-audit.sh --selftest passes both ways + residual.md exists; screen-record.md carries a closed-vocabulary ^PROGRAM-VERDICT; if residual non-empty, pre-registration precedes verdicts (ancestor guard) + check.sh --selftest passes + positive control recovered by ON (else INSTRUMENT-DEAD); assert-subject-untouched.sh green (edge-screener read-only); make test + make eval green at unchanged surface (apparatus repo-only); decision article + journal written."
---

# Phase 77: Cross-Session Retention Headroom Screen (audit-gated ablation)

## Objective

Measure whether the persistent on-disk dev-wiki substrate lets a fresh agent session recover decisions/process-discipline that a substrate-free session loses across a real session boundary — using the real `/Users/jwang/edge-screener` project as a fixed, read-only historical subject. Deliver a deterministic instrument plus a pre-registered `PROGRAM-VERDICT` on the amplifier program's terminal (cross-session) regime.

## Scope

Files and modules affected:
- `eval/amplifier/xsession-screen/*` — new repo-only apparatus (sibling to `anchor-screen/`, `retention-screen/`), frozen on completion, NOT wired into install.sh / Makefile / make test / make eval.
- `.dev-wiki/articles/decisions/*`, `.dev-wiki/articles/journal/*` — the decision article + phase journal.
- `/Users/jwang/edge-screener` — READ-ONLY subject (assert byte-identical before/after; no mutation).

## Exit Criteria

- [ ] `test -x eval/amplifier/xsession-screen/residual-audit.sh && bash eval/amplifier/xsession-screen/residual-audit.sh --selftest` (audit predicate + absence-grep selftest pass both ways)
- [ ] `test -f eval/amplifier/xsession-screen/residual.md` (residual enumerated or recorded empty)
- [ ] `grep -Eq '^PROGRAM-VERDICT: (TERMINATE|NULL|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)' eval/amplifier/xsession-screen/screen-record.md` (closed verdict vocabulary)
- [ ] If residual non-empty: `git merge-base --is-ancestor "$(cat eval/amplifier/xsession-screen/.prereg-commit)" HEAD` AND `bash eval/amplifier/xsession-screen/check.sh --selftest`
- [ ] If T2 ran: positive control recovered by ON (recorded pass) — else verdict reads `INSTRUMENT-DEAD`, not NULL
- [ ] `bash eval/amplifier/xsession-screen/assert-subject-untouched.sh` (edge-screener git status clean + substrate hashes byte-identical pre/post)
- [ ] `make test` green and `make eval` green (apparatus repo-only → no registration/settings/README/firing-coverage churn)
- [ ] Decision article + journal written

## Constraints

- **No LLM in the scoring path** — deterministic consensus-by-clause only; `grep -F`/regex over a pre-registered discriminating token; checker has a `--selftest` flipping on a control pair. Prevents the false-HAS-HEADROOM risk the campaign's evidence already cut.
- **OFF input set is physically stripped, not honor-system** — build OFF from a `git archive`/copy with substrate paths deleted; a manifest diff asserts ZERO substrate files before the run, else fail closed. Prevents the silent false-null where the agent reads a `.dev-wiki/` that still exists on disk.
- **Per-item provenance absence-grep** — each scored item carries a committed absence check (zero hits across OFF's inputs); items that fail are excluded, not silently counted. Prevents leakage inflating recovery value.
- **Length/volume control (padded-OFF)** — ON scores HAS-VALUE only if it beats BOTH bare-OFF and padded-OFF. Prevents the Phase-59 confound where ON wins on token volume, not content.
- **Positive control gates the null** — a planted substrate-only decision ON MUST recover; if it fails, verdict is `INSTRUMENT-DEAD`, not NULL. Prevents a confound-induced false null terminating the program's last regime.
- **Pin to terminal/HEAD-consistent value + HEAD-resolvability filter** — recovery of a superseded value is a miss; a token that no longer resolves at HEAD is excluded at audit time. Prevents rewarding the substrate for surfacing obsolete/reversed state.
- **Process-discipline items are behavioral artifacts, not assertions** — each reduces to a deterministic artifact a bare agent cannot produce without the substrate (cites the correct next uncompleted task-id, honors a specific deferred-decision exclusion, names the active-phase number) + its own absence-grep. Prevents the vacuous always-recover.
- **Subject is read-only and isolated** — every condition runs in a throwaway copy with hooks disabled; assert the original repo `git status` clean + substrate hashes byte-identical pre/post; fail closed on drift.
- **n-floor forces INCONCLUSIVE** — eligible-item floor pinned at n≥3 distinct residual decisions, committed BEFORE the residual count is known (floor-commit ancestor of the audit output). Prevents the n=1 false-positive scar.
- **Pre-registration before runs, ancestor-guarded** — `git merge-base --is-ancestor <prereg> <verdict>` must pass. Prevents retrofitting the verdict.
- **Apparatus repo-only, frozen** — not referenced by install.sh/Makefile; make test/make eval/registration/firing-coverage counts unchanged. Prevents surface churn.

## Checkpoints

- After T1 residual audit: if residual is EMPTY (or below the n-floor) ⇒ STOP, write `PROGRAM-VERDICT: TERMINATE`/`INCONCLUSIVE`, do NOT build T2/T3. Report.
- After the pre-registration commit, BEFORE any OFF/ON candidate run: confirm the ancestor guard and the controls plan are committed.
- If the positive control fails under ON: STOP, verdict `INSTRUMENT-DEAD` — do not report a null. Report.
- If the subject-integrity assertion detects drift: STOP, the run is contaminated — discard and report.

## Assumptions

- edge-screener's history is stable and read-only for the measurement window. If false (actively worked in parallel): snapshot a pinned commit and measure against that snapshot only.
- The frozen `retention-screen/` scoring primitives transfer to a real cross-session boundary. If false: clone-and-adapt with the diff explicitly recorded, keeping consensus-by-clause and NO-LLM intact.
- At least one residual item plus a constructible positive control exist. If false (zero residual): the verdict is `TERMINATE` (UNMEASURABLE-cross-session), which is itself the deliverable — not a failure.
- The OFF condition is entitled to full `git log` commit bodies (every real bare session has git). If this makes the residual near-empty, that is the expected honest finding, pre-registered as distinct from substrate-valuelessness.

## Notes

Terminal regime of the amplifier headroom-search: Ph70 (single-decision) and Ph71 (single-session/compaction) both TERMINATED as boundary-properties, not dead instruments. The honest prior here is degenerate too; the deliverable is an un-foolable verdict either way. The git-log-as-competing-substrate-channel caveat is load-bearing: a null residual means the harness's value precipitated into git via debrief discipline, NOT that the substrate is worthless. KNOWLEDGE GAP: whether ANY edge-screener decision survives the absence-grep (residual non-empty) is unknown until T1 runs — this is the gate; whether a constructible substrate-only positive control exists is confirmed-at-T3.
