---
title: "Frontier Positioning Sweep — External Arm of the Shrink/Direction Decision (Phase 97)"
aliases: [frontier-positioning-sweep, phase-97-sweep, frontier-sweep, companion-research-rung-a]
category: decisions
tags: [strategy, positioning, frontier, companion, research, amplifier-program, subtraction, roadmap]
parents: [phase-97-frontier-positioning-sweep]
created: 2026-06-21
updated: 2026-06-21
source: plan
confidence: high
---

## Context

The maintainer reopened "shrink or not to shrink" with an explicit constraint: *stop deciding it
in isolation*. Every amplifier-null verdict (Ph70/71/77/78/80) was self-referential — the kit
measuring itself against a bare frontier model — and the maintainer named that isolation as the
limitation. The proposal: a local-only **companion** that reads where the agent-harness / agent-tooling
frontier is actually converging, to inform the direction with EXTERNAL signal.

Two prior decisions constrain this:
- **[[strategic-inflection-review]]** (Ph92) set the frame as **product for consumers** and committed
  to "re-measure-once-then-shrink." The internal arm of that re-measure already ran.
- **[[memory-layer-disposition]]** (Ph95, delivered the same day) is the internal re-measure's result:
  it **REVERSED the shrink premise** — memory-mcp-layer KEEP, both writers KEEP, enforce-memory
  REDESIGNED (not retired), trim-trials CONFIRMED. So the biggest shrink candidate is adjudicated
  toward KEEP on the kit's own clean evidence. The frontier sweep is the **external** arm, and it
  lands precisely on the one avenue the amplifier program named as never-tested: retrieval of genuinely
  **post-cutoff / proprietary** signal a bare model cannot hold in-parameter (which also makes the
  Ph59 "research-injection is net-negative" finding non-binding — that was about topics the model
  already knew).

A de-risking ladder was chosen over the maintainer's full bundle (research pipeline + 24/7 opencode
workers + eventual trading): **rung A = this one-shot sweep**; rung B (standing pipeline) / rung C
(opencode workers under nana-written contracts, referencing signal-watch) / rung D (generalization)
are explicitly LATER phases. The subtraction test split the cheap, decision-relevant rung from the
expensive, speculative ones so the former isn't held hostage by the latter.

## Decision

Run a **pre-registered, one-shot Frontier Positioning Sweep** whose verdict is read MECHANICALLY
against a decision rule frozen before any research. Three maintainer positions at the direction
(assumption) gate, 2026-06-21 (ledger Phase-97 block; all_accept:false):

1. **A1 REJECT → reframe layer-shrink to PRODUCT-POSITIONING.** The verdict's altitude inverts from
   inward ("which kit layers to cut") to outward ("is the kit's bet DIFFERENTIATED / COMMODITIZED /
   DIVERGENT vs the frontier"). Shrink is a downstream consequence of a COMMODITIZED verdict, not the
   axis. Consistent with the Ph92 product frame; does NOT reopen the Ph95 memory KEEP.

2. **A2 REJECT → lab artifacts PRIMARY, OSS SECONDARY.** The sweep's spine is *declared lab direction*
   (Anthropic agent SDK / cookbooks / Claude Code, OpenAI Agents SDK, Google ADK, eng blogs, papers) —
   labs productize what they validated internally. OSS repos (stars/trending) are corroboration: "is
   the community converging on the same thing." Honesty bound: internal lab harnesses stay unseen; we
   read declared direction, a strong-not-complete proxy.

3. **A3 DON'T-KNOW → down-scoped to T4.** No standing pipeline this phase regardless; T4 assesses the
   signal's half-life and *recommends* a pipeline cadence (or none) for rung B. Routed to a T4
   deliverable, not Blockers.

Four tasks, controls-first: **T1** gitignore guard (`companion/` ignored + nothing tracked, verified
BEFORE any research write — nothing leaks into the shippable kit); **T2** pre-register the frozen
instrument → `companion/research/pre-registration.md` (decision rule with falsifiable thresholds per
outcome, scoping OUT the Ph95 memory KEEP; lab-primary sweep protocol; thin-vs-thick rubric;
anti-retrofit note) — this serves as the phase's spec, a deliberate deviation (the apparatus is
gitignored, so the spec lives there not in `specs/`); **T3** run the sweep → cited `sweep-findings.md`
+ `convergence-map.md` (every cluster classified against the rubric); **T4** mechanical verdict →
`verdict.md` (one of DIFFERENTIATED / COMMODITIZED / DIVERGENT / INCONCLUSIVE, threshold-mapped) +
signal-half-life → pipeline-cadence recommendation + (if COMMODITIZED) a candidate shrink-target list
gated to a later phase.

## Consequences

