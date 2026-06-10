---
title: "A3 disposition: keep-current for registration-dead ~/.claude copies"
aliases: [a3-keep-current, registration-dead-copies-disposition]
category: decisions
tags: [install, drift, hooks, prune-on-value, checkpoint]
parents: [phase-85-install-gap-dogfood]
created: 2026-06-10
updated: 2026-06-10
source: debrief
confidence: high
---

# A3 disposition: keep-current for registration-dead ~/.claude copies

## Context

~/.claude/hooks holds 11 project-scope hook copies that are registration-dead since Phase 84's ghost deregistration (zero references in ~/.claude/settings.json; all live registrations are project-local). Phase 85's A3 was a down-scoped don't-know: the kit fixes (hook_dirs shipping + checker directory currency) proceed independent of these copies' fate, with ship-vs-dispose explicitly routed to checkpoint 1. Options presented: keep the copies current (ship + drift-compare them, per the Phase-82 presence charter "a present installed copy is running code"), or dispose now (delete the dead copies, shrinking the surface).

## Decision

At checkpoint 1 the maintainer chose **keep-current** over dispose-now. The copies stay shipped and drift-compared (directory cells now active for them too); disposal is routed to the next prune-on-value round TOGETHER with the Phase-82 installed-only skill-residue inventory — one subtraction decision over the whole installed-residue class, not a per-phase nibble.

## Consequences

- The Phase-82 presence charter stands unbroken: anything present in an installed root is compared, never silently stale.
- Live ~/.claude run proceeded under keep-current: drift 0 WITH directory cells active; kit hooks == modules.json scope:global set.
- The next prune-on-value round's input queue now holds: registration-dead ~/.claude copies disposal, Phase-82 installed-only residue inventory, A5 memory-layer disposition (zero-demand evidence filed this phase), detect-loop prune candidate, check-tests-were-run harden.
- Cost accepted: until that round, the installer keeps shipping (and the checker keeps comparing) copies nothing registers — visible surface, no silent risk.
