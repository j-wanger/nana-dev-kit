---
title: "Phase 70: Single-Decision Anchor-Headroom Screen"
aliases: [phase-70, anchor-headroom-screen, amplifier-anchor-screen]
category: phases
tags: [eval-validity, amplifier-vision, measurement, anchor-selection, headroom, phase-70]
parents: []
created: 2026-05-30
updated: 2026-05-30
source: plan
status: completed
ceremony: standard
scope: ["eval/amplifier/anchor-screen/*", "specs/*", ".dev-wiki/articles/*"]
entry_criteria: "Phase 69 delivered (measurability-gate.sh = NOT-MEASURABLE; the anchor is degenerate and the detector is blind on real data). Anchor selection is upstream of measurement, so the next plannable step is screening for anchor existence — not the gated live run, not predicate-repair-first (which is structurally blocked on the current degenerate anchor)."
exit_criteria: "check.sh --selftest green (classifies planted PASS/FAIL/HEDGED + verifies prompt-shasum pins) + leak-check.sh green; pre-registration commit is a git ancestor of the first verdict commit; controls-first checkpoint passes (neg=DEGENERATE, pos=HAS-HEADROOM, middle=STABLE) OR records FINDING: INSTRUMENT-BROKEN; ≥6 verdict files each carrying an anchored ^verdict: token; a single anchored ^PROGRAM-VERDICT: (CONTINUE|PARKED|TERMINATE); no harness_lift=/VERDICT: harness token + 'lift is possible' disclaimer present; emitter + measurability-gate + eval/comparison|corpus|reasoning git-diff-empty; make eval 52/52; make test green at the UNCHANGED 19-script count; decision article names the Phase-71-or-disposition handoff"
---

# Phase 70: Single-Decision Anchor-Headroom Screen

## Objective

Build AND RUN the cheapest decisive go/no-go for the whole amplifier-measurement program (Phases 65–69 mostly negative; Phase 69 found the live off/on run premature because the anchor is degenerate AND the detector is blind). Screen anchor EXISTENCE: does ANY non-commodity single-decision PURE-REASONING anchor have real OFF-baseline headroom — the harness-OFF bare subagent OMITS the correct behavior unprompted, so the harness could plausibly help? This inverts the Phase-69 handoff order (anchor selection is upstream of measurement; predicate-repair-first is structurally blocked on the current degenerate anchor). NO harness-ON run. See [[amplifier-anchor-headroom-screen]].

## Scope

Files and modules affected:
- `eval/amplifier/anchor-screen/check.sh` — the deterministic named-clause checker + consensus rule (≥4/5 same clause-id) + `--selftest` + `--verify-pins`. NO LLM/judge.
- `eval/amplifier/anchor-screen/leak-check.sh` + `leak-vocab.txt` — assert each frozen OFF prompt smuggles no harness injected-rule vocabulary.
- `eval/amplifier/anchor-screen/pre-registration.md` — candidates (3 controls + ≥3 prior-seeded single-decision candidates), each with `base-model:`, a frozen `prompt-shasum:`-pinned OFF prompt, and a per-anchor named-clause check. COMMITTED before any run.
- `eval/amplifier/anchor-screen/fixtures/` — planted PASS/FAIL/HEDGED outputs for `check.sh --selftest`.
- `eval/amplifier/anchor-screen/verdicts/*.md` — per-anchor frozen verdict files (anchored `verdict:` token, per-run pass/fail, consensus clause-id, `prompt-shasum:`).
- `eval/amplifier/anchor-screen/screen-record.md` — the graded `PROGRAM-VERDICT:` + candidate count + no-harness-value disclaimer.
- `.dev-wiki/articles/decisions/amplifier-anchor-headroom-screen.md` — the decision + Phase-71/disposition handoff.

**Out of scope (do NOT touch):** any harness-ON run / lift estimate (a separate gated phase); `eval/amplifier/emit-proxy-vector.sh` (frozen ruler) and `measurability-gate.sh` (predicate repair is gated on this screen finding a valid anchor); CODE under `eval/comparison|corpus|reasoning`; the long-horizon / multi-turn constraint-retention anchor class (one-shot subagent can't surface its failure mode — deferred to a multi-turn substrate); hooks, `modules.json`, `settings.json`, `install.sh`; anything wired into `make test` / `make eval`.

## Tasks

5 tasks (see `tasks.md` for enriched fields):

- **T1 [M] (FIRST/checkpoint)** — pre-registration + deterministic check apparatus, RED-first. `check.sh --selftest` (classifies planted PASS/FAIL/HEDGED + `--verify-pins`), `leak-check.sh` + `leak-vocab.txt`, `fixtures/`, and `pre-registration.md` (3 controls + ≥3 candidates, each base-model + shasum-pinned OFF prompt + named-clause check). Must be COMMITTED before T2 runs (pre-registration-precedes-runs invariant). STOP if no deterministic check is writable even for the controls (method infeasible — a finding).
- **T2 [M] (load-bearing checkpoint)** — controls-first run. n=5 bare clean-room subagents per control anchor with the frozen OFF prompt only; apply `check.sh`; record `verdicts/control-{negative,positive,middle}.md` + the middle blind re-run. CHECKPOINT: negative=DEGENERATE, positive=HAS-HEADROOM, middle=UNSTABLE reproduced (`stability: STABLE`). Any misbehavior → STOP + `FINDING: INSTRUMENT-BROKEN`; do not screen candidates.
- **T3 [M]** — screen the ≥3 pre-registered candidates (n=5 each, harness-OFF, frozen prompt). Quarantine tool-gap-vulnerable (→ DISQUALIFIED + reason) and prompt-sensitive (require ≥2 paraphrases else UNSTABLE) candidates.
- **T4 [S]** — aggregate the graded `PROGRAM-VERDICT:` per the ladder (CONTINUE / PARKED / TERMINATE) + candidate count + necessary-not-sufficient disclaimer; write the decision article + Phase-71/disposition handoff. No emitter/gate/apparatus code edits.
- **T5 [S] (LAST)** — regression + scope-honesty gate: `make eval` 52/52; `make test` green at the UNCHANGED 19-script count (anchor-screen NOT a make-test gate → no README bump); frozen artifacts git-diff-empty; no-harness-value token sweep; handoff recorded.