- **VERDICT only — NO cut executed.** Any shrink that falls out of a COMMODITIZED verdict is a
  separate, gated phase (the kit's deregistration/removal discipline applies). Conflating "decide" with
  "execute" is the scope-creep this avoids.
- **Frozen discipline** (Ph87 three-tier authority): decision rule committed before T3, verdict read
  mechanically, no post-hoc threshold tuning. The guard against the real risk — *apparatus as
  decision-avoidance*: the pre-registered rule forces the sweep to RESOLVE, not just gather intel.
- **`companion/` is gitignored, local-only** — the de-risking ladder's home. Rungs B/C/D are future
  phases planned only if this verdict (and the T4 half-life read) justify them.
- **Honest limits**: the sweep reads *declared* frontier direction, not closed lab internals; it pairs
  with — never replaces — the kit's internal evidence (the Ph95 KEEP stands on internal grounds). An
  INCONCLUSIVE outcome is fully valid and names the resolving evidence (which would itself justify rung B).
- Local VC-durability of `companion/` (gitignored, so the kit repo won't track its history) is a known
  open question — mirrors the standing Phase-96 consumer VC-durability item; filed to Blockers, decided
  if/when rung B lands.
- Cross-links: [[strategic-inflection-review]], [[memory-layer-disposition]], [[consumer-memory-remeasure]],
  [[HEU-012]], [[prune-on-value-subtraction]].

## Outcome (executed 2026-06-21)

**VERDICT = INCONCLUSIVE — forced-under-observed (differentiated-leaning).** The mechanical OUTCOME read
against the frozen instrument is **INCONCLUSIVE**, and that is the label of record. The substance underneath
is **decisively differentiated-leaning** — kept SEPARATE from the label, never relabeled. That separation IS
the anti-retrofit discipline, and an independent cold re-derivation confirmed it.

**Mechanical read** (frozen instrument `sha256 600e1c9f…2d99`, freeze re-verified at T4 against
`companion/research/.frozen` — MATCH, verdict VALID; memory excluded per Phase-95):
- **K_low = 0** (zero COMMODITIZED primitives), **K_high = 1** — B5 (boundary-validator) is CONTESTED, the
  sole value-capturing FOR being OpenAI's auto-Pydantic tool-arg validation (`params_pydantic_model(**json_data)`
  + `ValidationError → ModelBehaviorError` before the function fires). One FOR + primaries-against → CONTESTED;
  falls short of the COMMODITIZED bar (needs ≥2 labs or Anthropic+1; Anthropic ships only attach-surfaces).
- **CORE is UNCOMMODITIZED:** B1 (blocking gates) and B4 (assumption gate) both NOT-COMMODITIZED; B2 (config+drift)
  and B3 (decision/lifecycle trail) also NOT-COMMODITIZED.
- **Tallies:** THIN = 12/14 sources (frontier converging thin ✓); 3 distinct labs affirmatively leave the
  discipline/lifecycle layer to tooling (Anthropic context-engineering, OpenAI security-delegated-outside, MCP
  "cannot enforce at the protocol level"); DIVERGENT-direction = 0; OSS corroborates DIFFERENTIATED (secondary).
- **Why INCONCLUSIVE not DIFFERENTIATED:** every DIFFERENTIATED clause holds EXCEPT "no contests" — the frozen
  rule's zero-tolerance "any contest bars DIFFERENTIATED" clause fires on the single non-core B5 contest. The
  §1 burden-of-proof routes a non-decisive read AGAINST the bet (to a tracked rung-B watch), never to a free
  DIFFERENTIATED. **Both resolutions of the B5 contest land DIFFERENTIATED** (resolver narrative — NOT a
  pre-committed future verdict; a fresh sweep would re-derive it).

**The forced INCONCLUSIVE is the realized rigor/legibility cost flagged at freeze (instrument §9).** The
rigorous rule the maintainer chose over the simpler one I recommended pre-freeze bit exactly here: the simplified
rule would have returned a clean DIFFERENTIATED. The frozen rule producing a more conservative label than the
evidence's center of mass IS the anti-retrofit discipline working — recorded as a data point, not edited.

**NET decision read:** the external frontier supplies **NO case to shrink the kit's bet.** Every GA "blocking"
surface (Claude Code hooks, OpenAI guardrails, MS middleware, Google callbacks) is the frozen edge case —
platform ships the hook/intercept surface, the consumer authors the opinionated block CONTENT (value-capture
test held). Combined with the Phase-95 internal memory KEEP, **both arms of the Ph92 re-measure now agree**:
the kit's distinctive layer (deterministic enforcing gates + the assumption-forcing gate + the lifecycle trail)
is uncommoditized and affirmatively left to tooling by the labs themselves.

**Freeze mechanism (new reusable method):** because git first-add-commit ancestry CANNOT guard an UNTRACKED
(gitignored) file, the freeze used a **SHA256 ATTESTATION** — `companion/research/.frozen` snapshots the
pre-registration hash; T4 re-verifies and is VOID on mismatch. This is the gitignored-apparatus analogue of the
Phase-87 byte-freeze ancestry guard.

**Dropped check (honesty note):** the adoption / peer-deletion proxy was dropped from the one-shot (deferred to
rung B). Consequence: value-capture became the SOLE judgment-bearing check between a GA label and a COMMODITIZED
tally — a soft spot; re-add adoption archaeology if rung B is built.

**Independent verification:** a cold re-derivation CONFIRMED the read — freeze MATCH, Step-4 path identical,
retrofit-check CLEAN, arithmetic clean, no critical findings (one minor caution: the "both resolutions land
DIFFERENTIATED" line is resolver-narrative not a pre-committed future verdict — already caveated in verdict.md).

**Resolver / rung-B charter:** watch (1) the B5 contest (a 2nd lab shipping a GA value-capturing boundary-validator,
or OpenAI's regressing) and (2) the real COMMODITIZED tripwire — ANY lab shipping a value-capturing, default-on
B1 (opinionated blocking content) or B4 (enforced assumption/plan adjudication). **Cadence (A3 resolved):**
QUARTERLY core-primitive watch — the value-capturing core layer is a slow (quarters-scale) signal; a standing
high-frequency pipeline would burn cost on the fast attach-surface layer that does not move the verdict.

**Honesty ceiling:** reads declared/productized direction only; internal lab harnesses are unseen; pairs with —
never replaces — the kit's internal evidence (amplifier-null + Phase-95 KEEP).
