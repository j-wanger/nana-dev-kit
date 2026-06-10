---
title: "Prune-on-Value Subtraction"
aliases: [phase-83-decision, prune-on-value]
category: decisions
tags: [subtraction, harness-right-sizing, hooks, memory, utilization-evidence, deregistration]
parents: [phase-83-prune-on-value-subtraction]
created: 2026-06-09
updated: 2026-06-09
source: plan
confidence: high
---

## Context

Phase 79 parked prune-on-value ("which of the 17 hooks / ~100 working-knowledge entries earn their keep?") with re-trigger "a prune-on-value subtraction phase." Phase 82's QA sweep armed it: the usage-area audit produced a 6-candidate subtraction-review list with utilization evidence (eval/qa-sweep/verification-matrix.md rows 93-96 + repro-runs.log + the filed Blockers): enforce-memory.sh zero lifetime firings; memory reinforcement 0/55 entries; memory MCP never called by edge-screener; audit-log model field always "unknown"; 3 orphan companions pinned in test_companions.sh; harness-audit.sh unwired. Jake chose this over hook-hygiene-round-2 and edge-screener work (2026-06-09). The kit's 4-instance registered-but-dormant history cuts both ways: it motivates shrinking the surface AND warns that a zero can measure broken plumbing, not absent demand.

## Decision

Evidence-first, verdict-gated, serialized subtraction (spec `specs/phase-83-prune-on-value-subtraction.md`, nana:approved):

- Per-candidate verdict table (keep / cut / harden / disable-at-boundary) BEFORE touching anything; every verdict cites its matrix row/filing AND carries an arming-procedure column — the concrete test behind each zero-classification, defined per candidate at T1 (hook-shaped arming for enforce-memory/harness-audit/reinforcement; Read-path resolution for the orphan companions; for the field/decision candidates the procedure names what evidence stands in for "arming"). Candidate 3's DEREG artifact (what the absence assertion targets, given the scaffold ships via py-init/ts-init template copy, not a settings entry) is decided at T1, not improvised at execution.
- Mandatory couldnt-fire vs didnt-fire classification per zero: arm the precondition in a mktemp -d sandbox, pipe a synthetic trigger, observe firing. Won't-fire-when-armed = DEFECT finding, not demand evidence — no cut.
- Installed surface mechanically DISCOVERED, not assumed (A3 reject → A6 accept): kit-marker scan of this machine (~/.claude/.nana-dev-kit-path, home-dir projects with kit-named hooks, .nana/ dirs, shell-profile exports) precedes the liveness grep.
- Removal-set-first liveness grep over ALL discovered roots; alive = LIVE references outside the removal set; HISTORICAL dev-wiki records don't count and are never rewritten (Phase-72 method).
- Mid-phase checkpoint: full verdict table to the maintainer BEFORE any cut (unconditional).
- Cuts execute serially, one commit per candidate (`Phase 83 cut: <name>`), per-cut MANIFEST/settings regeneration with regenerated-diff ⊆ removal set; installed-surface deregistration limited to each cut's OWN ghosts (Jake 2026-06-09 — the other 10 ghost global registrations stay deferred under the Phase-82 drift filing).
- memory_server verdict menu: keep / disable-at-boundary / cut-with-regenerated-patch (vendoring contract: near-zero upstream divergence).
- Bound by prior decisions: [[audit-log-disposition]] (audit-log stays; candidate 4 is field-level only), [[memory-architecture-classification]] (candidate 3 is scaffold-shipping only; kit's own 55-entry voluntary use is real), [[single-source-scope-tagged-hook-registration]].
- Zero cuts is a valid outcome.

Direction gate (assumption-approval; ledger block appended, all_accept: false — approved 2026-06-09): A1 accept (installed dereg mechanically safe with sandbox rehearsal); A2 accept (Phase-82 zeros measure demand post-restoration); A3 REJECT → revised A6 accept (installed surface DISCOVERED, not assumed); A4 don't-know → defended A7 accept (live install lacks fastembed; storage.py reinforces only at cosine >0.90 — unreachable without embeddings, word-overlap fallback only warns → candidate 2 largely pre-classified couldnt-fire → keep/harden semantics); A5 don't-know DOWN-SCOPED (candidate 3 stays scaffold-shipping-only; the kit-side memory-layer value question deferred to Blockers, revisit-status: open, must-revisit).

Rejected alternatives: wholesale memory-layer disable (contradicts memory-architecture-classification; the layer has live kit-side consumers — memory-consolidate skill, session-start health probe, bridge stores); folding in all 11 ghost deregistrations (widens blast radius beyond evidenced candidates; Jake chose own-ghosts-only); repo-only cuts with deferred installed deregistration (leaves silently-failing ghost registrations — the 4-times-bitten class).

## Consequences

The always-running surface shrinks or is explicitly re-affirmed with every verdict traceable to firing evidence. The make eval denominator may drop IF a cut removes corpus scenarios (e.g. a candidate-1 cut would remove its 3 hook scenarios) — the spec authorizes an explained denominator change, not any specific cut; verdicts stay evidence-forced. Harden verdicts produce filed follow-ups, not in-phase plumbing work. Residue (out-of-scope tiers, frozen-apparatus-blocked items) is filed with re-triggers. Working-knowledge entries naming cut components get superseded entries, never rewrites.
