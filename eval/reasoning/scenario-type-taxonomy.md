# Scenario-Type Taxonomy

Classifies reasoning eval scenarios into 3 types based on **scenario properties** (what makes the decision hard), not outcomes (how the model scored). Each type identifies the primary decision axis — the dimension that most determines whether the answer is expert-quality.

## Types

### risk-dominant

The correct answer is primarily determined by risk management. The scenario presents an appealing but risky option against a safer incremental alternative.

**Property criteria (2 of 3 required):**
1. The affected component has high blast radius — failure impacts many users, is hard to reverse, or crosses a security/compliance boundary
2. An external deadline or compliance requirement creates urgency that tempts shortcutting
3. The options differ primarily in deployment risk profile (single high-stakes cutover vs incremental validated steps)

**Distinguishing signal:** The expert reasoning centers on "what goes wrong if this fails" rather than "what's the optimal path forward." The anti-pattern involves conflating urgent risk remediation with aspirational improvement.

**Training example:** 015 (rewrite-vs-refactor-auth) — security audit deadline, auth system blast radius, rewrite-vs-incremental deployment risk.

### capacity-constraint

The correct answer depends on understanding resource allocation dynamics — compounding costs, velocity effects, or investment payback periods.

**Property criteria (2 of 3 required):**
1. Competing priorities vie for a fixed resource budget (time, headcount, sprint capacity)
2. One option has compounding cost characteristics — the problem gets worse over time if not addressed
3. The tension is between short-term visible output and long-term capacity or velocity

**Distinguishing signal:** The expert reasoning involves quantitative framing — payback periods, compounding multipliers, or total cost over a time horizon. The anti-pattern involves incremental approaches that fail due to prioritization dynamics.

**Training example:** 018 (feature-flag-debt) — 150 flags creating compounding velocity drag, 2-week investment with within-quarter payback.

### domain-nuance

The correct answer requires understanding domain-specific conventions, second-order systemic effects, or meta-decision properties that surface-level analysis misses.

**Property criteria (2 of 3 required):**
1. Multiple options are genuinely valid from a surface analysis — no option is obviously wrong
2. The expert answer relies on a domain convention, ecosystem norm, or systemic insight not stated in the scenario
3. The correct choice has a meta-property — it improves the ability to make future decisions, or operates on a different level than the other options

**Distinguishing signal:** The expert reasoning introduces a framing or principle not present in the scenario description. The anti-pattern involves optimizing for the most visible or easily measured metric while missing systemic effects.

**Training example:** 020 (tech-debt-triage) — three valid proposals, test reliability chosen for meta-property (creates capacity for the other two).

## Classification Protocol

1. Read the scenario context and question
2. Identify the primary decision axis — what makes this decision hard?
3. Check property criteria for each type (2 of 3 required)
4. If a scenario matches criteria for multiple types, assign the type whose training example is most structurally similar
5. If no type clearly fits (0-1 criteria for all types), assign the type whose distinguishing signal best matches the expert reasoning pattern

## Validation Checkpoints

- At least 2 scenarios per type (if any type has 0-1, taxonomy is too fine-grained)
- Training scenarios (015, 018, 020) must classify correctly under these criteria
- Held-out scenarios (012, 014) classified without reference to their eval scores
