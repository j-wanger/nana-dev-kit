---
title: "Post-Phase-96 hook hardening — self-resync, 2 hook fixes, content-currency drift, consumer propagation"
aliases: [2026-06-21-post-phase-96-hook-hardening]
category: journal
tags: [hooks, enforce-memory, block-dangerous-bash, drift, consuming-projects, self-resync, dogfood, follow-on]
parents: [phase-96-consumer-resync-rollout]
created: 2026-06-21
updated: 2026-06-21
source: debrief
duration: ~one session (post-delivery follow-on, no new phase)
---

# Post-Phase-96 hook hardening

Follow-on work after the Phase-96 delivery was accepted. No new phase planned — a chain of
dogfood-surfaced hook fixes, each verified-by-firing and propagated. 5 commits (all on main, pushed):
`8c4719d` (mark Ph96 article/index completed) → `54d91e0` (self-resync) → `3fa2f0b` (enforce-memory
anchor) → `55ab629` (block-dangerous-bash) → `4b1a502` (drift content-currency + consumer propagation).

## What happened (the dogfood chain)
1. **Self-resync** — re-synced nana-dev-kit's OWN gitignored `.claude/hooks/` to current templates via the
   brand-new Phase-96 `install.sh --migrate-to-local` (its first real use beyond the 7 consumers). Closed
   the Blocker "the kit's own enforce-memory is still the pre-Phase-95 marker". Verified-by-firing.
2. **enforce-memory false block** — firing the freshly-synced (Phase-95 redesigned) hook BLOCKED me despite
   6 real `memory_search` calls in my transcript. Root cause: the freshness anchor was the GLOBAL
   `~/.claude/.session-start-ts`, which a concurrent/resumed SessionStart had advanced ~2h past my searches.
   The hook was correct to demand freshness — the anchor was just shared mutable state. Fix: per-`session_id`
   keyed anchor + global fallback.
3. **block-dangerous-bash false positive** — the `rm -rf .claude/...` I tried during self-resync was blocked
   because the guard matched `/` ANYWHERE after the flags (any relative path with a slash). Fixing it
   surfaced a worse latent bug: `r`-before-`f` requirement → `rm -fr /` was a **false negative** (catastrophic
   command unblocked). Fix: precise target matching + flag-order handling.
4. **The currency gap** — when I checked whether the fixes reached consumers, all 7 were STALE on all 3
   changed hooks (enforce-memory, block-dangerous-bash, session-start) — yet `check-install-drift --consumer`
   reported CLEAN. It checked registration topology, never hook-file CONTENT. Added a content-currency check,
   then propagated all 3 fixes to the 7 consumers via `install.sh --update` (the upgrade path; nana-init is
   bootstrap-only).

## Decisions
- [[post-phase-96-hook-hardening]] (high) — the three durable design choices: per-session keyed memory
  anchor; absolute-path block policy for `rm -rf`; drift detection must compare content not just registration.

## Review Gate
Standard ceremony, but the substantive work was the Phase-96 delivery (adversarially reviewed last session,
28 candidates). This follow-on is bug-fixes, each **verified-by-firing** (HEU-012) in BOTH sandbox controls
tables and the live installed hooks — the operative quality gate here, stronger than a prose review:
- enforce-memory: 4 keyed-anchor tests (concurrent-isolation, resume-freshness, keyed-fallback, session-start
  write); fired live (fallback allows, not locked out).
- block-dangerous-bash: 18 behavioral tests + a 41-case controls table; fired live (`rm -rf .claude/x`→allow,
  `rm -rf /`→block, `rm -fr /`→block). It even blocked its own commit message (literal `rm -rf /` text) —
  routed via `git commit -F`.
- content-currency: test-first (flagged 3 stale hooks on real consumers BEFORE `--update`, clean AFTER);
  seeded stale-content control; positive control (self-resynced kit = 0 stale).

## Health Delta
- `tests/test_tooluse_hooks.sh`: +22 (4 keyed-anchor + 18 block-dangerous) → 43. `tests/test_install_update.sh`:
  +1 stale-content control + builder ships real hooks → 55. `make test` ALL-PASS · `make eval` 50/50
  (denominator unchanged) · kit + all-7-consumer drift CLEAN.
- Behavior changes shipped to templates + global `~/.claude` + the 7 consumers: enforce-memory (per-session
  anchor), block-dangerous-bash (precise targets), session-start (keyed-anchor write); check-install-drift
  gained a content-currency dimension.

## Gate Compliance
Phase 96 gate-log `delivery=accepted` (flipped last session, 973e78e verified). No new phase → no new gate.
Assumption-ledger Phase-96 rows all `held` (no blank revisit-status). This session opened no ledger block
(no dev-plan; follow-on fixes under the post-delivery norm).

## Soft Observations / Phase N+1 Candidates
- **Consumer VC-durability (still open)** — the 3 git-tracked Phase-96 consumers (edge-analyst, ai-game
  committed; fate staged) remain consolidated working-tree-only; committing a kit-clean settings.json +
  detect-loop deletion per repo is the durability follow-up. Note: the post-Phase-96 hook refreshes ALSO
  only touched working trees (consumer `.claude/hooks` are gitignored, so no consumer commit needed for the
  hooks themselves — but the tracked settings.json topology revert risk persists). Evidence:
  `eval/consumer-resync/rollout-evidence.md` "Version-control durability".
- **A periodic consumer-currency sweep** — now that `check-install-drift --consumer` detects content drift,
  a small script that runs it across all known consumer roots (kit-marker discovery, à la Phase-83/84) would
  catch staleness proactively instead of on-question. Candidate for a tiny maintenance phase.
- **basename-collision (carried from Phase 96)** — `--update`/`--migrate-to-local` dereg/relocate is
  basename-keyed; a consumer custom hook sharing a kit basename is treated as kit-managed. A `--dry-run`
  content-diff warning (stock vs present) would surface it. None of the 7 hit this.
