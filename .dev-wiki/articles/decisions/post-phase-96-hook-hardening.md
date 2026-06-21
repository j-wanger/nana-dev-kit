---
title: "Post-Phase-96 hook hardening — per-session memory anchor, precise rm-block, content-currency drift"
aliases: [post-phase-96-hook-hardening, per-session-memory-anchor, rm-block-target-policy, drift-content-currency]
category: decisions
tags: [hooks, enforce-memory, block-dangerous-bash, drift, consuming-projects, currency]
parents: [phase-96-consumer-resync-rollout]
created: 2026-06-21
updated: 2026-06-21
source: debrief
confidence: high
---

## Context

After the Phase-96 delivery, a self-resync of nana-dev-kit's own hooks (dogfooding the new
`--migrate-to-local`) surfaced a chain of hook defects, each caught by **verify-by-firing** ([[HEU-012]]).
Three of the fixes carry durable design choices worth recording (the rest is mechanical).

## Decisions

### 1. enforce-memory freshness anchor is per-session_id keyed, not global
The Phase-95 redesign ([[memory-layer-disposition]]) asserted a real in-session `memory_search` whose
timestamp ≥ the **global** `~/.claude/.session-start-ts`. That anchor is shared mutable state: a concurrent
session's SessionStart (or a `--resume`) advances it, falsely excluding a genuine in-session search (observed
live — a ~2h-advanced global blocked a real search). **Decision:** `session-start.sh` ALSO writes a
per-session `~/.claude/.session-start-ts-<session_id>` (session_id from the SessionStart event on stdin, read
only when piped so it can't hang a TTY; every step `|| true` — SessionStart must never break, the Phase-84
machine-wide class); `enforce-memory` prefers the keyed file and **falls back to the global** when absent
(never stricter than before). `--resume` reuses the same session_id, so resumed-session freshness is
preserved. Alternative rejected: transcript-first-event timestamp as the anchor (more parsing, no global
fallback path). Commit `3fa2f0b`.

### 2. block-dangerous-bash blocks dangerous TARGETS, allows relative subpaths
The prior `rm` guard matched `/` anywhere after the flags, so any relative subdir delete with a slash
(`.claude/x`, `build/`) was wrongly blocked, and the `r`-before-`f` flag pattern silently MISSED `rm -fr /`
(a false negative on a catastrophic command). **Decision:** a dangerous target is a standalone argument that
is an ABSOLUTE path (leading `/` — covers `/`, `/*`, `/etc`, `/tmp/x`), `~`/`$HOME`, `..`, or the cwd
(`.`/`./`/`.*`); a relative subpath (no leading slash) is allowed — this exactly removes the false positive
while keeping the prior absolute-path safety envelope. Recursive+force recognized in any order/separation;
the target is tied to the rm within one simple command (`[^;&|]*` never crosses `;`/`&&`/`||`); optional
leading quote (`"$HOME"`); POSIX `[[:space:]]`. Alternative considered: enumerate system dirs only (would
NEWLY allow `/tmp/x`, beyond scope, and require editing the eval fixture) — rejected in favor of the minimal
"absolute = block" policy that matches prior behavior. Commit `55ab629`.

### 3. Drift detection must compare content, not just registration
`check-install-drift --consumer` validated registration topology but never compared hook-FILE content vs
templates, so all 7 consumers ran stale post-Phase-96 hook code while reporting CLEAN — the Phase-84
"single-file currency misses content" lesson ([[install-gap-dir-currency]]) recurring at the consumer layer.
**Decision:** `--consumer` now `cmp -s` each present kit project hook against `templates/.claude/hooks` and
flags `stale: <hook>`; test fixtures ship REAL template content (a "synced" consumer is content-current) +
a seeded stale-content control. **Propagation path:** `install.sh --update` (cp-overwrites hook files);
`nana-init`/`py-init`/`ts-init` are bootstrap-not-upgrade (`transform.md` copies only-if-absent), so they
refresh nothing on an existing consumer. Commit `4b1a502`; all 7 consumers propagated + verified.

## Consequences

Three hooks (enforce-memory, block-dangerous-bash, session-start) and the drift checker changed in templates
+ global `~/.claude` + the 7 consumers. `make test` ALL-PASS, `make eval` 50/50, kit + consumer drift CLEAN.
Future hook-content staleness is now self-detecting at the consumer layer. The Phase-96 consumer VC-durability
follow-up (3 git-tracked consumers, working-tree-only) remains open and filed in Blockers.
