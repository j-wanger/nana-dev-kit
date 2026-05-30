<!-- nana:approved 2026-05-30 -->
# Spec: Phase 71 — Cross-Boundary Retention Headroom Screen

## Objective

Build AND run a pre-registered, deterministic screen that decides — as the cheapest go/no-go — whether the harness's cross-compaction state machinery has any **retention headroom**: across a context-loss (compaction) boundary, does the harness state file *recover* an earlier-established, counter-default project decision that a bare agent (residual context only) *drops*? The verdict gates whether a full multi-turn measurement rig is worth building in a later phase.

## Context

A multi-phase research program (the "amplifier" line, Phases 63–70) asked whether the Nana harness measurably improves a frontier base model's decisions. For SINGLE-decision one-shot tasks the answer was no: Phase 70's anchor-headroom screen found that `claude-opus-4-8` (bare) produces the correct AML behavior unprompted on every realistic anchor; measurable headroom appeared ONLY on a fictional fact the model could not know. Single-decision harness headroom lives only in *unknown facts* (a retrieval problem) — the single-decision-anchor line was TERMINATED.

Phase 70 named two surviving, untested avenues. This phase executes the one Jake selected (AskUserQuestion, 2026-05-30): **long-horizon / multi-turn process-retention**, whose `decidable-when` was "a multi-turn substrate exists." It is the multi-turn analog of the Phase-70 screen: the "unknown" is no longer a fictional fact but an *earlier-established counter-default decision* the now-compacted conversation produced and that the model would not generate by default.

The confound core, quantified during planning: Claude Code's own compaction summary is NOT a blank slate — the single real compaction record in the local transcript corpus is an 11,470-char summary that references phases, `active-phase`, and `tasks.md` unprompted. So the OFF baseline already carries substantial project context, and the screen must isolate the *increment* the harness state files add on top of that native summary. Substrate is scarce (1 of 64 transcripts carries a structured boundary; 0 of the A/B testbeds do), so a real boundary cannot be sampled at n=5 — the boundary is SYNTHESIZED (Jake-approved). To keep the synthetic boundary representative, the OFF residual is produced the way real compaction produces it (a model-authored summary), not by manual truncation, so OFF is not artificially starved.

## Scope

### In scope
- A NEW repo-only tree `eval/amplifier/retention-screen/`, cloning the Phase-70 `eval/amplifier/anchor-screen/` apparatus (`check.sh`, `pre-registration.md`, `leak-check.sh`, `leak-vocab.txt`, `prompts/`, `checks/`, `verdicts/`, `runs/`, `fixtures/`, `screen-record.md`).
- Per item: a pre-registered, shasum-pinned **synthetic transcript**; a **model-authored compaction summary** of it (the OFF residual substrate, frozen once generated); an OFF prompt (residual only) and an ON prompt (identical residual + an in-context `[HARNESS STATE]` block carrying the dropped constraint + the recovery instruction to honor it).
- A **bare-derivation gate** (zero context) run first to discard candidates the model produces cold.
- A differential verdict layer over two n=5 aggregates: `DEGENERATE` / `HAS-HEADROOM` / `INERT` / `UNSTABLE` (+ a per-run `VOID` for leak-detected trials).
- 3 controls (negative, positive, middle) run before candidates; ≥2 candidates including ≥1 **motivated** counter-default (discoverable rationale) and the engineered-favorable/arbitrary backstop.
- Pre-registration committed in a SEPARATE commit that is a git ancestor of the verdict commit; a `screen-record.md` with a single anchored `^PROGRAM-VERDICT:` and the no-harness-value disclaimer; a finalized decision article.

### Out of scope
- Editing the cross-compaction machinery — it is the SUBJECT of measurement (`templates/.claude/hooks/{pre-compact,post-compact,session-start}.sh` + `session-start.d/*`, the recovery protocol in `.claude/rules/dev-wiki-hooks.md`, the memory bridge, the always-loaded rule files).
- Fixing the discovered dead `.session-anchor` read-branch in `post-compact.sh` (recorded as a follow-up; fixing it here violates freeze-the-subject).
- A live forced-`/compact` run; any LLM/embedding/fuzzy logic in the SCORING path (a model IS used to author the summary substrate, then frozen); wiring into `install.sh` / `Makefile` / `make test` / `make eval`.
- Any Phase-72 live measurement rig (only authorized if a MOTIVATED NATURAL candidate screens HAS-HEADROOM).

## Approach

