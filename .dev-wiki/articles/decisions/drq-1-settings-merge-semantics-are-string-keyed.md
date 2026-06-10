---
title: "DRQ-1: settings merge semantics are string-keyed dedupe"
aliases: [drq-1, string-keyed-hook-dedupe, settings-merge-dedupe]
category: decisions
tags: [hooks, settings, platform-semantics, edge-screener, install]
parents: [phase-85-install-gap-dogfood]
created: 2026-06-10
updated: 2026-06-10
source: debrief
confidence: high
---

# DRQ-1: settings merge semantics are string-keyed dedupe

## Context

Phase 85's edge-screener migration rode on assumption A2: duplicate hook registrations across `settings.json` + `settings.local.json` double-fire. The spec made empirical verification MANDATORY before checkpoint 2 (STOP-and-re-present if contradicted) because no platform documentation records the merge semantics, and the migration plan (dedupe-by-basename into settings.local.json) was justified by the double-fire model.

## Decision

Verified empirically (2 headless-session probes, each with a positive control; eval/install-gap/drq1-verification.md): Claude Code dedupes duplicate hook registrations across settings.json + settings.local.json ONLY when the command strings are byte-identical. Distinct strings invoking the same script (e.g. `bash ~/.claude/hooks/X.sh` vs an absolute path) BOTH fire. Verdict recorded as `dedupe` (string-keyed) — A2's double-fire working model was wrong in the identical-string case but right in the distinct-string case, which is the case that exists in the wild (Phase-84 gate scan: live registration forms are MIXED).

Consequence adopted: registration migrations must normalize by script basename, never rely on platform dedupe. The edge-screener migration was reframed from a correctness fix (stopping an active double-fire) to hygiene that closes a latent class — any future re-registration in a different string form would silently double-fire.

## Consequences

- A2 ledger row filled `bit` (instructively — the mandatory pre-checkpoint-2 verification caught it; the STOP rule was not needed because the migration plan survives under both verdicts).
- Basename identity is the durable union-uniqueness invariant (asserted by eval/install-gap/assert-edge-screener-registration.sh: 17/17 basenames exactly once; firing probe: each Stop hook fired exactly once).
- Reusable method: headless `claude -p` sessions in a sandbox project are a cheap empirical probe for undocumented platform semantics — two probes settled what no documentation records (wiki-capture candidate).
