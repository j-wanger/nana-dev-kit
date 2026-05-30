<!-- nana:approved 2026-05-30 -->
# Spec: Phase 70 — Single-Decision Anchor-Headroom Screen

## Objective

Build and RUN an empirical anchor-headroom screen that decisively answers one question: does even one non-commodity *single-decision* anchor have real OFF-baseline headroom — i.e. does the harness-OFF base model OMIT the correct behavior unprompted, leaving room for the harness to plausibly help? Produce a frozen, pre-registered, per-anchor empirical record and a graded program verdict (continue / parked / terminate) that gates whether the amplifier-measurement program proceeds to a live experiment.

## Context

Phases 65–69 tried to measure whether the Nana harness (hooks/skills/memory/rules over a coding agent) improves outcomes; the results were mostly negative. Phase 69 ran a deterministic ruler over 8 real consuming-project transcripts and found the planned live off/on run premature for two independent structural reasons: the ground-truth detector is blind (the anchor surfaces in prose, never inside an AskUserQuestion — 0 in-boundary events on all 8) AND the anchor is degenerate (the base model handles look-ahead bias unprompted even in the harness-OFF baseline — `raw` hits OFF 11/22/30 vs ON 4/8/6, i.e. OFF ≥ ON, so there is no lift to detect). A committed `measurability-gate.sh` prints NOT-MEASURABLE.

The Phase-69 handoff listed Phase 70 as "predicate repair → valid anchor → live run," but that order is wrong: predicate-repair-first is structurally blocked — any boundary broadened to catch the current anchor in ON also catches it in OFF (raw-text collapse), discriminating nothing. You cannot repair the detector until you know *where a valid anchor surfaces*. Anchor SELECTION is upstream of measurement (`eval/amplifier/VALID-MEASUREMENT.md:41`, and a prior harvested lesson: an anchor is *degenerate-for-lift* iff the base model already produces the correct behavior unprompted in the OFF baseline — zero headroom — so a candidate must pass an OFF-baseline headroom screen *before* any off/on experiment is designed). So Phase 70 inverts the order and screens for anchor existence first — the cheapest decisive go/no-go for the whole program after five negative phases.

The recurring scar this screen must not reopen: an earlier feature shipped a +0.5 result at n=1 that evaporated at n≥3, and the LLM-as-judge had high inter-run variance (mean 2.97–4.85). The asymmetric risk is a FALSE POSITIVE — declaring headroom that isn't there — which would greenlight an expensive downstream experiment built on sand. A null result is an accepted, valuable outcome.

## Scope

### In scope
- A screen apparatus under `eval/amplifier/`: a pre-registration of candidate anchors (each with a frozen, shasum-pinned OFF-baseline prompt + a deterministic pass/fail check) committed BEFORE any run; a deterministic check runner; per-anchor verdict files; a frozen aggregate screen record.
- THREE controls run first as a checkpoint: a NEGATIVE control (known-degenerate look-ahead anchor → must screen DEGENERATE), a POSITIVE control (constructed anchor requiring an unknowable fact → must screen HAS-HEADROOM), a MIDDLE calibration control (known-partial headroom → must produce a STABLE verdict across runs + a blind re-run).
- Executing the harness-OFF runs (bare clean-room subagent, no tools/hooks/skills/memory/rules) at the pre-registered n per anchor, applying the deterministic check, and recording per-run pass/fail + consensus.
- A graded program verdict + a Phase-71 handoff (or parked/terminated disposition) recorded as a decision article.

### Out of scope
- Any harness-ON run, lift estimate, or controlled off/on experiment (the screen is harness-OFF ONLY — the live experiment is a separate, gated phase).
- Patching `eval/amplifier/emit-proxy-vector.sh` (the frozen ruler) or `measurability-gate.sh`; predicate repair is deferred to Phase 71+ and is gated on this screen finding a valid anchor.
- Any CODE edit under `eval/comparison`, `eval/corpus`, `eval/reasoning`.
- The long-horizon / multi-turn constraint-retention anchor class (a one-shot subagent cannot surface its failure mode — explicitly deferred to a future phase with a genuine multi-turn substrate).
- Hooks, `modules.json`, `settings.json`, `install.sh`; wiring anything into `make test` / `make eval`.

