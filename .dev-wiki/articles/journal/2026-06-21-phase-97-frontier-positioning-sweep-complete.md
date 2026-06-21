---
title: "Phase 97: Frontier Positioning Sweep — INCONCLUSIVE (forced-under-observed, differentiated-leaning)"
aliases: [phase-97-debrief, frontier-sweep-outcome]
category: journal
tags: [strategy, positioning, frontier, companion, research, amplifier-program, pre-registration, verdict]
parents: [phase-97-frontier-positioning-sweep]
created: 2026-06-21
updated: 2026-06-21
source: debrief
duration: long
---

# Phase 97: Frontier Positioning Sweep — Mechanical Verdict INCONCLUSIVE (differentiated-leaning)

## What Happened

The EXTERNAL arm of the Ph92 re-measure-then-shrink. One extended session: plan (already gated) → 3 research
workflows → mechanical verdict. Ran a pre-registered, one-shot sweep of where the agent-harness / agent-tooling
frontier is converging, read MECHANICALLY against a decision rule FROZEN before any research, to answer whether
the kit's bet (deterministic spine + lifecycle ceremony) is DIFFERENTIATED / COMMODITIZED / DIVERGENT vs the
frontier. Lab-published artifacts PRIMARY (declared frontier direction), OSS SECONDARY corroboration. Lives
entirely in gitignored `companion/research/` — rung A of the de-risking ladder; B (pipeline) / C (opencode
workers under nana-written contracts) / D (generalization) stay future phases.

- **T1** gitignore guard verified BEFORE any research write (`companion/` ignored, `git ls-files companion/`
  empty) — nothing leaks into the shippable kit.
- **T2** pre-registered the frozen instrument (`pre-registration.md`, the phase's gitignored spec). Because
  git first-add-commit ancestry CANNOT guard an untracked file, freeze used a **SHA256 ATTESTATION** —
  `.frozen` snapshots the hash; T4 re-verifies, VOID on mismatch. Maintainer sign-off: "freeze it and run the
  sweep" — chose the **rigorous (adversarially-hardened)** rule over the **simplified** one I recommended; I
  flagged the over-engineering risk, he weighted airtightness-against-gaming.
- **T3** ran the sweep — 14 live lab artifacts + OSS, adversarially verified. An agent **hallucinated a verbatim
  citation** (P12/B1); the re-fetch audit caught it before it reached the verdict.
- **T4** mechanical verdict + freeze re-verify (`sha256 600e1c9f…2d99` MATCH → VALID) + half-life → cadence.

**VERDICT = INCONCLUSIVE — forced-under-observed (differentiated-leaning).** The mechanical OUTCOME is
INCONCLUSIVE (the label of record). The substance is decisively differentiated-leaning, kept SEPARATE from the
label — never relabeled. K_low=0 (zero COMMODITIZED primitives), K_high=1 (B5 boundary-validator CONTESTED — sole
value-capturing FOR is OpenAI's auto-Pydantic tool-arg validation; falls short of the ≥2-labs-or-Anthropic+1
bar). CORE (B1 blocking gates + B4 assumption gate) UNCOMMODITIZED; B2/B3 also NOT-COMMODITIZED. 12/14 sources
THIN; 3 distinct labs affirmatively leave the discipline layer to tooling; DIVERGENT-direction = 0; OSS
corroborates DIFFERENTIATED. INCONCLUSIVE is FORCED by the rigorous rule's zero-tolerance "any contest bars
DIFFERENTIATED" clause firing on one NON-CORE primitive — the realized rigor/legibility cost flagged at freeze;
the simplified rule would have returned a clean DIFFERENTIATED. Both resolutions of the B5 contest land
DIFFERENTIATED (resolver narrative, NOT a pre-committed future verdict).

**NET:** the external frontier gives NO case to shrink the kit's bet. Every GA "blocking" surface (Claude Code
hooks, OpenAI guardrails, MS middleware, Google callbacks) is the frozen edge case — platform ships the
hook/intercept surface, consumer writes the block CONTENT (value-capture test held). Combined with the Phase-95
internal memory KEEP, **both arms of the Ph92 re-measure now agree.**

### Review Gate
Independent cold re-derivation of the verdict CONFIRMED INCONCLUSIVE-forced: freeze MATCH, Step-4 path identical,
retrofit-check CLEAN, arithmetic clean, no critical findings. One minor caution: the "both resolutions land
DIFFERENTIATED" line is resolver-narrative, not a pre-committed future verdict — already caveated in verdict.md.

