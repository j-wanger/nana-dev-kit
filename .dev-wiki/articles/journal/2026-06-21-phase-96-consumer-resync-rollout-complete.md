---
title: "Phase 96 complete — Consumer Re-sync Rollout (consolidate-to-local + live --update across all 7)"
aliases: [2026-06-21-phase-96-consumer-resync-rollout-complete]
category: journal
tags: [install, consuming-projects, hooks, registration, deregistration, settings-topology, consolidation, live-rollout, adversarial-review, ultracode]
parents: [phase-96-consumer-resync-rollout]
created: 2026-06-21
updated: 2026-06-21
source: debrief
duration: ~one long session (plan -> implement -> live rollout -> adversarial review -> deliver)
---

# Phase 96 complete — Consumer Re-sync Rollout

## What Happened
- Realized the banked, sandbox-only Phase-93 `install.sh --update` value LIVE across all 7 consuming
  projects. The phase the Phase-92 product-for-consumers frame pointed at — turn built capability into
  applied value.
- **The planning probe reversed the Phase-93 premise.** `install.sh --update` hardcodes
  `settings.local.json`, but a live probe of all 7 consumers found **4 of 7** (edge-analyst, ai-game,
  fate, aml-casework) register their kit hooks in **`settings.json` (project scope, git-tracked)**.
  Running `--update` there would `rm detect-loop.sh` while its registration sat in `settings.json` (a
  ghost — the registered-but-broken class bitten 5×) AND spawn a parallel `settings.local.json`
  (DRQ-1 cross-file double-fire). The "probe the live machine before pinning an install/topology spec"
  lesson ([[install-resync-update-mode]] / Phase-91) earned its keep again.
- **Maintainer A1 chose consolidate-to-local over in-place reconcile** (direction gate, all_accept:false):
  a new one-shot `install.sh --migrate-to-local` relocates `settings.json` kit regs into gitignored
  `settings.local.json` + basename-deregisters kit/cut hooks from `settings.json` (both-file backup →
  survivor smoke → revert; existing `--update` UNCHANGED). One canonical topology; each hook in exactly
  one file → DRQ-1 double-fire structurally impossible.
- Built controls-first (settings.json-topology fixture + seeded controls, RED→GREEN), passed a HARD
  checkpoint (sandbox + all-7 live dry-runs presented before any write), then applied live gated
  per-consumer: ready-3 via `--update` (signal-watch onboarded+armed, edge-screener, aml-substrate);
  Group-B via `--migrate-to-local`→`--update` (aml-casework armed). ai-game's 73 dirty files
  WIP-committed first. End state (working-tree/runtime): every consumer 17-hook kit set in
  `settings.local.json` only, `settings.json` kit-clean, detect-loop ghost-free, drift CLEAN.
- Armed = {signal-watch, edge-screener, aml-substrate, edge-analyst, aml-casework}; unarmed =
  {ai-game, fate} — exactly the A5 decision. Resolves the Phase-93 deferred live-application filing.

## Decisions
- [[consumer-resync-rollout]] (high) — consolidate-to-local via `--migrate-to-local`; live rollout all 7,
  gated; arm signal-watch + aml-casework.

## Review Gate (ultracode — 4-lens adversarial workflow, 28 candidates, orchestrator-verified)
Subagents are read-only candidate-generators in-kit (working-knowledge leak ⇒ prose ≠ evidence,
[[qa-verification-sweep]]); every finding was confirmed/refuted by a deterministic orchestrator-run check.
Verdict: **REVISE → fixed inline before delivery.**
- **Code fixes (tests added, 54/54):** (1) `--migrate-to-local --arm` on a no-`.claude` consumer crashed
  (`touch` before `mkdir`); (2) migrate now **ships the kit hook files** (mirrors `--update`) so a
  standalone migrate can't leave registered-but-missing and the survivor smoke is never vacuous;
  (3) `run-exit-criteria.sh` now asserts **no DRQ-1 duplicate** (raw vs distinct), not just ≥17 distinct.
