# Screen Record — Assumption-Surfacer Silent-Class Screen (Phase 80)

PROGRAM-VERDICT: INSTRUMENT-DEAD

(Closed vocabulary, frozen in `pre-registration.md`. INSTRUMENT-DEAD = a control failed → the screen
yields no valid build/cut conclusion. Here: the clean-context premise failed for the SURFACER condition.)

## What failed
The three REAL silent-class fixtures (mcp-cwd, line-cap, cascade) are nana-dev-kit's OWN documented
failures; their buried assumptions are written verbatim in always-loaded `.claude/rules/working-knowledge.md`.
The T5 workflow subagents ran INSIDE this repo and inherited that context. The SURFACER prompt's
infrastructure-enumeration triggered retrieval of those documented answers: it leaked project-specific
facts (Phase numbers, working-knowledge specifics) on **4/5, 5/5, 5/5** of the three real cases, and
**0/5** on the two cases NOT in working-knowledge (costsort-adversarial, negative). The headline
SURFACER>NAIVE result (line-cap, 5/5 vs 0/5) is an artifact of SURFACER reciting "session-start.sh line
cap 70→137, Phase 22" from working-knowledge — not surfacing it from the plan. The clean-context premise
(both conditions reason only from the plan) is therefore violated for SURFACER on exactly the cases that
matter. See `verdicts/summary.md`.

## What the run nonetheless establishes (informative-null, not nothing)
1. **The leak IS the amplifier-null, caught in the act.** With the harness present, the "surfacer"
   recovers documented decisions by RE-PRESENTATION; on the two cases the harness does not document, it
   had nothing to recall (leak 0/5). This is the Ph70/71/77/78 finding in its sharpest form — and the
   Ph66/69 representativeness lesson re-confirmed: you cannot measure assumption-surfacing inside the very
   project whose working-knowledge documents the test answers.
2. **The clean signal points DEGENERATE.** NAIVE ran clean (leak ~0/5) and recovered 3/4 silent-class
   assumptions by pure reasoning from the plan; the one fully-clean comparison (costsort-adversarial,
   0 leak both conditions) was BOTH-CATCH. The project's silent failures were silent because nobody ASKED
   at planning time — not because the assumptions are unsurfaceable. A naive "list the load-bearing
   assumptions, cost-sorted" prompt surfaces them.
3. **Residual, genuinely open:** the ONE place NAIVE cleanly missed (line-cap = accretion/budget class) is
   exactly where SURFACER's leak was strongest, so whether scope-anchoring GENUINELY helps on the
   accretion class — independent of the leak — is UNMEASURED.

## Consequence for Phase 81 (the gate build)
- A2's demand ("validate set-completeness before building") cannot be cleanly met by THIS run. But the
  combined evidence — the T1 spike, NAIVE-clean recovering 3/4, the one clean BOTH-CATCH — converges on:
  **a naive clean-context surfacer is strong; the elaborate scope-anchored machinery is NOT shown to earn
  its complexity** (its only apparent edge was a leak artifact).
- Recommendation: Phase 81 ships the **simplest gate** — a one-line clean-context "list the plan's
  load-bearing assumptions, cost-sorted" surfacer feeding accept/reject/don't-know — and leans on the A3
  ledger (detect-after) for the silent class, NOT on pre-validation. This is the "validate+backstop"
  resolution, now earned: pre-validating silent-class completeness is either trivial (naive already does
  it) or unmeasurable-here (the leak).
- The ONLY clean way to test the accretion-class residual is a truly clean context — a CONSUMING project
  that does not carry nana-dev-kit's working-knowledge (the recurring amplifier requirement). Whether that
  re-run is worth it is a user call; the prior (spike + this run's clean signals) is DEGENERATE.

## Apparatus / provenance
- Pre-registration committed `86d8584` BEFORE runs; ancestor of HEAD (re-verified at T6).
- Repo-only `eval/assumption-screen/`; NOT wired into install.sh/Makefile/make test/make eval.
- 50 runs (5 fixtures × 2 conditions × n=5) via the T5 workflow; outputs in `runs/`, scored by `check.sh`
  (NO LLM in scoring; `--selftest` green); leak audit + per-case classification in `verdicts/summary.md`.
- Honest limit (pre-registered): mechanical R5 labels only capture eventually-caught silent failures; the
  always-on silent class remains beyond any in-kit measurement → the A3 ledger is its only backstop.
