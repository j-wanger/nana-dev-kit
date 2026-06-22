---
title: "Phase 101: Harder-corpus contract-vs-spec fidelity screen (edge-screener)"
aliases: [phase-101-harder-corpus-screen, harder-corpus-screen-phase]
category: phases
tags: [contract-fidelity, harder-corpus, edge-screener, rung-c, opencode, amplifier-screen, measurement, pre-registration, integrity-invariant, calibration-pilot, heu-012]
parents: []
created: 2026-06-22
updated: 2026-06-22
source: plan
status: completed
scope: ["companion/research/contract-screen-hard/**", ".dev-wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 100 delivered + accepted (verdict amplifier-null, ceiling-saturated → harder-corpus routed forward); spec specs/phase-101-harder-corpus-screen.md nana:approved 2026-06-22; direction gate closed (ledger Phase-101, all_accept:false); opencode on PATH; /Users/jwang/edge-screener present with its .venv."
exit_criteria: "pilot.md records per-task held-out scorer PASSES seeded reference AND FAILS seeded known-wrong + bare failing-assertion + disposition (in-band|floor|ceiling); >=3 in-band tasks (else informative null recorded); held-out unreachable (grep gate) + contract-leakage diff + information parity (strip asserts) all recorded; analyze-hard.py --selftest exit 0; shasum -c .frozen OK BEFORE any scored run; results.md = in-band tasks x 3 arms x n=3 with per-run fields + bare integrity-failure evidence; verdict.md = mechanical det-primary contract-vs-spec verdict (+ contract-floor disposition) OR informative null, claim scoped + worker pinned; /Users/jwang/edge-screener checksum identical before/after + git status clean; nana-dev-kit make test PASS, make eval 50/50, drift 0 (ships nothing); companion/ untracked."
---

# Phase 101: Harder-corpus contract-vs-spec fidelity screen (edge-screener)

## Objective

Re-run the Phase-100 contract-vs-spec fidelity screen on a **harder corpus** where a bare prompt plausibly **fails for an integrity reason** — real code-development tasks built by stubbing integrity-critical functions in `edge-screener` — to test whether a contract (naming the integrity invariant as a deterministic guardrail) keeps a delegated `opencode` worker more on-outcome than a prose spec or a bare prompt, on subtle-integrity work a bare prompt overlooks but **held-out** un-foolable tests catch. Directly attacks Phase 100's ceiling-saturated null (which lacked bare-arm failure headroom).

## Scope

Files and modules affected:
- `companion/research/contract-screen-hard/**` — the measurement apparatus (gitignored, like Ph97/98/100): from-scratch FUNCTION stubs of integrity-critical edge-screener functions, each with the function's full held-out test as scorer + a seeded real reference + a seeded known-wrong; the per-run edge-screener-copy runner; the calibration pilot record; the byte-frozen pre-registration (forked `analyze-hard.py`); results; verdict.
- `.dev-wiki/**`, `.claude/rules/active-phase.md` — lifecycle artifacts.

OUT: ANY shipped-kit change (this phase ships NOTHING — it is a measurement re-run; `check-fidelity.py` already shipped in Phase 100); mutating the real `/Users/jwang/edge-screener` (per-run throwaway copies only; original read-only + checksum-verified); reusing Phase-100 `analyze.py` verbatim (it is judge-primary/`MIN_CORPUS=4`/`n≥5` — forked to `analyze-hard.py`); pillar 2 (downstream-worker fleet); any `scripts/`/`modules.json`/hook/test/`Makefile` change.

## Exit Criteria

- [ ] Controls-first: `pilot.md` records, per task, that the held-out scorer PASSES its seeded reference AND FAILS its seeded known-wrong (clean-on-seed → reject that task; all-clean → phase aborted, recorded).
- [ ] Calibration with failure-mode stability: each kept task has ≥2/N bare runs failing the SAME integrity assertion (non-integrity-dominated tasks rejected); ≥3 in-band tasks (else the informative null is recorded + the phase routes to close-out).
- [ ] Held-out unreachable + contract-leakage diff + information parity: per scored run a recorded grep gate confirms the held-out test + its discriminating literals absent from the worker copy's reachable tree; the frozen contract shares no discriminating literal with the held-out test source; `strip_guardrail(contract)==spec` and `strip_objectives(spec)==bare` (byte-equal).
- [ ] Frozen instrument: `analyze-hard.py --selftest` exit 0; `shasum -a 256 -c companion/research/contract-screen-hard/.frozen` passes; freeze precedes any scored run; gitignored (`git check-ignore` confirms).
- [ ] `results.md` records in-band tasks × 3 arms × n=3 with per-run fields (task/arm/run/deterministic/judge/judge_variance/run_status) + the bare-arm integrity-failure evidence (rate <1.0 on ≥1 task); structural field scan passes.
- [ ] `verdict.md` records the mechanical det-primary contract-vs-spec verdict (per-arm distributions + effect form + the contract-floor disposition) OR the informative null with per-task bare evidence; claim scoped to the corpus + worker pinned. A contract-vs-spec VERDICT (vs the null) requires ≥1 in-band task with contract-arm rate > bare-arm rate by the frozen effect form.
- [ ] Real codebase unmutated: `/Users/jwang/edge-screener` checksum identical before/after the run set; `git -C /Users/jwang/edge-screener status --porcelain` empty.
- [ ] No kit change: `make test` ALL-PASS, `make eval` 50/50, `bash scripts/check-install-drift.sh` drift 0; `companion/` untracked.

## Constraints

- **Failure-mode stability** (prevents measuring noise instead of integrity) — keep a task only if ≥2/N bare runs fail the SAME integrity assertion; import/signature/timeout/API failures are out-of-band; a no-scorable-implementation run is a distinct infra outcome, never a silent FAIL.
- **Deterministic test PRIMARY, judge SECONDARY** (prevents a judge false-positive manufacturing a contract effect) — the held-out integrity test is the verdict; judge-PASS but test-FAIL = FAIL. The opposite of Phase 100, because here the integrity tests are un-foolable. Forked `analyze-hard.py` (det-primary, MIN_CORPUS=3, n=3), NOT Phase-100 `analyze.py`.
- **Held-out validated vs seeded known-wrong** (prevents a dead instrument) — each scorer MUST fail the canonical bug AND pass the real reference; clean-on-seed aborts that task; all-clean aborts the phase ([[HEU-012]]).
- **Held-out truly unreachable** (prevents iterate-to-green) — grep the whole reachable tree for the discriminating literals; the test is applied only in a separate scoring copy.
- **Contract names the invariant, not the test literals** (prevents a leaked win) — a pre-registered leakage diff rejects any shared discriminating token.
- **Information parity** (prevents measuring payload size) — byte-frozen payloads with diff-able parity assertions.
- **Contract-arm floor guard** (prevents a floored corpus dressed as a verdict) — a VERDICT needs ≥1 in-band task with contract>bare by the effect form, else the informative null.
- **Real edge-screener never mutated** — per-run throwaway copies + checksum before/after; worker/scoring CWD asserted to be a copy.
- **Frozen before scored runs** (anti-retrofit) — kept corpus, payloads, scorers, reference/known-wrong, pinned worker model/version, n=3, and `analyze-hard.py` byte-frozen (sha256 `.frozen`) before the screen; the pilot precedes the freeze.
- **Ships nothing** — kit unchanged; apparatus gitignored.

## Checkpoints

- After the candidate stubs + held-out scorers + seeded reference + seeded known-wrong are built: report the controls-first result (each scorer passes the reference AND fails the known-wrong) — the instrument is alive before any worker run.
- After the calibration pilot, BEFORE freezing: report the per-task failing-assertion classification + in-band/floor/ceiling disposition. If <3 in-band → STOP and record the informative null. If ≥3 → freeze and proceed.
- After one scored run per arm on an in-band task: confirm the held-out test scores it in the scoring copy, the worker edited the target function in its copy, and the real repo checksum is unchanged — before the full n.
- If `opencode` cannot develop/run in an edge-screener copy, OR the invariant cannot be made unreachable, OR all scorers pass their seeded bug: STOP and re-scope/record the limitation rather than ship a leaked, vacuous, or non-runnable screen.

## Assumptions

- `opencode` can develop in a per-run edge-screener copy and the held-out test runs there via the reused `.venv`. If false: STOP — re-scope the workspace before the screen.
- ≥3 integrity-critical functions have a single namable invariant + a generative held-out test (validated vs a seeded bug) + a real reference. If false: if <3 land in-band, the informative null stands (do not pad with weak tasks).
- A bare prompt genuinely fails some in-band tasks for the integrity reason. If false: "contract adds nothing — capable worker honors integrity unprompted even on hard tasks" strengthens the Phase-100 null; report it as such.

## Notes

The rung-C contract-driven-delegation program: pillar 3 (dashboard, Ph99) + pillar 1 measurement (Ph100, ceiling-saturated null) shipped; this is the harder-corpus follow-on. Decision [[harder-corpus-screen]] (medium); spec `specs/phase-101-harder-corpus-screen.md` (nana:approved 2026-06-22). The direction dashboard recommended bug-injection (A); the maintainer chose from-scratch stub (A2 reject) — recommended≠chosen, dogfooded.
