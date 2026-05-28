---
title: "Bidirectional Registration Invariant"
aliases: [registration-completeness-test]
category: decisions
tags: [testing, registration, integrity, anti-pattern]
parents: [phase-55-harness-activation-overhaul]
created: 2026-05-28
updated: 2026-05-28
source: debrief
confidence: high
---

## Context

The functional smoke invariant (Phase 41) checks "does registered stuff work?" but not "is stuff registered?". The nana-init cascade failure (Phase 55) revealed an orphaned-component anti-pattern: a skill listed in modules.json but never installed, and a prompt file existing on disk but not registered. Three prior incidents of the same class (pre-compact.sh, MCP CWD, nana-init).

## Decision

Add a bidirectional registration completeness test (test_registration.sh, 40 assertions) that checks both directions: (a) every hook script on disk has a modules.json entry, (b) every modules.json hook entry exists as a file. This complements the functional smoke invariant which only checks direction (b).

## Consequences

Future orphaned components caught at `make test` time. The test is structural (cheap, deterministic) and runs before behavioral tests. Expands the functional smoke invariant from "registered stuff works" to "registered stuff works AND all stuff is registered."
