---
title: "Drift Checker Compares Installed Presence, Not Scope Tags"
aliases: [drift-pass-2b, installed-presence-comparison]
category: decisions
tags: [drift, install, hooks, modules-json, ghost-registrations, stale-copies]
parents: [phase-82-qa-verification-sweep]
created: 2026-06-09
updated: 2026-06-09
source: debrief
confidence: high
---

## Context

`check-install-drift.sh` (Phase 76) built its comparison set from modules.json scope tags: installed skills + `scope:global` hooks. But pre-Phase-79 GLOBAL installs left 11 project-scoped hooks physically present in `~/.claude/hooks/` — live code the scope-tag comparison never looked at. The Phase-82 drift audit found those 11 runtime copies STALE the same morning the checker reported "drift 0": a blind spot exactly shaped like the Phase-73/75 stale-installed-copy scars.

## Decision

Add pass 2b: any kit-shipped hook PRESENT in the installed root is compared regardless of its modules.json scope tag — presence = live code, and live code must match source. Boundaries held:

- The checker never ADDS files — refreshing stale copies stays install.sh's job (detect-and-warn, per [[installed-copy-drift-guard]]).
- User-owned non-kit hooks in the installed root are ignored (ownership boundary).
- Hermetically tested in both directions (stale-present flagged; non-kit ignored).

Ghost global REGISTRATIONS (the 11 entries still in ~/.claude/settings.json) are explicitly NOT handled here — deregistering changes live wiring in every project, a maintainer call, filed as a deferred Blocker.

## Consequences

The 11 stale runtime copies were refreshed this phase and now stay inside the comparison set — "drift 0" now means 0 under an EXTENDED set, not a blind one. The presence rule generalizes: a scope tag describes intent; the filesystem describes what actually runs — comparisons must follow the filesystem. Residue (installed-only skill inventory, checker-header memory_server omission, dead settings.json EXCLUDE entry) filed in the Phase-82 drift Blocker.
