<!-- nana:approved 2026-06-04 -->
# Spec: Phase 78 — Skill-Crystallization Headroom Screen

> Design hardened by an adversarial methodology review (2026-06-04, agent-internal) that read the candidate artifacts directly. Findings C1–C4 + M1–M5 incorporated below; provenance noted where load-bearing.

## Objective
Measure whether crystallizing a phase's TOOLING into a reusable skill adds value over bare re-derivation — specifically, whether a candidate tooling artifact embeds *non-recoverable correctness*: correctness a bare frontier model fails to reproduce even when given the **recoverable corpus** a non-crystallized consuming project would actually have (the artifact's public interface + its real call sites + the task), but not the implementation body or its tests. Deliver a deterministic, verifier-independent instrument plus a pre-registered `PROGRAM-VERDICT` that gates whether a capability→skill module is worth building at all.

## Context
The amplifier headroom-search has measured null in every *decision-retention* regime: single-decision (Phase 70, DEGENERATE 5/5), single-session/compaction (Phase 71, TERMINATE-by-summary-robustness), cross-session (Phase 77, residual 0/14). Banked finding: harness headroom does NOT live in re-presenting *decisions the model can recover from artifacts it already has*. The surviving avenue is the model's *capability/correctness* boundary, not its *decision/knowledge* boundary.

Real-usage observation (Jake): the kit captures knowledge (→ wiki article) and lifecycle (→ dev-wiki journal) but has no route for capturing CAPABILITY (→ a reusable skill bundling tested tooling). That crystallization happens only *inside* nana-dev-kit (skills are the product); in a consuming project (edge-screener) reusable tooling is a byproduct that never gets extracted. The proposed (Phase-79+) deliverable is a capability→skill route; this phase is the cheap go/no-go SCREEN before building any such machinery — burden-of-proof on the feature, per the campaign's subtraction discipline (Phase 64/72 cut speculative machinery).

