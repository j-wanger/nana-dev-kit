<!-- nana:approved 2026-06-21 (dev-plan --internal) -->
# Spec: Phase 96 — Consumer Re-sync Rollout (consolidate-to-local + live `--update` across all 7)

## Objective

Realize the banked, sandbox-only Phase-93 `--update` value LIVE across all 7 consuming projects, after extending the kit with a one-shot `install.sh --migrate-to-local` that consolidates `settings.json`-resident kit-hook registrations into gitignored `settings.local.json`. Result: every consumer reaches one canonical registration topology (`settings.local.json`), is reconciled to the current kit hook set, has the cut `detect-loop` deregistered with no ghost left behind, and signal-watch + aml-casework are armed. **Build-then-verify-in-sandbox the migration, then apply live per-consumer behind dry-run-first + backup + survivor smoke + revert.**

## Context

Phase 93 built `install.sh --update` (ADD/UPDATE + dedupe-by-basename + automated cut-hook dereg behind rails) and proved it in mktemp sandboxes only — ZERO live consumer writes ([[install-resync-update-mode]]). The live-application follow-on was filed in Blockers (dry-run-first, per consumer, arm separately). A live probe at Phase-96 planning REVERSED the filing's premise: `--update` hardcodes `.claude/settings.local.json`, but **4 of 7 consumers register their kit hooks in `.claude/settings.json` (project scope)** — edge-analyst, ai-game, fate, aml-casework. On those, `--update` as-built would (a) `rm detect-loop.sh` while its registration sits in `settings.json` → a **ghost registration** (the registered-but-broken class, bitten 5× — [[install-gap-dir-currency]], [[HEU-012]]), and (b) write a *second* registration set into a new `settings.local.json` → cross-file double-fire ([[drq-1-settings-merge-semantics-are-string-keyed]]). The Phase-93 fixtures only modeled `settings.local.json` — this is an unmodeled drift class, exactly the checkpoint clause "record it for the deferred follow-on."

Live landscape (planning probe, 2026-06-21):

| consumer | reg topology | settings.json git | armed | `--update` dry-run |
|---|---|---|---|---|
| signal-watch | none (greenfield) | — | no | clean onboard (add 17) |
| edge-screener | `settings.local.json` | — | yes | add enforce-assumption-gate + refresh |
| aml-substrate | `settings.local.json` | — | yes | refresh-only |
| edge-analyst | `settings.json` | TRACKED | yes | orphans detect-loop reg + spawns parallel local |
| ai-game | `settings.json` | TRACKED | no | same + **73 dirty .claude files** |
| fate | `settings.json` | untracked | no | same |
| aml-casework | `settings.json` | TRACKED | no | parallel local (no detect-loop) |

`settings.local.json` is gitignored in all consumers; `cut_hooks = ["detect-loop"]`; `context-size-check.sh` is the global-scope hook correctly FLAGGED-but-left. Re-sequenced from the Phase-92 product-for-consumers frame ([[strategic-inflection-review]]).

## Scope

