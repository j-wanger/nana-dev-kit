# Framing-Subagent Pilot Protocol (Track B2 deployment gate)

Per the Phase-90 direction gate, assumption **A1 was accepted pilot-gated**: the clean-
context framing subagent (`framing-subagent-prompt.md`) is built but NOT wired into
dev-plan as a default until this pilot passes. This file IS the gate.

## Why a pilot (not just ship it)

Two prior negatives in this kit:
- **Ph80** — in-kit workflow subagents inherit always-loaded `working-knowledge.md`, so a
  subagent run *inside nana-dev-kit* is not clean-context; its "independent" framing can
  recite documented answers (the leak that made the Ph80 surfacer INSTRUMENT-DEAD).
- **Ph47** — self-dialogue (same-context adversary) was net-negative; shallow
  counterarguments without novel insight.

The design bet (A1): the leak only bites kit-self-planning. In a **consuming project**
(e.g. signal-watch) the subagent has no always-loaded answer key, so clean-context framing
is genuinely clean. The pilot tests that bet where it must hold.

## Run location

A **consuming project**, NOT nana-dev-kit. signal-watch is the natural host (it ran
fable-5 and opus-4-8 on adjacent phases, so a quality read has a reference point).

## Procedure

1. Pick 3 real upcoming planning decisions in the consuming project (or replay 3 recent
   ones where the eventual outcome is now known).
2. For each, run dev-plan TWO ways, measurement-blind where possible:
   - **Control:** current dev-plan (inline T0 alternative-framing, planner holds the frame).
   - **Treatment:** same, plus the clean-context framing subagent feeding item 2/3 of T0.
3. Capture both framings verbatim. Do not score your own live session.

## Decision rule (pre-registered — set before results)

The framing subagent ships as a dev-plan default ONLY IF, across the 3 cases:
- **Question-invalidation rate:** Treatment surfaces a "the question isn't well-posed
  because X" or genuine frame-shift that the Control did not, in **≥2 of 3** cases.
- **No leak tell:** in none of the 3 does the subagent's framing recite a fact it could
  only have from an always-loaded answer key (manual check of the framing against what the
  clean context actually contained).
- **No dilution regression:** Treatment's downstream plan is not worse than Control's on
  the consuming project's own gate (the planner still converges; the extra framing didn't
  derail it).

If it passes: wire `framing-subagent-prompt.md` into dev-plan Step 12 (approach critique),
feeding the T0 alternative-framing slot. If it fails: keep it staged; the inline T0 +
B1 reframe-absorption beat remain the shipped mechanism. Either way, record the verdict
here — a negative result is a valid, publishable outcome (it bounds where context-shaping
recovers model-intrinsic behavior).

## Status

- [ ] Pilot run (3 cases, consuming project)
- [ ] Decision rule evaluated
- [ ] Verdict recorded + (if pass) wired into dev-plan