Clone the Phase-70 apparatus that worked and adapt the verdict layer to a two-condition differential. The single-run `.check` semantics (`run_check`: a run PASSES iff every `require` ERE matches and no `forbid` ERE matches; report the primary failing clause-id) port **verbatim**; the `.check` clauses are frozen pre-run (no post-hoc regex widening). The aggregation layer is NEW: it ingests an OFF n=5 batch and an ON n=5 batch for one item and emits a differential verdict.

**Substrate, representative-by-construction.** For each item, author a synthetic transcript in which a counter-default project decision is established, then generate the OFF residual as a *model-authored compaction summary* of that transcript (the real compaction mechanism) plus the last-K verbatim turns. Freeze and shasum-pin both the transcript and the summary. Require (leak-check) that the resulting summary does NOT restate the target decision — if the model's own summary KEEPS it, the boundary is not lossy for that decision and the item is recorded DEGENERATE-by-summary-robustness (honest, not discarded). The synthetic transcript is pinned BEFORE summary generation; the summary is accepted as produced — no iterating the transcript until the summary drops the decision (that would be retrofitting).

**Counter-default by construction.** Each item is built so the model's *default* (decision absent from context) VIOLATES the decision — that property is what lets OFF FAIL, the precondition for any headroom. OFF and ON prompts are byte-identical except ON appends one delimited `[HARNESS STATE]…[/HARNESS STATE]` block stating the decision plus the instruction to honor it; the state is provided IN-CONTEXT (not a file the agent must choose to read) so an ON failure means "read but not honored," never "never read." Both conditions forbid tools.

**Bare-derivation gate (cheapest falsification, runs first).** Before any OFF/ON spend, run the continuation task with ZERO context (no summary, no turns, no state) at n=5. If the model produces the decision in ≥4/5 bare runs, the candidate is the model's default → DISQUALIFIED (the Phase-70 degenerate-anchor analog); it is recorded, not screened. Only candidates that FAIL the bare gate ≥4/5 (genuinely counter-default) proceed to OFF/ON.

**Motivated vs. arbitrary — a pinned, falsifiable litmus (gates CONTINUE).** "Motivated" must be classified deterministically at T1, before runs, because it gates the strongest claim in the program. Each candidate carries a frozen **rationale probe**: a prompt that gives the model the decision's stated PREMISES (the project facts that justify it) but WITHHOLDS the decision, then asks what threshold/choice those premises imply, scored by a frozen `.check`. A candidate is **MOTIVATED** iff (a) it FAILS the bare-derivation gate ≥4/5 (the decision is NOT the model's cold default) AND (b) its rationale probe PASSES ≥4/5 (the decision IS derivable once the dropped premises are supplied). It is **ARBITRARY** iff it fails the bare gate but the rationale probe also FAILS (no discoverable rationale — a pure unknowable, the Phase-70 fictional-fact analog). The motivated case is genuine process-retention: the compaction summary dropped BOTH the premises and the conclusion, and the harness state file re-supplies the conclusion the model would have re-derived had it kept the premises. Both the probe and its `.check` are shasum-pinned in `pre-registration.md`. Because no automated litmus is infallible, a CONTINUE additionally requires explicit human confirmation at T5 (the rig is expensive — the screen recommends, the human authorizes).

**Differential verdict (over two n=5 aggregates, consensus-by-clause):**
- **DEGENERATE** — OFF PASSES ≥4/5. The residual context (the model-authored summary + last-K turns) is enough to recover/honor the decision; the harness adds nothing. (Leak-check guarantees the OFF residual does not restate the decision, so an OFF-pass is genuine re-derivation, not a planted leak.)
- **HAS-HEADROOM** — OFF FAILS ≥4/5 on the SAME clause-id AND ON PASSES ≥4/5. The harness state recovers a counter-default decision the residual dropped.
- **INERT** — OFF FAILS ≥4/5 on its consensus clause-id AND ON ALSO FAILS ≥4/5 **on that SAME clause-id**. The harness state is present in-context but the model still does not honor *that specific recovered decision* — a more fundamental finding than candidate degeneracy. If ON instead fails ≥4/5 on a DIFFERENT clause (it honored the recovered decision but broke another required element), the verdict is UNSTABLE/quarantine, NEVER INERT — INERT must mean the recovered constraint was specifically not honored, because it escalates to the consequential INERT-MACHINERY ladder rung.
- **UNSTABLE** — anything else, including the n=5 dead zone (OFF 2/5–3/5). Quarantine; does NOT count as HAS-HEADROOM and does NOT advance the ladder (no rounding toward "the harness helped," no retry-until-green).
- A single run is **VOID** (excluded from its batch, batch re-noted) only if a per-run leak-check trips on that run's frozen input — a guard against a planted leak silently scoring as PASS.