### In scope
- **`install.sh --migrate-to-local`** (new one-shot mode): for a consumer whose kit-hook/cut-hook registrations live in `.claude/settings.json`, register the current project-scope kit set into `.claude/settings.local.json` and basename-deregister the kit-managed + cut-hook (`detect-loop`) registrations from `.claude/settings.json`. Idempotent (re-run on a migrated consumer = no-op). `--dry-run` reconciliation diff. Reuses `register-settings.py hooks/deregister` (file-path-agnostic) — no new primitives. `--arm` honored (decoupled).
- Safety rails for the destructive cross-file op: `--dry-run`; timestamped backup of **BOTH** `settings.json` AND `settings.local.json`; survivor functional smoke (a kept enforce hook fires allow+block); revert-on-failure.
- Controls-first `tests/test_install_update.sh` extension: new fixtures (settings.json-topology consumer; post-migration single-file idempotency) + seeded controls (a `detect-loop` registration in `settings.json` the migration MUST remove; `settings.json` kit-regs that MUST relocate to local). Clean-on-seed = instrument-dead.
- `check-install-drift.sh --consumer` extended to detect `settings.json`-resident kit-hook registrations as a drift class.
- **Live rollout, all 7, gated per consumer**: pre-flight `check-install-drift --consumer` (read-only) → `--update --dry-run` (or `--migrate-to-local --dry-run` for Group B) → maintainer review → apply → post-state verify (drift 0, idempotent re-run no-op, survivor smoke). git-snapshot dirty trees first (ai-game's 73 files committed/stashed before any write).
- **Arm signal-watch + aml-casework** (`.claude/enforce`); ai-game + fate left unarmed; the 3 already-armed untouched.
- Docs (install.sh header, README, AGENTS pointer); Makefile/MANIFEST currency.

### Out of scope
- Two-file-aware in-place `--update` (A1 reject — consolidation chosen instead; existing single-file `--update` stays UNCHANGED).
- Arming ai-game / fate; disarming any already-armed consumer.
- Memory-layer changes (closed Phase 95); editing user-owned `~/.claude/rules/` or Claude Code native settings.
- Reverting d43950f / df3e623 / 75b48af / b8bd416; frozen apparatus (eval/amplifier|assumption-screen|qa-sweep|memory-remeasure/**).

## Approach

Consolidate-to-local (A1): the kit's single canonical hook topology is gitignored `settings.local.json` for every consumer. Build `--migrate-to-local` controls-first (T1 fixtures+seeded controls BEFORE the mode, so the cross-file dereg is proven to remove a seeded `settings.json` detect-loop and relocate seeded `settings.json` kit-regs before it is ever trusted), then the mode itself with both-file rails (T2), then the drift-comparator + docs (T3), then the gated live rollout — ready-3 via `--update` (T4) and Group B via `--migrate-to-local` then `--update` (T5) — then close-out (T6). Group B exercises the new cross-file dereg LIVE; every per-consumer apply is dry-run-reviewed and reversible via the timestamped backup. The existing `--update` is reused unchanged for the already-`settings.local.json` consumers.

## Constraints
- Existing single-file `--update` stays byte-unchanged except where shared helpers are reused; the new behavior lives in `--migrate-to-local`.
- Controls-first: the migration path must FIRST catch its seeded controls (settings.json detect-loop removed; settings.json kit-regs relocated) in mktemp; clean-on-seed = instrument-dead → STOP.
- The destructive migration NEVER runs without a timestamped backup of BOTH settings files + a tested restore; revert-on-failure on a failed survivor smoke.
- Sandbox-first for any settings surgery (mktemp -d, never live); assert allow AND block survivor paths before trusting (HEU-012).
- Idempotent — a second `--migrate-to-local`/`--update` run produces no change.
- Arming decoupled — `.claude/enforce` touched ONLY for signal-watch + aml-casework via explicit `--arm`/marker; never elsewhere.
- Live writes are per-consumer, dry-run-reviewed, git-snapshot-first; a consumer holding a drift class not modeled by the fixtures STOPs that consumer (model it, re-verify) — do not force.

## Checkpoints
- **After T1:** the fixture harness must FLAG both seeded controls (settings.json detect-loop registration; settings.json kit-regs needing relocation) before any migration logic is written — if not, STOP (instrument-dead).
- **After T3 (HARD, pre-live):** report the `--migrate-to-local` dry-run diff on the staged fixtures + the both-file backup/restore round-trip + survivor smoke + `make test`/`make eval`/kit-drift-0 to the maintainer BEFORE any live consumer write.
- **Per consumer during T4/T5:** present the live `--dry-run` diff for maintainer review before the real apply; ai-game's 73 dirty files are committed/stashed first.
- If a real consumer holds an unmodeled drift class: STOP that consumer, record it, re-model + re-verify in sandbox before applying.

## Assumptions
(Direction-gate positions — `.dev-wiki/assumption-ledger.md` Phase 96; all_accept: false)
- A1 (reject→consolidate): consolidate-to-local via a one-shot `--migrate-to-local`; existing `--update` unchanged.
- A2 (accept): rails back up BOTH settings files before any removal.
- A3 (accept): controls-first fixtures + seeded controls gate the build.
- A4 (accept): roll out all 7 live this phase, gated/reversible, ai-game snapshot-first.
- A5 (reject→arm-some): arm signal-watch + aml-casework; ai-game + fate stay unarmed.

## Exit Criteria
- [ ] `bash tests/test_install_update.sh` passes, including the new settings.json-topology fixture, post-migration idempotency, and both seeded controls (settings.json detect-loop removed; settings.json kit-regs relocated to local)
- [ ] `install.sh --migrate-to-local --dry-run` on a staged settings.json-topology fixture prints a correct diff (relocate kit regs to local, deregister detect-loop from settings.json) and writes nothing; the real run yields kit regs only in `settings.local.json`, `settings.json` kit-clean, `detect-loop` gone from both, `.claude/enforce` unchanged; a second run is a no-op
- [ ] destructive migration produces a timestamped backup of BOTH settings files and the tested restore round-trips; survivor smoke fires exit-2-on-block + exit-0-on-allow after migration
- [ ] `check-install-drift.sh --consumer` flags a settings.json-resident kit-hook registration as drift
- [ ] `make test` ALL-PASS (fixtures registered); `make eval` 50/50 (denominator unchanged); kit `check-install-drift` drift 0
- [ ] **Live, all 7 (working-tree / runtime state):** each consumer reconciled to the current kit set in `settings.local.json` only, `detect-loop` deregistered with no ghost, post-apply `check-install-drift --consumer` clean, idempotent re-run no-op; survivor smoke fired **live for Group-B** (migrate dereg) — the ready-3 `--update` path has no dereg, so its probe is verified by **byte-identity** to the suite-proven template, not a live firing; per-consumer rollout evidence table recorded (consumer | topology | actions | post-drift | idempotent | smoke). NOTE (pre-delivery review): for the 3 git-tracked consumers (edge-analyst, ai-game committed; fate staged) the consolidation is working-tree-only — committed/staged `settings.json` still carries the old topology; version-control durability is a maintainer follow-up (see `eval/consumer-resync/rollout-evidence.md`).
- [ ] signal-watch + aml-casework armed (`.claude/enforce` present); ai-game + fate unarmed; the 3 prior-armed still armed; no consumer disarmed
- [ ] Phase-93 deferred live-application Blockers filing RESOLVED; `## Phase 96` window-events append; decision article + `eval/consumer-resync/run-exit-criteria.sh` ALL-PASS
