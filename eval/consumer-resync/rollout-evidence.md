# Phase 96 — Consumer Re-sync Rollout: live evidence

Live application of `install.sh` across all 7 consuming projects, 2026-06-21, gated per-consumer behind
the HARD checkpoint (sandbox-verified first: `tests/test_install_update.sh` 52/52, `make test` ALL-PASS,
`make eval` 50/50, kit drift 0). Each consumer: WIP-commit `.claude` if dirty → apply → verify.

## End state (authoritative)

| consumer | pre-topology | mode | local regs | json hook regs | detect-loop (json/local/file) | drift | idempotent | survivor smoke | armed |
|---|---|---|---|---|---|---|---|---|---|
| signal-watch | greenfield (no `.claude`) | `--update --arm` | 17 | 0 | 0/0/0 | CLEAN | OK | probe==template | **armed** (new) |
| edge-screener | `settings.local.json` | `--update` | 17 | 0 | 0/0/0 | CLEAN | OK | probe==template | armed (kept) |
| aml-substrate | `settings.local.json` | `--update` | 17 | 0 | 0/0/0 | CLEAN | OK | probe==template | armed (kept) |
| edge-analyst | `settings.json` | `--migrate-to-local` → `--update` | 17 | 0 | 0/0/0 (removed) | CLEAN | OK | probe==template (fired live in migrate dereg) | armed (kept) |
| ai-game | `settings.json` (73 dirty) | `--migrate-to-local` → `--update` | 17 | 0 | 0/0/0 (removed) | CLEAN | OK | probe==template (fired live) | unarmed (kept) |
| fate | `settings.json` | `--migrate-to-local` → `--update` | 17 | 0 | 0/0/0 (removed) | CLEAN | OK | probe==template (fired live) | unarmed (kept) |
| aml-casework | `settings.json` | `--migrate-to-local --arm` → `--update` | 17 | 0 | n/a (no detect-loop) | CLEAN | OK | probe==template (fired live) | **armed** (new) |

**Invariant achieved on all 7:** every kit hook registered exactly once, in gitignored `settings.local.json`
only (`settings.json` kit-clean), so the DRQ-1 cross-file double-fire is structurally impossible
([[drq-1-settings-merge-semantics-are-string-keyed]]); `detect-loop` deregistered with no ghost
([[install-gap-dir-currency]] / [[HEU-012]]); current 17-hook kit project set present + registered.

**Arming (A5):** armed = {signal-watch, edge-screener, aml-substrate, edge-analyst, aml-casework};
unarmed = {ai-game, fate}. signal-watch + aml-casework newly armed this phase; the 3 already-armed kept;
ai-game + fate deliberately left unarmed. `--update`/`--migrate-to-local` touched `.claude/enforce` only
with `--arm`.

> The end-state table is the **working-tree / runtime** state — what Claude Code actually loads (it reads the
> on-disk `.claude/settings.json` + `settings.local.json`, NOT git HEAD). Runtime behavior is correct on all
> 7 now. See "Version-control durability" below for the git-tracked-consumer caveat the pre-delivery review surfaced.

## Safety / recovery
- Each Group-B migration wrote a timestamped `.claude/.migrate-backup.<ts>/` — the rollback point. It holds
  `settings.json` + the removed cut files; **`settings.local.json` did NOT exist pre-migrate** for any Group-B
  consumer, so only one settings file was actually backed up (revert removes the migrate-created local; correct
  by construction). Dirs: edge-analyst 131517, ai-game 131519, fate 131525, aml-casework 131527.
- The `.migrate-backup.<ts>/` dirs live inside the (tracked) `.claude/` tree and are **NOT gitignored** — they
  contain `detect-loop.sh`. Do NOT `git add -A` them into a consumer; exclude them from any consumer commit.