- **The miss worth recording — version-control durability (HIGH):** the consolidation is **working-tree
  only**. Claude Code reads the working tree, so runtime is correct now; but for the 3 git-tracked
  consumers (edge-analyst, ai-game committed; fate staged) HEAD/index still registers detect-loop + the
  old kit set, and the relocated kit regs live in *gitignored* `settings.local.json` (not under VC). A
  `checkout`/`reset`/fresh-clone reverts them; ai-game's committed `settings.json` even retains a
  duplicate `scan-secrets.sh`. Making it durable = committing a kit-clean `settings.json` + the
  detect-loop deletion per tracked consumer — a maintainer follow-up (runtime correct regardless).
- **Claim corrections:** ready-3 "survivor smoke" was byte-identity, not a live firing (`--update` had no
  dereg); Group-B "both-file backup" was one file (no pre-existing local); `.migrate-backup` dirs aren't
  gitignored. All corrected in `eval/consumer-resync/rollout-evidence.md`.
- **Documented limitations (not defects):** dereg is basename-keyed (DRQ-1 requires it) → a consumer's
  custom hook sharing a kit basename would be treated as kit-managed (none of the 7 had one); empty
  event-arrays remain in settings.json post-dereg (inert); "drift CLEAN" uses the same-phase
  global-hook-exclusion checker (disclosed).

## Health Delta
- `tests/test_install_update.sh` 37 → 54 assertions (settings.json-topology fixture, seeded controls,
  migrate cases, ships-files + bare-arm guards, drift cases). `make test` ALL-PASS · `make eval` 50/50
  (denominator unchanged) · kit drift 0.
- New kit surface: `install.sh --migrate-to-local`; `scripts/check-install-drift.sh --consumer`
  settings.json-topology detection + global-hook cut-exclusion; `eval/consumer-resync/{rollout-evidence.md,
  run-exit-criteria.sh}`.

## Gate Compliance
- Direction gate: approved 2026-06-21 (ledger Phase 96; all_accept:false — A1 reject→consolidate,
  A2/A3/A4 accept, A5 reject→arm-some). Delivery gate: pending (this debrief).
- Assumption-ledger revisit: A1/A2/A3/A4/A5 all **held** (no assumption bit); A2's "BOTH settings files"
  wording was Group-B-imprecise (only settings.json existed pre-migrate) but the reversibility intent held.

## Soft Observations / Phase N+1 Candidates
- **Make the consolidation version-control-durable** (commit a kit-clean settings.json + detect-loop
  deletion in edge-analyst, ai-game, fate). Cleanest as per-consumer sessions in each repo; fate needs
  its commit hook satisfied, ai-game its unrelated dirt handled. Evidence:
  `eval/consumer-resync/rollout-evidence.md` "Version-control durability".
- **enforce-memory in-repo is still the gameable marker.** This session was blocked until I `touch`ed
  `.claude/.memory-consulted` — the Phase-95 redesign (real memory_search assertion) shipped to
  `templates/` + `~/.claude` but nana-dev-kit's own installed hook still uses the marker. A drift between
  the redesigned template and the kit's own installed copy; worth a re-sync (and `session-start.sh:110`'s
  vestigial `.memory-consulted` clear is now load-bearing again). Evidence: the blocked Edit calls + the
  marker touch this session.
- **`--migrate-to-local` self-completeness generalizes.** Shipping files in migrate (post-review fix)
  closes the registered-but-missing class for that mode; the same "a mode that registers must also ship
  the files it registers" invariant could be a smoke test across all install paths.
- **basename-collision is a latent kit-wide assumption.** Both `--update` dereg and `--migrate-to-local`
  treat kit basenames as kit-owned. If a consumer ever ships a custom hook under a kit basename, it's
  silently overridden. A `--dry-run` content-diff warning (stock vs present) would surface it.
