# Anchor-Headroom Screen — Result (Phase 70)

> **No-harness-value claim.** This screen characterises ANCHORS, not the harness. `HAS-HEADROOM` means
> *lift is possible* (the base model omits the correct behavior unprompted, so a harness rule *could*
> supply it) — never that lift exists. `DEGENERATE` means the base model already produces the correct
> behavior unprompted, so there is no lift to measure on that anchor. This record makes **no claim about
> whether the Nana harness helps**.

base-model: claude-opus-4-8 (bare subagent via the Agent tool — no rules/hooks/skills/memory/tools)
method: n=5 per anchor, deterministic named-clause checker (`check.sh`), consensus-by-clause (HAS-HEADROOM iff FAIL ≥4/5 same clause-id; DEGENERATE iff PASS ≥4/5; else UNSTABLE). Pre-registered + committed before runs (`pre-registration.md`, commit be96783). Prompts shasum-pinned + leak-checked.

## Controls-first checkpoint — PASS (instrument validated)

| control | expected | result |
|---|---|---|
| control-negative (look-ahead bias) | DEGENERATE | **DEGENERATE** (5/5 PASS) ✓ |
| control-positive (fictional Zephyr Act fact) | HAS-HEADROOM | **HAS-HEADROOM** (5/5 FAIL, consensus) ✓ |
| control-middle (partial $14k judgment) | not HAS-HEADROOM, reproducible | **stability: STABLE** (DEGENERATE/DEGENERATE) ✓ |

The negative branch (a degenerate anchor reads DEGENERATE), the positive branch (an unknowable-fact anchor reads HAS-HEADROOM), and the no-false-positive property in the contested band all hold. The instrument is not vacuously stuck on either verdict.

## Candidate verdicts

| anchor | class | verdict |
|---|---|---|
| cand-structuring (sub-threshold structuring) | natural | **DEGENERATE** |
| cand-ubo (look-through + indirect aggregation) | natural | **DEGENERATE** |
| cand-sanctions (non-exact name match) | natural | **DEGENERATE** |
| cand-engineered (EU AMLR €10k cash cap) | engineered-favorable | **DEGENERATE** |

Candidates screened: 4 (3 natural + 1 engineered-favorable). Natural candidates HAS-HEADROOM: 0. Engineered-favorable HAS-HEADROOM: no.

## The finding

Across four substantive single-decision AML anchors — spanning detection-reasoning (structuring), multi-layer computation (UBO aggregation), procedural judgment (sanctions transliteration), and recent-regulation knowledge (EU cash cap) — the bare base model produces the correct behavior unprompted in 5/5 runs every time. The **only** anchor that surfaced headroom was the positive control, whose "correct answer" is a fact that *does not exist* (the fictional Zephyr Act §12(b)).

The discriminating variable is therefore **not reasoning quality and not domain difficulty** — the model reasons through the subtle multiply-and-sum, the structuring aggregation, and the transliteration logic correctly on its own. The only thing it lacks is a fact it cannot know. Single-decision harness headroom, for a frontier base model on this kind of task, lives exclusively in *unknown facts*, not in *reasoning the model can do unprompted*. This extends the Phase-59 commodity-knowledge lesson: support/injection does not pay where the model's parametric knowledge and reasoning are already strong — and here they are strong even on niche-looking AML calls.

PROGRAM-VERDICT: TERMINATE

Per the pre-registered ladder: even the engineered-favorable anchor screened DEGENERATE ⇒ strong termination of the **single-decision anchor** measurement program. Stop trying to measure harness lift via single-decision reasoning/knowledge anchors — that approach is exhausted for a strong base model.

## What TERMINATE does and does NOT close (scope + honesty rails)

TERMINATE is scoped to *single-decision anchor measurement of harness lift*. It does **not** close, and this screen did not and could not test:

1. **Retrieval on genuinely-unknowable facts.** The positive control proves headroom is reachable for facts outside the model's knowledge (proprietary / post-cutoff / fictional). That is a RETRIEVAL problem, not a reasoning-harness one — and it is exactly the long-standing Phase-59 untested sweet spot (weak-parametric / proprietary topics, never measured on real data). The engineered-favorable used a real, as-it-turned-out model-known regulation, so it did not reach into that band; a maximally-adversarial engineered anchor would have to use a genuinely proprietary or post-cutoff fact, which needs real proprietary data + an absorb pipeline this screen does not have.
2. **Long-horizon / multi-turn process-retention headroom.** Explicitly dropped from this screen (a one-shot subagent cannot surface multi-turn degradation). Deferred to a future phase on a genuine multi-turn substrate. A null here says nothing about it.
3. **The harness's process/discipline value** (lifecycle gates, not losing context, enforcement) — never a single-decision-anchor property; out of scope by construction.

## Limitations (recorded, not buried)

- **n=5; deterministic regex checks.** The checks are named-clause regexes, validated end-to-end by the three controls (both verdict directions + no-false-positive). They are not immune to brittleness on unseen phrasings, but the controls bound that risk and the candidate signal was unanimous (5/5) in every case, far from any threshold edge.
- **The middle control landed DEGENERATE/DEGENERATE, not UNSTABLE.** It confirmed the no-false-positive property (its load-bearing job) but did not fully stress the genuinely contested ~50/50 band — opus handled the $14k judgment more consistently than the design assumed. The screen's reliability at a true boundary is therefore less stress-tested than ideal.
- **The engineered-favorable was not maximally adversarial** (it used a knowable regulation). The TERMINATE follows the pre-registered rule literally; the honest texture is that headroom *is* reachable for truly-unknowable facts (per the positive control), so the surviving avenue is retrieval-on-proprietary-data, named above as item (1).

See [[amplifier-anchor-headroom-screen]] for the decision and the Phase-71/disposition handoff.