- Pre-rollout `.claude` state WIP-committed per consumer (ai-game's 73 files; edge-screener; aml-substrate clean).
  fate's snapshot is **staged, not committed** (a fate-side commit hook blocked the commit) — the staged index +
  the `.migrate-backup` give recovery, but a `git reset` would lose the staged index, so fate leans on the backup dir.
- **Survivor smoke fired live ONLY for Group-B** (`--migrate-to-local`): `block-dangerous-bash.sh` (payload-driven,
  state-independent) exit-2/exit-0 inside each migrate dereg — the migration completes only if it passes (HEU-012).
  The ready-3 used `--update` with NO cut to deregister, so install.sh's internal `survivor_smoke_ok` was **not
  invoked** there; their probe was verified by **byte-identity** to the suite-proven template (the table's
  `probe==template` column), NOT by a live firing. (Post-review, `--migrate-to-local` now also ships the hook files,
  so its smoke can never go vacuous on a probe-missing consumer.)

## Version-control durability (pre-delivery review finding — IMPORTANT)
The consolidation is applied to the **working tree** (runtime-correct now). For the 3 consumers whose `.claude/`
is git-tracked it is **NOT yet version-control-durable**:
- **edge-analyst, ai-game** — committed `.claude/settings.json` at HEAD STILL registers `detect-loop` + the old
  kit set, and `detect-loop.sh` is still a tracked file. The relocated kit regs live in **gitignored**
  `settings.local.json` (not under version control). A `git checkout`/`reset --hard`/`clean`/fresh clone would
  revert the working tree to the old topology (detect-loop ghost back, kit regs gone until `install.sh --update`).
- **ai-game** — HEAD `settings.json` additionally carries a pre-existing **duplicate `scan-secrets.sh`**
  registration (DRQ-1) that the working-tree consolidation removed but the committed copy retains.
- **fate** — the consolidation is unstaged working-tree edits over a staged PRE-migrate index (detect-loop staged).
- signal-watch, edge-screener, aml-substrate — settings live in gitignored `settings.local.json` only; no tracked
  settings.json carries kit regs, so no committed-ghost concern.

**To make it durable** (the consumer's own git decision): in each tracked consumer, commit a kit-clean
`settings.json` + the `detect-loop.sh` deletion (`settings.local.json` stays gitignored — kit hooks are personal,
re-created by `install.sh --update`). fate's commit hook must be satisfied or bypassed; ai-game's unrelated dirt
handled. **Deferred to a maintainer decision at the delivery gate** — runtime is correct regardless.

## In-kit refinement discovered during rollout
- `context-size-check.sh` (scope=global) sits as an **unregistered stray file** in 5 consumers (registered
  nowhere — never fires per-project; the real one fires from `~/.claude`). The `--consumer` drift checker
  over-flagged it as "cut". Fixed: `check-install-drift.sh` now excludes kit **global**-scope hooks from the
  consumer cut flag (a global kit hook strayed into a project dir is not "a cut hook the kit no longer ships").
  Test added; `make test` ALL-PASS. The stray files are left in place (not consumer cruft we may nuke).

## Pre-delivery adversarial review (28 candidates, orchestrator-verified)
A 4-lens read-only workflow generated candidate defects; each was confirmed/refuted by a deterministic
orchestrator-run check (subagent prose is non-evidence in-kit — [[qa-verification-sweep]]). Outcome:
- **Code fixes applied** (tests added, 54/54): (1) `--migrate-to-local --arm` on a consumer with no `.claude/`
  crashed (`touch` before `mkdir`) → fixed; (2) migrate now **ships the kit hook files** (mirrors `--update`)
  so a standalone migrate cannot leave registered-but-missing and the survivor smoke is never vacuous;
  (3) `run-exit-criteria.sh` now asserts **no DRQ-1 duplicate** (raw vs distinct count), not just `≥17 distinct`.
- **Claim corrections** (above): ready-3 smoke is byte-identity not a live firing; Group-B backup is one file
  (no pre-existing local); `.migrate-backup` is not gitignored; the **version-control durability** caveat for the
  3 git-tracked consumers.
- **Known limitations (documented, not defects):** dereg/relocate is **basename-keyed** (DRQ-1 requires it), so a
  consumer's custom hook sharing a kit basename would be treated as kit-managed — none of the 7 had one; the
  settings.json `hooks` object retains empty event-arrays post-dereg (functionally inert, not a clean `{}`); the
  "drift CLEAN" verdict uses the same-phase global-hook-exclusion checker (disclosed under In-kit refinement).