### Gate Compliance
Phase-97 gate comment is `direction=approved delivery=pending` — correct. Direction gate closed 2026-06-21
(ledger Phase-97, all_accept:false: A1 reject→positioning, A2 reject→lab-primary, A3 don't-know→half-life-to-T4).
The delivery gate flips only after the commit verifiably lands (delivery-flow Step D3); it stays `[ ]` here.

## Decisions Made
- [[frontier-positioning-sweep|Frontier Positioning Sweep]] — Outcome section appended (confidence bumped to
  high): VERDICT INCONCLUSIVE-forced-under-observed (differentiated-leaning); SHA256-attestation freeze mechanism;
  adoption proxy dropped → value-capture is the SOLE judgment-bearing check; quarterly core-primitive cadence.

## Problems Solved
- **Freezing a gitignored instrument** — git ancestry can't guard an untracked file → SHA256 attestation
  (`.frozen`), re-verified at T4, VOID on mismatch. New reusable method for gitignored apparatus.
- **Hallucinated verbatim citation** in the sweep — caught by the adversarial re-fetch audit before it reached
  the verdict. Reinforces verify-by-re-fetch + orchestrator-only-evidence ([[qa-verification-sweep]], [[HEU-012]])
  for ANY deep-research workflow.

## Open Questions
- **B4-in-core reachability** (pre-registration §9.6) — frozen watch-item; maintainer abstained at freeze; the
  most-likely-miscalibrated knob. Is an enforced "approve stated assumptions before acting" pause something a
  lab plausibly ships GA?
- **Rung B/C/D** — whether/when to build the quarterly frontier watch (B), local opencode 24/7 workers under
  nana-written contracts referencing the signal-watch family (C), generalization e.g. trading (D). Future-phase
  decisions, planned only if justified. Rung-B cadence is resolved (quarterly, core-primitive-focused).
- **companion/ VC-durability** (in Blockers) — gitignored, so the kit repo holds no history of the frozen
  instrument/verdict; decide local VC if rung B lands.

## Artifacts Changed
- `companion/research/pre-registration.md` (the FROZEN decision instrument — gitignored, serves the spec function)
- `companion/research/.frozen` (SHA256 freeze attestation seal)
- `companion/research/sweep-findings.md` + `convergence-map.md` (cited evidence + rubric classification)
- `companion/research/verdict.md` (mechanical verdict + half-life → cadence)
- `.gitignore` (gained the `companion/` entry — T1 guard)
- `.dev-wiki/articles/decisions/frontier-positioning-sweep.md` (Outcome section appended; confidence → high)
- `.dev-wiki/articles/phases/phase-97-frontier-positioning-sweep.md` (status stays active — implementation
  complete, delivery pending)
- `.dev-wiki/assumption-ledger.md` (Phase-97 A1/A2/A3 revisit-status open → held)

## Related
- [[phase-97-frontier-positioning-sweep|Phase 97: Frontier Positioning Sweep]] — parent phase
- [[memory-layer-disposition]] — the INTERNAL arm (KEEP); both arms now agree
- [[strategic-inflection-review]] — the Ph92 re-measure-then-shrink frame

## Soft Observations / Phase N+1 Candidates
- The rigor/legibility cost of an over-hardened FROZEN decision rule is now empirically demonstrated: adversarial
  hardening over-fit the rule into BOTH illegibility AND over-conservatism (forced INCONCLUSIVE on a single
  non-core contest where a simpler rule returns DIFFERENTIATED). | CROSS-PROJECT reusable → /wiki-capture
  candidate; lesson for a rung-B redesign | evidence: `companion/research/verdict.md` §rigor/legibility, the
  freeze-time complexity AskUserQuestion.
- An agent HALLUCINATED a verbatim citation (P12/B1) in a research workflow; the adversarial re-fetch audit caught
  it before the verdict. | CROSS-PROJECT reusable → /wiki-capture candidate; reinforces verify-by-re-fetch + a
  dedicated citation-reality auditor for any deep-research/sweep | evidence: sweep audit trail.
- value-capture is now the SOLE judgment-bearing check (adoption proxy dropped → rung B) — a soft spot; consider
  re-adding adoption archaeology if rung B is built.
- Rung B/C/D roadmap exists (quarterly watch / opencode workers under nana-contracts referencing signal-watch /
  generalization); plan only if justified. Rung-B cadence resolved (quarterly, core-primitive).
- B4-in-core calibration remains open (§9.6).
