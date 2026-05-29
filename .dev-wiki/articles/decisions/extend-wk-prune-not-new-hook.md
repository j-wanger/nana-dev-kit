---
title: "Extend the existing prune hook, do not add one"
aliases: ["extend-wk-prune-not-new-hook", "curator-extends-wk-prune"]
category: decisions
tags: [memory, hot-cache, working-knowledge, curation, hooks, activation-points]
parents: [phase-62-harden-hot-cache-curation]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The deterministic curator (cap-enforce, exact-proposition dedup, well-formedness bail, atomic write) needs a single enforcement point that runs reliably. The harness already has one: `templates/.claude/hooks/session-start.d/wk-prune.sh` — a sourced function `prune_working_knowledge(WK_FILE, STALE_QUEUE)` called from `session-start.sh`, which already does the age-based >30d `[uses:1]` prune (max 5/run, skips `[pinned]`). The choice is whether to extend that function or add a new hook/script for the new curation logic.

## Decision

**Extend `wk-prune.sh`** — the curator becomes additional logic in the existing `prune_working_knowledge` function, not a new hook or script. This is consistent with [[memory-architecture-classification]]: strengthen existing always-loaded activation points rather than add hooks that can be unwired. Adding hooks has bitten this project three times (the cascade-failure anti-pattern: pre-compact.sh, MCP CWD, nana-init), and a new session-start.d fragment is one more thing that must stay registered and tested.

Alternative rejected: a separate `wk-curate.sh` hook — cleaner separation on paper, but adds a registration surface and a wiring dependency for no functional gain; the prune and the cap/dedup/well-formedness checks all operate on the same file at the same lifecycle moment.

## Consequences

One function owns all hot-cache integrity enforcement at session-start. The existing >30d age-prune behavior is preserved (a regression test asserts it still fires). No new registration in `modules.json` or `settings.json`, no new drift surface. The new invariant test (`tests/test_working_knowledge_curation.sh`) targets the extended function directly.
