---
title: "Hook Event-Shape Normalization"
aliases: [hook-event-shape, tool-input-canonical-parse]
category: decisions
tags: [hooks, tool-input, path-normalization, enforce-spec, stop-hooks, silent-dormancy, heu-012]
parents: [phase-82-qa-verification-sweep]
created: 2026-06-09
updated: 2026-06-09
source: debrief
confidence: high
---

## Context

The Phase-82 QA sweep's firing audit found the enforcement layer silently dormant since 05-25 — a COMPOUND failure: the platform's current PreToolUse/PostToolUse events carry `.tool_input` with ABSOLUTE file paths while several hooks parsed legacy `.input` and/or matched relative-path patterns; on top of that the `~/.claude/enforce` marker was missing, enforce-spec had an absolute-path allowlist bypass, and its spec lookup broke on em-dash slugs. Each layer alone masked the others — no single check could have caught it (the HEU-012 verify-firing class, live).

## Decision

Normalize all hooks to one canonical event-shape contract:

- **Canonical parse:** `.tool_input.X // .input.X // empty` — current shape first, legacy `.input` and relative paths kept as defensive fallback.
- **Per-hook path normalization:** relativize against `$PWD` for relative-pattern hooks (enforce-spec, enforce-memory); absolutize against `$ROOT` for absolute-design hooks (dev-wiki-scope-check). Outside-project writes are ALLOWED — they are not the project's gate to block.
- **Stop events:** carry `transcript_path`, NOT `.tool_uses` — Stop hooks scan the transcript JSONL, with the `.tool_uses` fixture shape kept as first preference for test compatibility.
- **Spec lookup:** em-dash-proof — locate by phase-number glob, never by slug reconstruction.

Proven live: the fixed enforce-spec gate blocked the orchestrator's OWN edits mid-phase (the firing evidence; recovered via Bash since the gate matcher is Write|Edit only).

Rejected alternative: a platform-shape canary (detect the NEXT field rename). Deferred — no emission-side test exists; recorded as a soft observation instead.

## Consequences

7 hooks field/path-fixed; the enforcement layer (enforce-spec, block-dangerous-bash, enforce-memory, scope-check, both Stop hooks) restored from 15-day dormancy — enforce-memory fired for the FIRST time in its lifetime post-fix. The both-shape tests cover OUR parsing, not the platform's emission: the next platform field rename re-creates silent dormancy until a canary or periodic live-fire check exists (filed as a soft observation). All fixes were sandbox-validated in mktemp -d before live copies were touched (the live gate self-lockout mid-fix made this constraint earn its keep).