**Controls-first checkpoint (any misbehavior ⇒ STOP, instrument-broken):**
- **negative** — the decision PRESENT in the residual summary ⇒ MUST screen DEGENERATE (OFF passes; validates the checker does not false-positive headroom when residual suffices).
- **positive** — an *arbitrary* counter-default rule present ONLY in the `[HARNESS STATE]` block, absent from residual ⇒ MUST screen HAS-HEADROOM (OFF fails, ON passes). THE load-bearing control: it proves the ON pathway works — a state-block constraint is honored when it is the sole source. If it screens INERT, the machinery is inert (verify ON-prompt construction first, then report the inert-machinery finding as the phase result). NOTE: because this control is arbitrary/unknowable, its HAS-HEADROOM validates the *mechanism*, not process-retention value — that distinction is what the motivated candidate decides (see ladder).
- **middle** — a borderline counter-default decision ⇒ MUST NOT FALSE-POSITIVE (read HAS-HEADROOM) in either of two independent n=5 batches (`stability: STABLE`), per the Phase-70 binomial-validity rule (no-false-positive is the property that matters; "must reproduce UNSTABLE" would self-halt a working instrument).

**Graded verdict ladder (pre-committed, un-loosenable post-hoc).** Precondition: at least ONE candidate must reach a genuine OFF-fail (a lossy boundary — the model-authored summary actually dropped its decision); otherwise the candidate-level rungs are vacuous (see TERMINATE-by-summary-robustness).
- **CONTINUE** — a candidate classified MOTIVATED by the pinned T1 litmus (bare-gate FAIL ≥4/5 AND rationale-probe PASS ≥4/5) screens HAS-HEADROOM ⇒ genuine process-retention signal. A later phase builds a real multi-turn rig — but CONTINUE is RECOMMENDED only; it requires explicit human authorization at T5 (never auto-fired).
- **PARKED** — no motivated candidate HAS-HEADROOM, but an ARBITRARY/engineered-favorable candidate (or only the positive control) is ⇒ the Phase-70 "headroom only on unknowables" result in multi-turn clothing, not process-retention; park pending new priors.
- **TERMINATE** — the engineered-favorable backstop yields no headroom: it screens DEGENERATE (OFF-pass) OR is bare-disqualified (the model produces it cold ≥4/5) — both mean the model handles even the engineered case without the harness ⇒ the residual summary/model re-derives everything; the cross-boundary-retention screen line is closed.
- **TERMINATE-by-summary-robustness** (distinct) — NO candidate reached a lossy boundary (every candidate's model-authored summary preserved its decision ⇒ every candidate DEGENERATE-by-summary-robustness) ⇒ the native compaction summary retains project decisions on its own, so there is nothing for the harness state to recover. An honest finding about the summary, not a vacuous null. (The positive control still validates the mechanism, since its arbitrary rule is never in any transcript.)
- **INERT-MACHINERY** (distinct) — the positive control screens INERT ⇒ the harness state is present in-context but not honored even as sole source; report separately (a "harness not honored" result, not a "harness not needed" result).

### Domain Research Questions
1. Does a model-authored compaction summary of a synthetic transcript naturally DROP a counter-default project decision (making the boundary representatively lossy), or does it preserve such decisions — and how does the decision's prominence in the staged transcript change that?
2. Does the pinned rationale-probe litmus (the decision is derivable from its withheld premises) cleanly separate MOTIVATED from ARBITRARY candidates in practice, or do real project decisions blur it (partially derivable) — and how should a partial rationale-probe result (2–3/5) be recorded so it cannot quietly upgrade an arbitrary candidate toward CONTINUE?
3. Is the right "no harness value" null a DEGENERATE (model self-recovers) or an INERT (model ignores the in-context state), and what empirically distinguishes a candidate's INERT from a mis-specified candidate beyond the positive control?

## Constraints (CRITICAL)

- **OFF/ON isolation confound** (the A-vs-C scar) — if OFF and ON differ in anything but the `[HARNESS STATE]` block, the differential measures the wrong thing. Guard: each ON prompt MUST equal its OFF prompt byte-for-byte plus a single appended delimited block; a committed `assert-off-on-isolation.sh` asserts the OFF text is an exact prefix of the ON text for every item.
- **Residual leak of the target decision** — if the OFF summary or last-K turns restate the decision, OFF cannot fail and the result is an artifact. Guard: `leak-check.sh` greps every OFF prompt (summary + turns + continuation task) for the target decision's pre-committed vocab and FAILS if present; a per-run leak trip marks that run VOID, never PASS.
- **Lobotomized / starved summary** — a hand-stripped summary makes ON look valuable for a reason that won't reproduce. Guard: the OFF residual is a MODEL-AUTHORED summary of a pre-pinned transcript (real mechanism), not manual deletion; its omission of the target is a property of the model's summarization, not the author's editing. A HAS-HEADROOM on a synthetic boundary earns at most PARKED, never CONTINUE (CONTINUE additionally requires the motivated-candidate condition).
- **False HAS-HEADROOM = false-continue** (the asymmetric risk; the Phase-58 n=1 scar) — Guard: consensus-by-clause (≥4/5 same clause-id for OFF-fail) AND ON-pass ≥4/5; positive control validates both directions before any candidate; the n=5 dead zone is UNSTABLE, not soft-HAS-HEADROOM; n=5 exactly, pre-registered.
- **False victory by rediscovering unknowables** — headroom only on arbitrary decisions = the Phase-70 result, not process-retention. Guard: "motivated" is fixed at T1 by a pinned, falsifiable rationale-probe litmus (bare-gate FAIL ≥4/5 ∧ rationale-probe PASS ≥4/5), not an author label; CONTINUE requires a MOTIVATED candidate HAS-HEADROOM AND explicit human authorization; arbitrary/engineered-only headroom ⇒ PARKED, explicitly named "unknowables, not retention."
- **Vacuous candidate verdict from an all-robust boundary** — if every model-authored summary preserves its decision, no candidate exercises the ON pathway and a PROGRAM-VERDICT would be empty. Guard: ≥1 candidate must reach a genuine OFF-fail for any candidate-level rung; otherwise the named `TERMINATE-by-summary-robustness` outcome is recorded (the honest finding that the native summary is decision-robust), asserted by an exit criterion.
- **Degenerate-by-default candidate** — Guard: the bare-derivation gate (zero context, n=5) runs FIRST; a candidate the model produces cold ≥4/5 is DISQUALIFIED before OFF/ON.
- **INERT misread as DEGENERATE** — opposite implications (model doesn't need vs. model ignores the harness). Guard: the verdict layer reads BOTH aggregates; OFF-fail + ON-fail ⇒ INERT; the self-test plants an INERT case.
- **Retrofitted verdict / post-hoc-tuned matcher** — Guard: `pre-registration.md` (candidate set, both OFF and ON prompts + every transcript + summary shasum-pinned, all `.check` files, thresholds, ladder, bare-gate results) committed in a SEPARATE commit; `git merge-base --is-ancestor <prereg> <verdict>` must pass; `check.sh --verify-pins` recomputes every shasum; predicates are presence/absence of pre-named tokens (ERE), no similarity threshold.
- **Scope drift into the machinery** — Guard: the frozen set (`pre-compact.sh`, `post-compact.sh`, `session-start.sh`, `session-start.d/*`, `emit-proxy-vector.sh`, `measurability-gate.sh`, `anchor-screen/`, code under `eval/comparison|corpus|reasoning`) MUST be `git diff`-empty at T5.
- **No-LLM scoring** — Guard: a token sweep over the scoring path (`check.sh`, `leak-check.sh`, `assert-off-on-isolation.sh`) finds no model/judge/embedding invocation; `make test` count unchanged at 19, `make eval` 52/52. (Model use is confined to one-time summary-substrate authoring, frozen + pinned thereafter.)

## Success Vision

A cheap, decisive, pre-registered screen that either (a) surfaces the FIRST positive harness-value signal in the entire amplifier program — a MOTIVATED counter-default decision the harness state recovers across a representative boundary that the model's own summary drops, earning a CONTINUE — or (b) honestly TERMINATES, PARKS (unknowables-not-retention), or reports INERT-MACHINERY, with the same graded-ladder rigor as Phase 70. Excellence is methodological honesty: a verdict no reader can dismiss as retrofitted, confounded, starved, or a rediscovery of the program's own prior negative; a disclaimer that bounds the claim to "lift is possible"; zero new production code. A null is a real, publishable result.

## Exit Criteria (machine-checkable)

- [ ] `eval/amplifier/retention-screen/check.sh --selftest` exits 0 (planted PASS/FAIL classify; differential DEGENERATE/HAS-HEADROOM/INERT/UNSTABLE cases incl. a same-clause→INERT plant AND a cross-clause-ON-fail→UNSTABLE plant; pins verify)
- [ ] `eval/amplifier/retention-screen/check.sh --verify-pins` exits 0 (every transcript, summary, OFF prompt, and ON prompt shasum in `pre-registration.md` matches)
- [ ] `eval/amplifier/retention-screen/leak-check.sh` exits 0 (no target-decision vocab and no harness-rule vocab in any OFF prompt)
- [ ] `eval/amplifier/retention-screen/assert-off-on-isolation.sh` exits 0 (every OFF prompt text is an exact prefix of its ON prompt text)
- [ ] `git merge-base --is-ancestor <pre-registration commit> <first verdicts/ commit>` exits 0
- [ ] `grep -c '^PROGRAM-VERDICT:' eval/amplifier/retention-screen/screen-record.md` returns exactly 1, and the no-harness-value disclaimer string is present
- [ ] The bare-derivation gate result AND a motivated|arbitrary classification (with rationale-probe result) are recorded for every candidate; 3 controls present with results matching expectation (negative→DEGENERATE, positive→HAS-HEADROOM, middle→STABLE); ≥2 candidates screened with a recorded verdict
- [ ] `check.sh --stability <middle-b1-verdict> <middle-b2-verdict>` prints `stability: STABLE`, and exactly 10 middle-control run files exist (two independent n=5 batches actually ran)
- [ ] The engineered-favorable backstop either screens DEGENERATE or is recorded bare-disqualified (the TERMINATE rung is anchored, not silently absent)
- [ ] ≥1 candidate reached a lossy boundary (OFF-fail) OR `screen-record.md` records the verdict as `TERMINATE-by-summary-robustness` (no candidate-level rung is vacuous)
- [ ] `make eval` reports 52/52; `make test` runs the UNCHANGED 19 scripts (no README script-count bump)
- [ ] The frozen set is `git diff`-empty (`git diff --quiet -- <frozen paths>`)

## Checkpoints

- **T1 (freeze + pre-register):** apparatus, pinned transcripts + model-authored summaries, OFF/ON prompts, `.check` files, bare-gate results, and `pre-registration.md` committed in a SEPARATE commit BEFORE any OFF/ON run; `--verify-pins` + leak-check + isolation assertion green. Report and proceed.
- **T2 (controls — load-bearing):** run the 3 controls. If the positive control is not HAS-HEADROOM (esp. INERT), the negative is not DEGENERATE, or the middle false-positives → STOP, instrument-broken / inert-machinery; report before any candidate run.
- **T3 (candidates):** run ≥2 candidates (≥1 motivated) only after controls pass. A candidate that fails the bare-derivation gate at T1 is recorded DISQUALIFIED, not run here.
- **T4 (aggregate):** apply the graded ladder → `PROGRAM-VERDICT` + `screen-record.md` + finalize decision article.
- **T5 (regression):** `make eval` 52, `make test` unchanged 19, frozen set git-diff-empty, no-LLM token sweep clean, disclaimer present. If a MOTIVATED candidate is HAS-HEADROOM → STOP and surface the CONTINUE recommendation (do not auto-authorize a rig).

## Assumptions

- The Phase-70 `anchor-screen/check.sh` single-run semantics (`run_check`, `.check` ERE format, `--verify-pins`) port without change. If false: keep `run_check` verbatim and build only the differential aggregation fresh.
- A model-authored compaction summary of a staged transcript can be made to naturally drop a counter-default decision. If false (every summary preserves it): items screen DEGENERATE-by-summary-robustness — itself an honest finding that the native summary retains decisions (a no-headroom result), recorded as such.
- A counter-default decision (motivated and arbitrary) can be made checkable in a single post-boundary output via `require`+`forbid`. If false: narrow to one-action checkable decisions and NAME the scoping limitation in `screen-record.md`.
- The model treats an in-context `[HARNESS STATE]` block as authoritative when it is the sole source (the positive control tests this). If false (positive control INERT): STOP and report the inert-machinery finding — that IS the phase result.
- A model-authored synthetic boundary approximates real compaction closely enough for the retention question. If false: a HAS-HEADROOM earns only PARKED, never CONTINUE; the graded ladder absorbs it.
