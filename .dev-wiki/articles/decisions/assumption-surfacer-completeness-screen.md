---
title: "Assumption-Surfacer Completeness Screen (Phase 80)"
aliases: ["assumption-surfacer-completeness-screen", "phase-80-assumption-screen", "assumption-gate-screen"]
category: decisions
tags: [assumption-interrogation, blind-yes, surfacer, completeness, screen, scope-anchored, framing-pass, ledger, dogfood, cost-of-error]
parents: [phase-80-assumption-surfacer-completeness-screen]
created: 2026-06-08
updated: 2026-06-08
source: plan
confidence: low
status: active
---

# Assumption-Surfacer Completeness Screen (Phase 80)

## Context
A handover doc proposed re-shaping the dev-plan human gate from approving the *approach* (a conclusion
the maintainer can't evaluate → blind-yes) to taking an **accept / reject / don't-know** position on the
plan's load-bearing **assumptions** — plus a cross-phase assumption ledger, a literacy-payout loop, an
exogenous interrogator, and a smoothness/agreement "signature detector". Origin: a conversation about
upskilling Jake's AML team to catch domain errors in agent outputs; the scarce thing is a general
*assumption-interrogation reflex* that needs *just enough domain floor to bite*, and Jake is patient-zero
(he blind-approves nana-dev-kit plans because he lacks the software floor → "OK-not-great" product).

The plan was interrogated live by surfacing its own load-bearing assumptions as a forced
accept/reject/don't-know gate (the mechanism eating its own dogfood, rep 1). Jake's verdicts:
- **A1 Engagement** (forced verdict engages cognition, not slower clicks) → **ACCEPT**.
- **A2 Surfacing** (can you trust the agent-chosen assumption *set*?) → **REJECT** — "if I can't trust
  the set, the gate is worse than nothing; solve set-completeness before building anything."
- **A3 Ledger** (revisit-status gets filled, not write-only) → **ACCEPT** (conditional on a debrief
  forcing-function).
- **A4 Substrate** (nana-dev-kit is the right vessel despite the retracted AML-transfer proxy) → **ACCEPT**.

The single REJECT (A2) is the load-bearing signal and reshapes the phase.

## Decision
**Phase 80 is a screen, not a build.** Jake's A2 reject promotes set-completeness from *mitigation* to
*blocking precondition*. So Phase 80 builds and **validates** a scope-anchored assumption surfacer — it
must earn trust against controls *before* the gate/ledger/all-accept block (all accepted, mostly
relocation) are built in **Phase 81, gated on the verdict**. Surfacing approach: **scope-anchored +
screen** (over "reconstruction-delta" and "validate+backstop-only").

**The agent-internal adversarial approach review (6/10, revise) reshaped the design.** It found the
CRITICAL hole the convergence buried: a "real-history corpus" can only contain assumptions *someone
already noticed and labeled*, so the screen as first drafted could not distinguish "surfacer recovers
what humans already labeled" from "surfacer recovers what humans would have **missed**" — which is the
*entire point* of A2. Author-selected ground truth re-imports the measured bias. (Distinct from the
Ph66/69 plants≠soft-reals ghost.) Three further findings adopted: (b) completeness-by-construction covers
only *scope-local* assumptions; the **framing-level** class Jake actually rejected on (A1/A4 map to no
file) falls to the framing pass, which has **no** completeness guarantee — so it cannot be "co-primary"
under one verdict; (c) a `require`-ERE measures *vocabulary*, not recovery, for paraphrase-heavy NL
assumptions (the selftest only proves the scorer classifies fixtures written to its own regex); (d)
n=5/≥4-of-5 is cargo-culted from the anchor-screen's different (Bernoulli-fact) variance structure.

**Reframe (the screen's real question):** *does the scope+framing surfacer **beat a blind
(outcome-unaware) baseline** at recovering assumptions the project's own history later **proved**
load-bearing?* Ground truth becomes **outcome-determined and mechanically extracted** — confidence
revisions, supersessions, blocked tasks, later-phase contradictions (externally-determinate; honors
"deterministic validators at boundaries"), NOT author-selected. The surfacer must *exceed* unaided human
noticing, not match a curated list. This is structurally the **amplifier program's** question (harness vs
bare baseline) — and `surfacer ≈ blind-baseline` is a legitimate possible outcome (a 5th amplifier null →
TERMINATE), which the pre-registration states up front rather than hiding.

**Lead with a cheap circularity-escape SPIKE as a hard gate (T1).** Before building anything, attempt to
construct non-circular ground truth (mechanical outcome-labels + a blind baseline) for ~3 real past
phases. **If it cannot be set up without circularity → `^PROGRAM-VERDICT: INSTRUMENT-DEAD`, STOP — for
the cost of one task.** That *is* "solve set-completeness before building anything," cheapest-first.

**Controls/scoring (post-spike):** cost-sort **adversarial control** (plant the load-bearing assumption on
a deliberately *under-rated-cost* scope item — catches the burial-relocates-to-the-cost-sort attack); a
**two-track verdict** (scope = completeness-property + recovery; framing = recovery-only, explicitly
weaker); a **variance-derived bar** (re-derived from the surfacer's own per-run variance, not inherited);
entity-presence recovery scoring where checkable. `check.sh` cloned from
`eval/amplifier/anchor-screen/check.sh`, **NO LLM in scoring**, `--selftest`. Pre-registration committed
BEFORE runs, ancestor-guarded. Labeling fork (mechanical vs Jake-adjudicates-the-delta) is **resolved by
deferral**: the spike tests the mechanical approach; Jake-adjudicates-delta is the fallback if mechanical
labels prove too sparse.

Home: new repo-only line `eval/assumption-screen/` (the amplifier program is closed; NOT wired into
install.sh / Makefile / make test / make eval). dev-plan SKILL.md, the ledger, and the all-accept block
are **untouched** in Phase 80.

## Consequences
- Honors "solve it before building anything": the spike can return INSTRUMENT-DEAD before any scorer is
  built; a TRUSTWORTHY verdict now means "beats the blind baseline against outcome-determined ground
  truth," not "recovers a list I wrote."
- **Known limit (pre-registered, necessary-not-sufficient):** mechanical outcome-labels only capture
  assumptions that left a *trace* (a revision/supersession/contradiction); silently-correct buried
  assumptions that never bit leave no label. The Phase-81 ledger's missing-assumption calibration events
  are the detect-after backstop. The regress ("something is always the last unchecked checker") is not
  closed.
- Cuts from the handover: the smoothness/agreement **signature-detector** (re-imports Ph66/69 +
  gameable; cost-of-error sort already gives "fire on high-cost ones"); the rewarded **exogenous
  interrogator** as a separate engine (deferred — but *surfacing* runs in a clean/adversarial context,
  since the planner must not choose which of its own assumptions to expose).
- The four live verdicts seed the Phase-81 assumption ledger; the mechanism passed its own first
  all-accept smell test (1 reject / 4).

Rejected alternatives: build the full gate now (A2 reject blocks it); reconstruction-delta surfacing
(heavier, reconstructor has its own blind spots); validate+backstop-only (lighter, but Jake set a higher
bar); author-selected real-history ground truth (the review's CRITICAL — circular).
