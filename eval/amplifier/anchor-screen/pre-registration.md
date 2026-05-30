# Anchor-Headroom Screen — Pre-Registration (Phase 70)

> **Committed BEFORE any harness-OFF run.** This file fixes the candidate set, each frozen OFF prompt
> (shasum-pinned), each anchor's deterministic check, and the classification thresholds — so no
> verdict can be retrofitted to a desired conclusion. The pre-registration commit MUST be a git
> ancestor of the first `verdicts/` commit (`git merge-base --is-ancestor`). `check.sh --verify-pins`
> recomputes every prompt shasum below and fails on drift.
>
> **No-harness-value claim.** This screen characterises ANCHORS, not the harness. A `HAS-HEADROOM`
> verdict means *lift is POSSIBLE* (the base model omits the correct behavior unprompted, so a harness
> rule could supply it) — it does **not** mean lift exists. Necessary, not sufficient.

base-model: claude-opus-4-8 (bare subagent via the Agent tool — no rules/hooks/skills/memory/tools; model pinned at dispatch). The strongest default model is the fairest baseline: if even it has headroom, the harness has something real to add; if it does not, that is the honest finding.

## Method (frozen)

- **n = 5 runs per anchor, exactly.** Each run = one bare clean-room subagent given ONLY the frozen OFF prompt.
- **Deterministic classification (`check.sh`), never an LLM judge.** Each anchor has a `.check` file of
  named clauses (`require`/`forbid`, ERE). A run PASSES iff every `require` matches and no `forbid` matches.
- **Consensus-by-clause, not OR-of-failures:**
  - `HAS-HEADROOM` iff the check FAILS in ≥4/5 runs AND the SAME clause-id is the failing one in ≥4/5.
  - `DEGENERATE` iff the check PASSES in ≥4/5 runs.
  - otherwise `UNSTABLE` → quarantine (not classified). (A 5/5 fail split across two clauses is UNSTABLE, not headroom — the guard against a brittle-check false positive.)
- **Pure-reasoning anchors only.** Every anchor's correct behavior is a stated judgment needing no tool, so the bare subagent is a valid harness-OFF proxy (not a tool-gap confound). A candidate found to need a tool is recorded `DISQUALIFIED`.
- **Leak-checked prompts.** Every prompt below passes `leak-check.sh` against the frozen `leak-vocab.txt` (no answer-method cue smuggled in).

## Controls (run FIRST — instrument validation; any misbehavior ⇒ STOP, instrument-broken)

### control-negative — look-ahead bias (the Phase-69 degenerate anchor)
class: control-negative
expected: DEGENERATE (a strong base model avoids look-ahead unprompted — there is no headroom here)
prompt: prompts/control-negative.txt
prompt-shasum: 3d45ce0cad717781f0e687d22a6032e849dcce7af0d240f8a652271e998cf570
check: checks/control-negative.check

### control-positive — unknowable invented fact (the saturated-headroom endpoint)
class: control-positive
expected: HAS-HEADROOM (the "Zephyr Act §12(b)" threshold is fictional; the base model cannot know the $3,200 answer, so it omits it on every run — a harness that injected the policy would supply it)
prompt: prompts/control-positive.txt
prompt-shasum: 7d2dc823251a3f87875f193e32b96d0f442824b6606b04653ac274c2f83647d4
check: checks/control-positive.check

### control-middle — known-partial AML judgment (the contested band)
class: control-middle
expected: NOT HAS-HEADROOM, reproducibly. Run TWO independent n=5 batches; the control PASSES iff
NEITHER batch reads HAS-HEADROOM (`check.sh --stability` ⇒ `STABLE`). Rationale: at n=5 a true
p≈0.5 anchor is maximally UNSTABLE (~62% per batch), so requiring "reproduces UNSTABLE" would
self-halt a *working* instrument ~55% of the time. The property that actually matters is that the
screen does not FALSE-POSITIVE (emit HAS-HEADROOM) on a non-headroom partial anchor — that is the
costliest error. UNSTABLE/DEGENERATE jitter between batches is acceptable (the safe direction).
prompt: prompts/control-middle.txt
prompt-shasum: 0d3338a88303bbdc1ebfa67dbdab33fccc61b374b754a9d387a3db6380579d03
check: checks/control-middle.check

## Candidates (screened only if the controls pass)

Seeded from the headroom priors — weak-parametric AML decisions (niche/procedural application, not
textbook recall) where a frontier base model might omit the correct behavior unprompted. Honest
caveat: structuring, UBO look-through, and sanctions fuzzy-matching are well-documented; a strong
model may handle them and screen DEGENERATE. That is an informative result, not a failure.

### cand-structuring — sub-threshold structuring detection
class: candidate (natural)
correct-behavior: flags structuring / SAR-worthy via aggregation + evasion intent despite no single deposit reaching the $10,000 CTR threshold
prompt: prompts/cand-structuring.txt
prompt-shasum: cd1a42e17a0bf03e0563cf943754cdd8a9edabb8fa39b0277b768a8e831a2090
check: checks/cand-structuring.check

### cand-ubo — beneficial-ownership look-through + indirect aggregation
class: candidate (natural)
correct-behavior: aggregates Anna Kovac's two indirect paths to ~60% effective ownership (the subtle multiply-and-sum), not stopping at a single 30% path or at corporate owners
prompt: prompts/cand-ubo.txt
prompt-shasum: 61390635ece214c080b47385113df4fdfdb10b1b167ac9cc93ba27519ce4e7e0
check: checks/cand-ubo.check

### cand-sanctions — non-exact sanctions name match
class: candidate (natural)
correct-behavior: treats the inexact name as a potential hit requiring escalation/hold, rather than releasing on "names don't exactly match"
prompt: prompts/cand-sanctions.txt
prompt-shasum: 23c8b7e1cd4932bc1d1f2ca8e09fcfe916fb14e1822dcd9dae322b4796a0290a
check: checks/cand-sanctions.check

### cand-engineered — engineered-favorable: niche/recent EU AMLR cash cap
class: candidate (engineered-favorable)
role: the verdict-ladder backstop. Realistic (the EU AMLR €10,000 cash cap, adopted 2024, applying ~2027) but engineered as headroom-favorable as is realistic — a specific recent/niche figure a frontier model may not hold cold. If even THIS screens DEGENERATE, the null is strong (⇒ TERMINATE); if it is HAS-HEADROOM but no NATURAL candidate is, the program is PARKED (headroom only under construction).
correct-behavior: states the €10,000 EU-wide cash limit and flags the €12,000 purchase as over-limit
prompt: prompts/cand-engineered.txt
prompt-shasum: 3c0c8ee01e1b373534cc125ba5a85037d1298d8185d872ea217291c3d7604c4e
check: checks/cand-engineered.check

## Verdict ladder (graded; pre-committed; threshold un-loosenable post-hoc)

- **CONTINUE** — ≥1 NATURAL candidate (structuring / ubo / sanctions) screens HAS-HEADROOM. Phase 71 inherits that validated anchor (predicate repair + the live off/on run).
- **PARKED** — no natural candidate is HAS-HEADROOM, but `cand-engineered` is. Headroom exists only under construction, not in real work ⇒ park pending new priors / the deferred long-horizon class (a multi-turn substrate).
- **TERMINATE** — even `cand-engineered` screens DEGENERATE. Single-decision anchor measurement is closed as not-measurable; the program reverts to assessing the harness on process merits.

A null does NOT auto-terminate: "termination" language requires `cand-engineered` to also be DEGENERATE. No retry-until-green; no post-hoc threshold change.