## Approach

A controls-first empirical screen producing a deterministic, pre-registered, frozen record (mirroring `eval/reasoning/results.md` discipline). Anchors are single-decision, PURE-REASONING tasks only. The classification logic is deterministic and unit-testable even though the runs are model-driven: the LLM produces output; a committed deterministic predicate decides PASS/FAIL.

- **Deterministic consensus criterion, not a judge.** Each anchor carries a pre-registered deterministic check composed of one or more NAMED clauses (regex/structural predicates over the model output, e.g. a clause `pit-guard` = "commits to a point-in-time / data-leakage guard"). The runs are fixed at exactly n=5. Verdict rule: HAS-HEADROOM iff the check FAILS in ≥4/5 runs AND the SAME named clause is the failing one in ≥4/5 (consensus on the same missing behavior, decided deterministically by clause-id — not by free-text similarity); DEGENERATE iff the check PASSES in ≥4/5; anything else is UNSTABLE → quarantine (not classified). Consensus-by-clause-not-OR, because OR-of-failures plus run-to-run noise inflates false HAS-HEADROOM. The PASS/FAIL boundary for a PARTIAL / hedged answer (mentioned-weakly-as-one-option-among-several vs committed-to) is itself a pre-registration deliverable, locked as a `check.sh --selftest` fixture before any run — not a runtime decision.
- **Pure-reasoning anchors only.** A bare subagent differs from real harness-off in tool access (the confound that retired `eval/comparison`'s A-vs-C arm). Restrict to anchors whose correct behavior needs no tool; quarantine any tool-gap-vulnerable candidate with the reason stated, so "omits X" isolates harness-relevant headroom rather than a subagent capability gap.
- **Pinned, leak-free OFF prompts.** Each anchor's OFF prompt is frozen and shasum-pinned before runs; a deterministic check asserts the prompt contains none of the harness's injected-rule vocabulary (no smuggling the answer → no false DEGENERATE). Headroom that depends on prompt phrasing is a prompt-luck artifact, not real headroom.
- **Graded, priors-skeptic-proof verdict.** Candidates seeded from the known headroom priors (genuinely-novel / post-training-cutoff / proprietary decisions — weak parametric knowledge — plus domain-nuance), pre-registered before running. Verdict ladder: ≥1 NATURAL anchor HAS-HEADROOM → program CONTINUES (hand Phase 71 the validated anchor); no natural anchor but the ENGINEERED-FAVORABLE anchor HAS-HEADROOM → "headroom only under construction, not real work" → PARKED pending new priors; even the engineered-favorable anchor DEGENERATE → STRONG TERMINATION of the single-decision measurement program. The candidate count is recorded so a thin pool cannot pass as a confident null.

### Domain Research Questions
- What single-decision, pure-reasoning anchor most plausibly carries genuine OFF-baseline headroom for a strong frontier base model — i.e. a decision the model reliably gets wrong/omits unprompted but a harness rule could fix? (The whole program's premise rides on whether such a thing exists.)
- How is a PARTIAL / hedged answer scored deterministically — does "mentions the behavior weakly, as one option among several it doesn't commit to" count as PASS or FAIL? (The commitment threshold IS the verdict; it must be pre-registered, not decided post-hoc.)
- What is the minimal n and majority threshold that stabilizes the middle-band verdict given known judge/sampling variance — and is a single canonical prompt defensible, or must headroom survive ≥2 paraphrases?

## Constraints (CRITICAL)

- The headroom criterion MUST be a deterministic predicate over model output with a consensus-over-n rule (strong majority + same-missing-behavior agreement), never a raw LLM-judge score — prevents judge-variance being read as anchor signal (the false-HAS-HEADROOM failure).
- Pre-registration is load-bearing and MUST precede runs: candidate list, the base-model identity (`base-model:` model+version field), each frozen OFF prompt (shasum-pinned), and each deterministic check are committed BEFORE any harness-OFF run; each per-anchor verdict file records the `prompt-shasum:` it ran against (matching pre-registration) and is written from the run outputs, not retrofitted — prevents fitting the verdict to a desired conclusion and lets a skeptic reconstruct which model produced what.
- n = 5 per anchor, exactly (pre-registered, frozen before results — not n≥5, so the majority threshold is unambiguous); HAS-HEADROOM requires check-FAIL in ≥4/5 with the SAME named clause failing; DEGENERATE requires check-PASS in ≥4/5; the in-between band is UNSTABLE/quarantine — prevents the n=1 false-positive resurrection.
- Each OFF prompt MUST pass a deterministic answer-leak check against a frozen forbidden-vocabulary wordlist (`leak-vocab.txt`, committed with the pre-registration; the harness's injected-rule terms) — prevents a contaminated baseline that smuggles the answer (false DEGENERATE) or carries the harness's lift inside the prompt.
- Controls MUST falsify the screen in both directions AND in the middle: NEGATIVE → DEGENERATE, POSITIVE → HAS-HEADROOM, MIDDLE → stable verdict across the n runs AND on a blind re-run. Any control misbehavior → STOP (the screen instrument is broken) — prevents trusting a screen validated only on saturated endpoints.
- Pure-reasoning anchors only; tool-gap-vulnerable candidates are quarantined with the reason documented — prevents a subagent-capability-gap artifact masquerading as harness headroom.
- The null branch is graded (downgrade-to-PARKED, not auto-terminate) and "termination" language requires the engineered-favorable control to also screen DEGENERATE; there is NO retry-until-green path and the threshold cannot be loosened after seeing results — encodes the asymmetric cost (false positive ≫ false null) and makes a null a first-class success.
- NO harness-value claim anywhere: HAS-HEADROOM means "lift is POSSIBLE," never "lift exists" (the screen tests a necessary, not sufficient, condition). The record carries a no-harness-value disclaimer and contains no machine verdict token (`harness_lift=`, `VERDICT: harness`) — mirrors the Phase-69 anchor/instrument-not-harness-value discipline.
- `eval/amplifier/emit-proxy-vector.sh`, `measurability-gate.sh`, and all CODE under `eval/comparison|corpus|reasoning` stay git-diff-empty; `make eval` frozen at 52; `make test` green at the UNCHANGED 19-script count (the screen is a repo-only eval artifact, not a make-test gate — no README script-count bump).

## Success Vision

A skeptic reading the frozen record can reconstruct exactly what was asked, of which base model, how many times, what the pre-committed correct-behavior key was, and how each PASS/FAIL was decided — and reaches the same verdict without trusting the author's interpretation. The controls visibly bracket the screen (a known-degenerate anchor reads DEGENERATE, a known-headroom anchor reads HAS-HEADROOM, a contested-middle anchor reads stably), so the candidate verdicts are credible in the band where they actually live. The outcome is DECISIVE in either direction: either Phase 71 inherits a deterministically-validated anchor it can build a real experiment on, or the program receives a graded null that a priors-skeptic cannot wave away as "you didn't look hard enough." It is emphatically NOT a sixth "we measured and it was inconclusive" record — the controls + pre-registration + graded ladder make inconclusiveness itself a recorded, interpretable state (UNSTABLE/quarantine), not a shrug.

## Exit Criteria (machine-checkable)

- [ ] `test -f eval/amplifier/anchor-screen/pre-registration.md && grep -Eq '^prompt-shasum: *[0-9a-f]{64}' eval/amplifier/anchor-screen/pre-registration.md && grep -Eq '^base-model: *.+' eval/amplifier/anchor-screen/pre-registration.md` — pre-registration pins per-prompt shasums and the base-model identity
- [ ] `git log --diff-filter=A --format='%H' -- eval/amplifier/anchor-screen/pre-registration.md | tail -1` is an ancestor of the first `verdicts/` commit (`git merge-base --is-ancestor <prereg-commit> <first-verdict-commit>` exits 0 — pre-registration precedes runs)
- [ ] `bash eval/amplifier/anchor-screen/check.sh --selftest` exits 0 (the deterministic clause-checker classifies planted PASS, FAIL, and HEDGED fixture outputs to their pre-registered expected verdicts, in both directions, and verifies each verdict's `prompt-shasum:` matches pre-registration)
- [ ] `bash eval/amplifier/anchor-screen/leak-check.sh` exits 0 (every frozen OFF prompt contains no term from the committed `leak-vocab.txt`)
- [ ] `ls eval/amplifier/anchor-screen/verdicts/*.md | wc -l` ≥ 6 (3 controls + ≥3 candidates) and `grep -LEq '^verdict: (DEGENERATE|HAS-HEADROOM|UNSTABLE|DISQUALIFIED)$' eval/amplifier/anchor-screen/verdicts/*.md` prints nothing (every verdict file carries an anchored verdict token)
- [ ] controls behave OR a STOP was recorded — `( grep -Eq '^verdict: DEGENERATE$' eval/amplifier/anchor-screen/verdicts/control-negative.md && grep -Eq '^verdict: HAS-HEADROOM$' eval/amplifier/anchor-screen/verdicts/control-positive.md && grep -Eq '^stability: STABLE$' eval/amplifier/anchor-screen/verdicts/control-middle.md ) || grep -Eq '^FINDING: INSTRUMENT-BROKEN' eval/amplifier/anchor-screen/screen-record.md`
- [ ] `grep -Eq '^PROGRAM-VERDICT: (CONTINUE|PARKED|TERMINATE)$' eval/amplifier/anchor-screen/screen-record.md` — a single anchored graded verdict is recorded
- [ ] `! grep -REq 'harness_lift=|VERDICT: *harness' eval/amplifier/anchor-screen/ && grep -qi 'lift is possible\|makes no.*harness.*\(value\|claim\|verdict\)\|no harness-value' eval/amplifier/anchor-screen/screen-record.md` — no harness-value token; necessary-not-sufficient disclaimer present
- [ ] `git diff --quiet HEAD -- eval/amplifier/emit-proxy-vector.sh eval/amplifier/measurability-gate.sh eval/comparison eval/corpus eval/reasoning` — frozen artifacts untouched
- [ ] `make eval 2>&1 | tail -1` reports 52/52 and `make test` exits 0 at the unchanged 19-script count

## Checkpoints

- After pre-registration (candidates + frozen prompts + checks) is committed: STOP and verify it precedes any run; do not begin harness-OFF runs until it is committed.
- After the THREE controls run (FIRST, load-bearing): if NEGATIVE≠DEGENERATE, or POSITIVE≠HAS-HEADROOM, or MIDDLE is unstable across runs/blind-re-run → STOP and record the instrument-broken finding; do NOT screen any real candidate on a broken instrument.
- If no deterministic check is writable even for the controls → STOP (the screen method is infeasible — itself a finding).
- Before any "termination" language in the verdict: confirm the engineered-favorable anchor also screened DEGENERATE; otherwise the verdict is PARKED, not terminated.

## Assumptions

- A deterministic per-anchor check is writable for the three controls and ≥3 candidates. If false for an anchor: that anchor is DISQUALIFIED and the disqualification is recorded as a finding (an anchor with no deterministic check is not measurable downstream either).
- The bare clean-room subagent is a valid harness-OFF proxy ONLY for pure-reasoning anchors (no tool dependency). If a candidate's correct behavior could require a tool the subagent lacks: quarantine it and state why, rather than screen it.
- n = 5 with the ≥4/5 same-clause threshold stabilizes the middle-band verdict. If the MIDDLE control is unstable across the 5 runs or on the blind re-run: STOP — increasing n or loosening the threshold to force stability is forbidden (that is the retry-until-green path the asymmetric cost prohibits).
- A single canonical OFF prompt per anchor is defensible as neutral phrasing. If a candidate's headroom looks prompt-sensitive: require it to survive ≥2 paraphrases before classifying HAS-HEADROOM, else quarantine as prompt-luck.