The sharpening that makes the screen non-trivial: crystallizing procedure-PROSE is the amplifier null in new clothes (the model re-derives procedures). The only value-bearing case is TOOLING that embeds correctness the model does NOT reliably reproduce — and the fair test of that (per the review's C2) is against the *recoverable corpus*, not a lossy brief, exactly as the prior screens gave OFF the recoverable inputs (code+tests+git). The honest prior is SPLIT — general tooling likely DEGENERATE (re-derivable from its interface+callers), domain tooling (subtle quant correctness: look-ahead/survivorship/leakage — silently-wrong-on-re-derivation, the verifier/tooling boundary) likely HAS-HEADROOM. A split is itself the finding: "crystallize domain-tooling, not general-tooling."

## Scope
### In scope
- A new repo-only apparatus in `eval/amplifier/skill-screen/` (sibling to `anchor-screen/`, `retention-screen/`, `xsession-screen/`), frozen on completion.
- A deterministic NO-LLM scorer `check.sh` that runs a candidate's HIDDEN spec-implied correctness tests against an OFF re-derivation and emits a per-sample pass/fail; consensus aggregation pinned at **n=5, threshold=4** (cloned from the frozen `anchor-screen/check.sh`, not re-invented — review M1); `--selftest` flips both ways (real artifact passes, planted-buggy fails).
- A ported `leak-check.sh` + per-candidate `.offleak` (answer-tokens the spec-implied tests assert ∪ the tests' fixture literals): the OFF recoverable-corpus must contain NONE of them (review C4/M5), shasum-pinned.
- Frozen fixtures per candidate: the recoverable corpus `R_A` (public interface/signature + docstring + real call sites + task statement — NOT the implementation body, NOT the tests), the hidden test suite `T_A` (copied read-only), and the pinned spec-implied-vs-unstated partition WITH a quoted entailing corpus sentence per spec-implied test (review C3).
- OFF runs: clean subagents (bare model, `R_A`-only, no implementation/tests/kit-context), n=5 per candidate + controls; outputs frozen under `runs/`.
- `pre-registration.md` committed BEFORE any OFF run, ancestor-guarded.
- `classification.md` (per-candidate tally + SPEC-INCOMPLETE + cost-delta) and `screen-record.md` (grep-able `^PROGRAM-VERDICT:` + controls disposition + router-reframe note).

### Out of scope
- BUILDING the skill-crystallization module / capability→skill route (Phase 79+, gated on HAS-HEADROOM here).
- Any mutation of the edge-screener repo or of nana-dev-kit's own source artifacts (read-only subjects).
- Wiring the apparatus into `install.sh` / `Makefile` / `make test` / `make eval` (frozen, repo-only).
- LLM-as-judge scoring of any kind.
- End-to-end downstream-task reuse measurement (framing B). This screen is the cheap NECESSARY-condition gate (framing A: does the artifact embed non-recoverable correctness); the downstream-task ablation is the expensive follow-on, gated on this showing headroom.

## Approach
Verifier-independent, controls-first. The screen applies the report's central principle (the oracle must be out-of-band and invisible to the generator) to itself: OFF never sees the implementation or its tests, and the `.offleak` guard ensures the corpus does not state the answer.

- **T1 — Apparatus.** Build `check.sh` (NO-LLM): inputs an OFF-output path + candidate id; runs ONLY that candidate's pre-registered spec-implied tests against the OFF output; emits `PASS`/`FAIL` per sample; aggregates n=5 at threshold=4. `--selftest` flips both ways on a planted pair (the real artifact passes; a planted-buggy variant fails) — a no-op `exit 0` does not satisfy it. Port `leak-check.sh` (per-candidate `.offleak`). Build `assert-subject-untouched.sh` (read-only guard: source artifact hashes + edge-screener `git status` clean + fixture hashes byte-identical pre/post; fail closed). Stand up the frozen fixtures.
- **T2 — Pre-registration (the anti-retrofit gate).** `pre-registration.md` pins, per candidate:
  - (a) the candidate selection — chosen by criterion, not by a property asserted in prose: each candidate MUST have a locatable test function in `T_A` that encodes its non-obvious correctness, and the prereg QUOTES that test function (review C1 — no pinning a property not present in the test file);
  - (b) the recoverable corpus `R_A` (interface + docstring + call sites + task), shasum-pinned, and verified leak-clean against `.offleak`;
  - (c) the spec-implied test subset — each entry CITES the exact `R_A` sentence/signature that entails it; un-citable tests are unstated-edge BY RULE (review C3);
  - (d) the unstated-edge subset (failure → SPEC-INCOMPLETE, never headroom);
  - (e) the four controls (below);
  - (f) n=5, threshold=4, and the UNSTABLE disposition (review M1/M2);
  - (g) the verdict ladder.
  Commit BEFORE any OFF run; record `.prereg-commit`; `git merge-base --is-ancestor "$(cat .prereg-commit)" HEAD` must pass.
- **T3 — OFF re-derivation runs (the experiment; the one L).** For each candidate + control, spawn n=5 CLEAN subagents given exactly the pinned `R_A`; capture each A' under `runs/<candidate>/<n>/`. Score with `check.sh`. The OFF subagents are the verifier-independent clean-room (Phase-43 finding: bare subagents lack hooks/skills/memory). Record `classification.md`: per candidate, pass/fail over spec-implied tests (consensus), unstated-edge failures (SPEC-INCOMPLETE), and the recorded-only cost-delta.
- **T4 — Record + disposition.** Apply the verdict ladder; controls gate it. Cash `^PROGRAM-VERDICT:`. Append RESULT to the decision article; write the journal.

### Controls (four — review M3 added the symmetric one)
1. **Negative** — a trivial artifact (e.g. integer add); OFF MUST pass. Violated ⇒ OFF is lobotomized ⇒ `INSTRUMENT-DEAD`.
2. **Positive-unknowable** — an artifact whose correctness is a project-specific value absent from and unguessable from `R_A` (test-pinned magic constant); OFF MUST fail. Violated (OFF passes) ⇒ the corpus is leaking the answer ⇒ `INSTRUMENT-DEAD`.
3. **Recoverable-fully-specified** — an artifact whose correctness is FULLY entailed by its `R_A`; OFF MUST pass. Violated (OFF fails) ⇒ corpora are systematically too thin, every HAS-HEADROOM is suspect ⇒ `INSTRUMENT-DEAD`. (This is the control the review found missing: it guards false-HAS-HEADROOM-from-thin-corpus, the symmetric partner to the positive control.)
4. (The `.offleak` leak-check is the per-candidate fourth guard — it brackets every real candidate's corpus into the legitimate band: rich enough to be a fair counterfactual, not stating the answer.)

### Verdict ladder
- Per-candidate: **DEGENERATE** (OFF passes spec-implied tests ≥4/5 → re-derivable from `R_A` → skill adds only cost) / **HAS-HEADROOM** (OFF fails them ≥4/5 → non-recoverable correctness) / **UNSTABLE** (neither consensus reached) / and, orthogonally, **SPEC-INCOMPLETE** flag on any unstated-edge failures (recorded, never counted as headroom).
- UNSTABLE disposition (review M2): an UNSTABLE candidate counts as NOT measurable for the ≥2-measurable gate and never contributes a DEGENERATE→TERMINATE vote.
- Program `^PROGRAM-VERDICT:`: all measurable real candidates DEGENERATE ⇒ `TERMINATE` (don't build). ≥1 real candidate HAS-HEADROOM ⇒ `HAS-HEADROOM` (justify building, scoped to the candidate class that showed it). Any control violated ⇒ `INSTRUMENT-DEAD`. <2 real candidates measurable ⇒ `INCONCLUSIVE`.
- Cost-delta is recorded-only; NO verdict logic reads it (review M4).

### Domain Research Questions
1. Does the silent-wrong (survivorship/look-ahead — a plausible wrong answer) vs loud-wrong (a naive impl visibly never fires) distinction track the verdict? It would sharpen what a future module should target.
2. Is a SKILL the right vessel for a HAS-HEADROOM artifact, or is a regression TEST / lint rule better (it fires automatically; a skill must be remembered + invoked)? Record the router reframe so a HAS-HEADROOM verdict does not auto-imply "build a skill."
3. Where exactly is the `R_A` band fair? Document, per candidate, what was included (interface, which call sites) and what was redacted by `.offleak`, so a reviewer can confirm the corpus neither states the answer (false TERMINATE) nor is starved (false HAS-HEADROOM).

## Constraints (CRITICAL)
- **No LLM in the scoring path** — `check.sh` runs pinned tests, pass/fail only; `--selftest` flips on a known-correct/known-buggy pair.
- **OFF gets the recoverable corpus, never the implementation or tests** (review C2) — `R_A` = interface + docstring + call sites + task; the subagent has no repo/tool access; `R_A` shasum-pinned. Headroom then means "even with the surrounding code and interface, the model can't re-derive the correctness" — the same bar the prior screens used.
- **`.offleak` leak guard** (review C4/M5) — `R_A` must contain none of the answer-tokens the spec-implied tests assert, nor the tests' fixture literals; `leak-check.sh` fails closed on overlap. Prevents false TERMINATE (corpus states the answer) and copy-passing.
- **Spec-implied = entailed-by-`R_A`, with a quoted entailing sentence per test** (review C3) — pinned before runs; un-citable tests are unstated-edge by rule; `check.sh` counts only spec-implied tests. Mechanizes the partition so it cannot be retrofitted to observed failures.
- **Four controls gate the verdict** (review M3) — negative (pass), positive-unknowable (fail), recoverable-fully-specified (pass), plus the per-candidate `.offleak`. Any violation ⇒ `INSTRUMENT-DEAD`, not TERMINATE/HAS-HEADROOM.
- **n=5, threshold=4** (review M1) — cloned from the frozen apparatus; kills the n=1/2/3 lucky-draw scar (Phases 58/70/71/77) against high code-gen variance. <2 real candidates measurable ⇒ `INCONCLUSIVE`.
- **Candidate correctness must be located in `T_A`, not asserted in prose** (review C1) — the prereg quotes the test function encoding each candidate's non-obvious correctness; a candidate with no such locatable test is dropped.
- **Subjects read-only** — `assert-subject-untouched.sh` byte-identical pre/post, fail closed.
- **Pre-registration before runs, ancestor-guarded** — `git merge-base --is-ancestor "$(cat .prereg-commit)" HEAD`.
- **Apparatus repo-only, frozen** — unchanged make test/eval/registration/firing-coverage counts.

## Success Vision
A deterministic, verifier-independent instrument that returns an honest go/no-go either way. A TERMINATE is informative only if the negative + recoverable-fully-specified controls prove the corpus channel is fair AND the positive-unknowable control proves the instrument can see non-recoverable content — then it means "the candidate tooling is re-derivable from its interface+callers, so crystallizing it buys only cost-savings, not correctness," and the module is not built. A HAS-HEADROOM result names exactly which candidate(s) the bare model could not re-derive correctly from a leak-clean recoverable corpus, with each scored test traceable to an entailing corpus sentence — and the record states whether the right vessel is a skill or a regression test. A SPLIT verdict scopes any future module to domain/correctness tooling. Excellence is the verdict being un-foolable in either direction, not the direction it points.

## Exit Criteria (machine-checkable)
- [ ] `test -x eval/amplifier/skill-screen/check.sh && bash eval/amplifier/skill-screen/check.sh --selftest` (scorer flips both ways on the planted correct/buggy pair)
- [ ] `test -x eval/amplifier/skill-screen/leak-check.sh && bash eval/amplifier/skill-screen/leak-check.sh` (every candidate's `R_A` is leak-clean against its `.offleak`)
- [ ] `test -f eval/amplifier/skill-screen/pre-registration.md && git merge-base --is-ancestor "$(cat eval/amplifier/skill-screen/.prereg-commit)" HEAD` (prereg incl. quoted candidate tests + entailment-cited partition + n=5 precedes runs)
- [ ] `test -f eval/amplifier/skill-screen/classification.md` (per-candidate tally + SPEC-INCOMPLETE + cost-delta)
- [ ] `grep -Eq '^PROGRAM-VERDICT: (TERMINATE|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)' eval/amplifier/skill-screen/screen-record.md`
- [ ] Controls recorded: negative passed OFF, positive-unknowable failed OFF, recoverable-fully-specified passed OFF — else `screen-record.md` reads `INSTRUMENT-DEAD`
- [ ] `bash eval/amplifier/skill-screen/assert-subject-untouched.sh` (subjects byte-identical pre/post)
- [ ] `make test` green and `make eval` green (apparatus repo-only → no registration/settings/README/firing-coverage churn)
- [ ] Decision article (RESULT appended) + journal written

## Checkpoints
- After T1: `check.sh --selftest` flips both ways AND `leak-check.sh` passes on all corpora before any OFF run.
- After the T2 prereg commit, BEFORE any OFF run: ancestor guard passes; each candidate's correctness test is quoted; each spec-implied test cites its entailing `R_A` sentence; controls committed.
- After T3 controls: any control violated (neg fails / positive-unknowable passes / recoverable-fully-specified fails) ⇒ STOP, `INSTRUMENT-DEAD`; do not report a real-candidate verdict.
- If `assert-subject-untouched.sh` detects drift ⇒ STOP, contaminated, discard + report.

## Assumptions
- edge-screener's source is stable/read-only for the window; else pin a commit and copy that snapshot's artifact + tests + call sites as the frozen fixture.
- A bare clean subagent given only `R_A` is a faithful OFF/no-skill baseline (Phase-43 finding); else assert `R_A` is the complete input with no repo/tool access.
- ≥2 real candidates (each with a locatable correctness test) + working controls are constructible; else `INCONCLUSIVE` — itself the deliverable.
- The candidate's own tests are a valid correctness oracle; a tautological/weak test (the TTDD risk the screen is about) is excluded from the spec-implied subset and the exclusion noted — the screen must not inherit the anti-pattern it measures.
