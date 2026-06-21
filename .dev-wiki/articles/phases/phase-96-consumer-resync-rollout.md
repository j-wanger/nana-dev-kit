---
title: "Phase 96: Consumer Re-sync Rollout (consolidate-to-local + live --update across all 7)"
aliases: [phase-96-consumer-resync-rollout, consumer-resync-rollout-phase, migrate-to-local-phase]
category: phases
tags: [install, consuming-projects, hooks, registration, deregistration, settings-topology, consolidation, rollout]
parents: []
created: 2026-06-21
updated: 2026-06-21
source: plan
status: completed
scope: ["install.sh", "tests/test_install_update.sh", "scripts/check-install-drift.sh", "scripts/register-settings.py", "eval/consumer-resync/**", "README.md", "AGENTS.md", "MANIFEST", "Makefile", ".dev-wiki/**"]
entry_criteria: "Phase 95 delivery accepted (3d401d5 + b960c70); Phase-93 install.sh --update built + sandbox-verified; spec specs/phase-96-consumer-resync-rollout.md nana:approved; Phase-96 ledger block appended + validated; direction gate closed (all_accept:false — A1 reject->consolidate, A2/A3/A4 accept, A5 reject->arm signal-watch+aml-casework)"
exit_criteria: "tests/test_install_update.sh PASS (new settings.json-topology fixture + post-migration idempotency + both seeded controls); --migrate-to-local dry-run/real correct + idempotent + both-file backup round-trips + survivor smoke; check-install-drift --consumer flags settings.json kit-regs; make test + make eval 50/50 + kit drift 0; ALL 7 consumers live on settings.local-only topology (working-tree/runtime), detect-loop ghost-free, post-drift clean, idempotent, survivor smoke (Group-B fired live in migrate; ready-3 probe byte-identity); armed set = edge-screener/edge-analyst/aml-substrate/signal-watch/aml-casework (ai-game+fate unarmed); NOTE 3 git-tracked consumers consolidated working-tree-only (VC durability = maintainer follow-up); Phase-93 deferred live-application Blockers filing RESOLVED; ## Phase 96 window-events; eval/consumer-resync/run-exit-criteria.sh ALL-PASS"
---

# Phase 96: Consumer Re-sync Rollout (consolidate-to-local + live --update across all 7)

## Objective

Realize the banked, sandbox-only Phase-93 `install.sh --update` value LIVE across all 7 consuming
projects, after extending the kit with a one-shot `install.sh --migrate-to-local` that consolidates
`settings.json`-resident kit-hook registrations into gitignored `settings.local.json`. End state: every
consumer on ONE canonical topology (`settings.local.json`), reconciled to the current kit hook set,
`detect-loop` deregistered with NO ghost left behind, and signal-watch + aml-casework armed.

## Why this shape

A Phase-96 planning probe of the 7 live consumers REVERSED the Phase-93 deferred-filing premise. `--update`
hardcodes `.claude/settings.local.json`, but **4 of 7 consumers register their kit hooks in
`.claude/settings.json` (project scope)** — edge-analyst, ai-game, fate, aml-casework. On those, running
`--update` as-built would `rm detect-loop.sh` while its registration sits in `settings.json` (a **ghost
registration** — the registered-but-broken class bitten 5×, [[install-gap-dir-currency]] / [[HEU-012]])
AND spawn a parallel `settings.local.json` → cross-file double-fire
([[drq-1-settings-merge-semantics-are-string-keyed]]). The Phase-93 fixtures modeled only
`settings.local.json` — an unmodeled drift class. `settings.local.json` is gitignored in all consumers;
`settings.json` is git-TRACKED in 3 of the 4 Group-B consumers.

Maintainer direction-gate positions (ledger Phase 96; all_accept:false): **A1 REJECT** in-place reconcile →
**consolidate-to-local** (one canonical gitignored topology; existing `--update` UNCHANGED; a one-shot
`--migrate-to-local` does the cross-file move). **A4 ACCEPT** roll out all 7 live this phase, gated/reversible,
ai-game (73 dirty files) snapshot-first. **A5 REJECT** fully-decoupled arming → arm signal-watch +
aml-casework; ai-game + fate stay unarmed; the 3 already-armed untouched.

## Approach

Controls-first build (T1 fixtures + seeded controls BEFORE the mode → T2 `--migrate-to-local` with both-file
backup + survivor smoke + revert → T3 drift-comparator + docs + kit-green + HARD checkpoint), then the gated
live rollout — ready-3 via `--update` (T4) and Group-B 4 via `--migrate-to-local` then `--update` (T5) — then
close-out (T6). The migration reuses the existing `register-settings.py hooks`/`deregister`
(file-path-agnostic) and `survivor_smoke_ok` (state-independent, `block-dangerous-bash.sh`-driven, fires on
unarmed consumers too) — no new primitives.

See `specs/phase-96-consumer-resync-rollout.md` and decision [[consumer-resync-rollout]].
