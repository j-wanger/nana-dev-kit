---
title: "Consumer Memory-Layer Re-measure (Phase 94)"
aliases: [consumer-memory-remeasure, phase-94-remeasure, memory-demand-remeasure]
category: decisions
tags: [memory, demand-evidence, dogfood, amplifier-program, subtraction, verify-by-firing]
parents: [phase-94-consumer-memory-remeasure]
created: 2026-06-20
updated: 2026-06-20
source: plan
confidence: high
---

## Context

The Phase-92 [[strategic-inflection-review]] gated "re-measure-once-then-shrink": the
Phase-89 consumer memory demand-zero was **COULDN'T-FIRE** — the memory MCP was broken in
consumer cwds until the Phase-91 PYTHONPATH fix ([[memory-mcp-consumer-e2e-fix]]) — so that
zero is inadmissible as demand evidence ([[HEU-012]]: a layer that can't fire produces
couldn't-fire zeros, never demand zeros). The review's direction is explicit: **ONE clean
re-measure on a working memory layer must precede any Phase-95 memory-layer cut.** The
measurement must run in **consuming projects, never in-kit** — nana-dev-kit's always-loaded
`working-knowledge.md` leaks the answer the screen is trying to recover (Phase-80
INSTRUMENT-DEAD; 5th amplifier-null; see [[assumption-surfacer-completeness-screen]]).

## Decision

Run a lightweight **RETROSPECTIVE re-measure** — NOT a new measurement-apparatus phase (the
roadmap explicitly said not to build that) — over three live consumers on the repaired global
memory MCP, gated by a **verify-by-firing** admissibility check.

**Substrate** (maintainer-fixed `n=3` at the direction gate, expanded from `n=1`):
`signal-watch` + `aml-casework` + `aml-substrate`. The recon hint is a **PRIOR to test, not a
result**: demand is hypothesized to track a *kit-memory-machinery gradient* —

- `signal-watch` (no rules/hooks) ~ spontaneous **FLOOR** (low),
- `aml-casework` (rules, no hooks),
- `aml-substrate` (rules + hooks).

If that gradient holds it would **REVERSE** the roadmap's "consumer demand is zero" lean,
which is exactly why `n=1` on the floor consumer alone was insufficient.

**Three tasks:**

- **T1 — verify-by-firing admissibility.** Drive the MCP server the way Claude Code launches
  it from a consumer cwd; a `store -> search` round-trip must persist AND retrieve a row in
  the **CONSUMER's** `.memory/memory.db`. A broken-config control MUST classify
  **COULDN'T-FIRE** (instrument-dead self-check; clean-on-broken = dead probe). Only on a
  firing pass does retrospective tallying become admissible.
- **T2 — retrospective JSON `tool_use` tally.** Read the transcript JSON, **never grep** (a
  deferred-tool catalog contaminates a grep ~5x). 3-class taxonomy
  (spontaneous / rules-instructed / hook-prompted); cross-session **read-back**
  (ritual-vs-value) and **attempted-vs-satisfied** via `tool_result`; the post-repair window
  is pinned to a commit SHA; a positive ingest control confirms the tally sees a known call.
- **T3 — file evidence.** Reuse the Phase-89 `memory-demand.md` schema. **EVIDENCE ONLY**,
  with an explicit **NO-SUFFICIENCY caveat**: a spontaneous floor alone cannot license cutting
  a COERCED (rules/hook-instructed) layer — Phase 95 reconciles floor + coerced + read-back.

## Consequences

**Evidence ONLY.** Phase 94 takes **no keep/shrink/cut disposition** — that is Phase 95's job.

Does NOT trigger the deferred Phase-93 live consumer re-sync: memory fires globally via the
Phase-91 `env`/PYTHONPATH topology, independent of hook re-sync. **Zero kit code changes** —
`eval/` + `.dev-wiki/` + `specs/` only.

**Direction gate 2026-06-20** (ledger Phase-94; `all_accept:false`):

- **A1 accept** — fires in a consumer cwd (verify-by-firing is T1).
- **A4 accept** — post-repair window pinned to a SHA.
- **A2 don't-know** — resolved by the down-scope (retrospective, not apparatus) + the
  substrate expansion that measures coerced demand directly; sufficiency-for-cut is routed to
  Phase 95 (revisit-status open).
- **A3** — maintainer revised `n=1` to `n=3`.

Spec: `specs/phase-94-consumer-memory-remeasure.md` (nana:approved).

**Rejected:**

- The heavier "install the kit memory layer fresh into a consumer + run fresh sessions" path —
  the apparatus phase the roadmap said not to build.
- `n=1` on `signal-watch` alone — the maintainer expanded it; the expansion is what reverses
  the floor reading by measuring the machinery gradient directly.
