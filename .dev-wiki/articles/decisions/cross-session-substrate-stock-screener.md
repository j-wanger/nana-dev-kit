---
title: "Decision: Cross-session-persistence substrate = an external stock-screener project"
slug: cross-session-substrate-stock-screener
type: decision
status: accepted
confidence: high
source: plan
phase: 73
created: 2026-05-30
updated: 2026-05-30
tags: [amplifier-vision, cross-session-persistence, substrate, external-project, dogfood, measurement-deferred]
---

# Decision: Cross-session substrate = external stock-screener project

## Context

The Phase 58–71 amplifier-measurement campaign returned 14 consecutive CUT/TERMINATE
verdicts; Phase 72 cashed the first one ([[cash-compaction-recovery-subtraction]]). Both
closed lines — single-decision reasoning ([[amplifier-anchor-headroom-screen]]) and
single-compaction retention ([[cross-boundary-retention-headroom-screen]]) — share one
structural confound: they were measured on *this* repo, whose own git log / dev-wiki is
**decision-comprehensive**, so the native model context already carried what the harness
was hypothesized to recover.

The one surviving harness-value regime the campaign never reached is **cross-SESSION
persistence**: the native compaction summary dies when the session ends, but the harness
files (`active-phase.md`, `_CURRENT_STATE.md`, `.dev-wiki/`) persist. To measure it
honestly we need a *real, external, multi-session* workload — not nana-dev-kit measuring
itself (pre-flagged confounded), and not a synthetic rig (the campaign repeatedly showed
synthetic substrates produce confounded nulls).

At the `/dev-plan` direction fork (AskUserQuestion, 2026-05-30) Jake chose **Build a real
substrate**, then **cross-session persistence**, with the concrete workload: *build an
actually-working stock screener with real edge over the S&P 500, extensively tested.*

## Decision

**The cross-session-persistence substrate is a new, standalone stock-screener project**
(`/Users/jwang/edge-screener`), scaffolded with the **real nana harness** (`py-init` +
`dev-init`) so there is a genuine harness to measure, and built across many real sessions.
It is an external **consuming project** — its own repo and `.dev-wiki/` — which removes the
self-measurement confound.

Three framings were locked at the direction gate:

1. **Honest goal = an un-foolable backtest apparatus, not guaranteed alpha.** Beating the
   index net of costs out-of-sample is hard; most strategies die on false positives
   (survivorship bias, lookahead, overfitting, ignored costs). Success = a validator that
   can't be fooled into believing a dead screen is alive + an honest characterization of
   what edge is/isn't there — the campaign's 14-TERMINATE falsification DNA, pointed at
   markets.
2. **The cross-session measurement is DEFERRED.** You cannot measure recovery on session 1
   — there is nothing for a fresh session to recover until real multi-session decision
   history has accrued. Early phases are substrate *construction*; the OFF/ON
   fresh-session recovery measurement runs later, once history exists.
3. **Data = free public (yfinance/Stooq) with explicit, loud bias guards.** Survivorship
   bias interacts with strategy (price/momentum less corrupted than fundamentals-value, since
   delisted names are simply absent); early edge numbers are treated as ceilings.

## Why (alternatives considered)

- **Speculative substrate** (build one just to measure) — rejected: violates the
  burden-of-proof-on-the-feature discipline the campaign established; risks another
  confounded null.
- **Cross-session via nana-dev-kit itself** — rejected: pre-flagged confounded by its own
  decision-comprehensive git log.
- **Proprietary/post-cutoff retrieval (dir-3)** — viable and domain-adjacent, but needs a
  genuinely weak-parametric corpus; not chosen this round.
- **Engineering roadmap (gap 4.1 / vector-search)** — gap 4.1 stays DEFERRED YAGNI (a
  Python screener does not trip the non-Python re-trigger).

A real screener is a genuine external multi-session project — the unconfounded substrate
the regime needs — and dogfoods the kit on its first serious consuming project.

## Consequence

- **nana-dev-kit Phase 73 is thin and a handoff:** the deliverable is *the external
  substrate established with the real harness + the deferred-measurement design recorded*.
  No quant code lives in nana-dev-kit; the screener build proceeds in the new project's own
  `.dev-wiki/` (its Phase 1 = "Validated backtest ruler, before any edge search" — mirrors
  Phase 68's build-the-ruler-before-measuring).
- nana-dev-kit returns to **active phase: NONE** after bootstrap, awaiting the deferred
  cross-session measurement (trigger: the screener project has accrued real multi-session
  history).
- A standing open question is recorded: the exact OFF/ON cross-session recovery protocol is
  designed *when* the substrate has history, not pre-registered now (pre-registering before
  the substrate exists would be premature speculation).

## Source

Phase 73 plan; direction gate AskUserQuestion 2026-05-30 (Build a real substrate →
cross-session persistence → stock screener; defaults approved). Evidence chain:
[[amplifier-anchor-headroom-screen]], [[cross-boundary-retention-headroom-screen]],
[[cash-compaction-recovery-subtraction]].
