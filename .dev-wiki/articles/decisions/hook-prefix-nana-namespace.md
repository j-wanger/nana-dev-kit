---
title: "Hook prefix [nana:<hook>] namespace"
aliases: [hook-prefix, nana-prefix, hook-message-format]
category: decisions
tags: [hooks, dx, discoverability, message-format]
parents: [phase-28-dx-discoverability]
created: 2026-05-23
updated: 2026-05-23
source: plan
confidence: high
---

## Context

Hook messages currently use 6 distinct patterns: `[tag]`, `Blocked:`, `Warning:`, bare text, `===` headers, and JSONL. This inconsistency impairs debuggability -- when Claude or the user sees hook output, there's no reliable way to identify which hook produced it or whether the message is from harness infrastructure vs shell output.

## Decision

**Adopt `[nana:<hook-name>]` as universal prefix for all hook messages.** The `nana:` namespace helps Claude distinguish harness output from shell output, and the hook name makes the source identifiable at a glance.

**Exception: `[dev-wiki:post-commit]` kept as semantic trigger.** This string is referenced by dev-wiki-hooks rules as a trigger pattern. Renaming it would require coordinated changes across rules files and would break the semantic contract.

**`[warn]` subsumed into `[nana:<hook>]`.** The jq fail-open guard pattern previously used `[warn]` for fallback messages. These become `[nana:<hook>] jq not found, skipping` -- still informational, but now identifiable by source.

Alternative considered: plain `[hook-name]` without namespace -- rejected because nana: namespace helps Claude distinguish harness output from arbitrary shell output. Alternative: keep current mixed patterns -- rejected because inconsistency impairs debuggability and discoverability.

## Consequences

- All 11 hooks need prefix updates. 5 eval scenarios need assertion updates to match new prefix strings.
- session-start.sh gets semantic sub-prefixes: `[nana:gate]`, `[nana:memory]`, `[nana:recovery]`, `[nana:pending]`, `[nana:enforce]` for its multiple output categories.
- Future hooks must follow the `[nana:<hook>]` convention -- this becomes a project convention.
- Eval assertions use substring matching, so only the key substring needs to change (not full-line rewrites).
