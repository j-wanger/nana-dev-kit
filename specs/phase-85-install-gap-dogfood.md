<!-- nana:approved 2026-06-10 -->
# Spec: Phase 85 — Install-Gap Fix + Edge-Screener Dogfood

## Objective

Close the extra_dirs install gap (no install path ships `hooks/session-start.d/` to a root that holds `session-start.sh`; the drift checker is blind to directory contents), then replace edge-screener's hand-patched hook registration with a durable template-sourced install and run a real consuming-project dogfood round there, capturing usage evidence — including a verified-live answer to whether the memory MCP layer is ever touched (feeds the open A5 must-revisit ledger row).

## Context

The kit develops in `templates/.claude` but runs from installed copies (`~/.claude` for the maintainer, `<project>/.claude` for consuming projects). Five "registered+present+but-broken" incidents have come from gaps between those copies. The 5th (2026-06-09): a refresh synced `session-start.sh` to `~/.claude/hooks/` but nothing ships `~/.claude/hooks/session-start.d/` — the directory was empty, `session-start.sh` hard-`source`s three curator scripts from it by name (lines 10-12), so EVERY SessionStart on the machine errored until a live manual repair. `modules.json` declares the directory only under `project_local.extra_dirs`; `install.sh`'s global path copies only `scope==global` hook scripts flat; `scripts/check-install-drift.sh` has zero references to `session-start.d` or `extra_dirs`, so the breakage was invisible to the existing guard.

The consuming project `/Users/jwang/edge-screener` was hand-patched in Phase 79: its `.claude/settings.json` was edited directly (rollback at `.claude/settings.json.bak`); it has NO `.claude/settings.local.json` — but `install.sh --project-local` registers into `settings.local.json`. Claude Code merges both files, so a naive reinstall double-registers every kit hook. Edge-screener's `session-start.d/` is already populated and verified identical to templates; the maintainer's `~/.claude/hooks/session-start.d/` was hand-repaired under incident pressure and is unverified against templates.

Phase 84 deregistered 11 ghost global hook registrations, leaving `~/.claude/settings.json`'s kit hooks exactly equal to the modules.json `scope:global` set (currently 1: context-size-check). That end-state must not regress.

The memory MCP layer's value is an open must-revisit question (ledger row A5): access counts ~0 and edge-screener has never called it — but edge-screener has no `.memory/` directory, and Phase 83 established that historical zeros there were couldnt-fire (missing embeddings), not no-demand. The dogfood round must distinguish the two.

## Scope

### In scope
- `install.sh` — extra_dirs shipped by the install paths that ship hook scripts; copy robustness under `set -euo pipefail`.
- `scripts/check-install-drift.sh` — directory-currency coverage for extra_dirs, with consumer-conditioned presence expectation.
- An inventory of ALL paths that ship hook scripts (install.sh global, install.sh --project-local, py-init, ts-init, nana-init template copy, any maintainer refresh procedure) — each either fixed or filed with rationale.
- `tests/**` — new/updated deterministic tests including seeded negative controls for the drift coverage.
- Edge-screener (out-of-repo, checkpoint-gated): registration migration off the hand-patch, template-sourced reinstall, `.bak` disposition, dogfood round with usage-evidence capture.
- Conditional: if the install-path inventory shows the gap lives in py-init/ts-init/nana-init template-copy logic, those skill files (`templates/.claude/skills/{py-init,ts-init,nana-init}/**`) enter scope for that fix — an inventory-confirmed causal path is fixed, not filed.
- Maintainer `~/.claude` (out-of-repo, checkpoint-gated): reconcile hand-repaired `session-start.d/` copies with templates before any overwriting install run.
- Evidence artifacts under `eval/install-gap/` (or equivalent): inventory, rehearsal log, dogfood usage evidence, A5 memory-layer probe record.

### Out of scope
- A5 disposition itself (deciding the memory layer's fate) — this phase produces the demand evidence; the decision is a later prune-on-value round.
- detect-loop.sh prune call (separate filed candidate; upstream platform defect).
- Consuming-project drift detection generally (Phase-76 deferred item B) — only the extra_dirs/dir-currency slice of the maintainer-root checker is in scope.
- Changing hook scope tags in modules.json or re-registering session-start globally — the fix ships files, never registrations.
- New dogfood features in edge-screener beyond exercising the existing harness on real work.

## Approach

Fix the structural invariant, not the single instance: every install path that ships a hook script must also ship the subdirectories that script consumes, and the drift comparator must treat "consumer present, directory missing/stale" as drift — not as not-installed. Inventory the install paths first; fix where the gap is real; rehearse the full install in a mktemp sandbox (HOME and project both overridden) where a real piped SessionStart event must exit 0 before any live root is touched. Then migrate edge-screener: dedupe kit-owned entries out of `settings.json` in the same change that writes `settings.local.json`, verify single-firing with a real event, dispose of the poisoned `.bak` explicitly, and run the dogfood round on real edge-screener work with a recorded memory-layer liveness probe so a zero counts as demand evidence rather than couldnt-fire.

### Domain Research Questions
1. What does Claude Code's settings merge actually do when the same hook command appears in both `settings.json` and `settings.local.json` — double-fire, dedupe, or precedence? The migration design depends on the verified answer, not the assumed one.
2. Which install path actually performed the 2026-06-09 refresh that shipped `session-start.sh` without its `.d/`? Fixing only install.sh leaves the causal path unfixed if it was a different procedure.
3. What should directory currency mean for files that exist installed but not in templates (orphans) — flag, prune, or ignore? The checker's charter says it never ADDS files; it is silent on REMOVE.

## Constraints (CRITICAL)

- Out-of-repo writes (`~/.claude`, edge-screener) happen only behind a HARD maintainer checkpoint with a timestamped backup and a tested restore, after sandbox rehearsal passes — prevents the Phase-84-class live-state regression and honors the no-live-edits-on-direction-gate-authority precedent.
- The extra_dirs copy must tolerate empty/no-match sources under `set -euo pipefail` — prevents the installer itself aborting mid-sequence and reproducing incident 5 (hooks copied, registrations unwritten, or `.d/` half-populated).
- The fix ships FILES only where the consumer script is already present; it never adds or changes registrations — prevents recreating the ghost registrations Phase 84 just removed. Post-fix, `~/.claude/settings.json` kit hook commands must still equal exactly the modules.json `scope:global` set.
- Drift-checker directory coverage must condition presence-expectation on the consumer: `session-start.sh` present ⇒ `session-start.d/` and each templates file in it must exist and match — prevents the absent=skipped semantic from masking the exact 2026-06-09 failure mode.
- Checker and matrix output counts as evidence only after seeded negative controls pass (one sandbox root with the directory deleted, one with a single stale file → both must report drift) — prevents a clean-on-seed instrument-dead guard (QA-sweep controls-first standard).
- Edge-screener migration must end with each kit hook registered exactly once across the UNION of `settings.json` + `settings.local.json`, where hook identity = script BASENAME (command forms are mixed: `bash ~/.claude/hooks/X.sh`, absolute, `${CLAUDE_PROJECT_DIR}` — naive string comparison sees two forms as distinct entries), verified by counting firings of one real piped event (1 row, not 2) — prevents double-fire contaminating both enforcement and the dogfood usage evidence.
- Before the first overwriting run on the maintainer root, diff the hand-repaired `~/.claude/hooks/session-start.d/` against templates and reconcile any divergence explicitly — prevents silently reverting an under-pressure hotfix.
- A memory-layer zero in the dogfood round counts as demand evidence ONLY with a recorded liveness probe (the actual server-start command + its exit code + a DB row count) filed alongside — prevents feeding a couldnt-fire false negative into ledger row A5 in `.dev-wiki/assumption-ledger.md` (the Phase-83 trap).
- The dogfood round has a minimum bar: at least 2 real-work sessions in edge-screener, with at least one observation row each for SessionStart, a PreToolUse decision (allow or block), and a Stop event — prevents a single trivial session satisfying the evidence criterion. Evidence schema pinned up front: one row per observation with hook, event, timestamp, and a helped/neutral/noise judgment.
- `--project-local` runs must assert the target project root before writing (it is CWD-relative) — prevents silently installing edge-screener's hooks into whatever directory the session happens to be in (including nana-dev-kit itself).
- Frozen surfaces stay frozen: `eval/` apparatus and the assumption ledger are read-only except for this phase's own new artifacts; supersession notes, never history rewrites.

## Success Vision

A future refresh of any hook script cannot silently strand its companion directory: the installer ships directories wherever their consumer lands, the drift checker turns the 2026-06-09 state into a loud red cell, and both claims are backed by seeded controls rather than presence checks. Edge-screener runs current, template-sourced hooks registered exactly once, with the hand-patch era closed out cleanly (no poisoned rollback left behind). The dogfood round produces honest consuming-project evidence: what fired, what helped, what was never touched — with the memory-layer answer carrying a liveness probe so the A5 revisit can trust a zero. The install-path inventory leaves no "which path caused incident 5" mystery: each path is either fixed or has a filed, reasoned exemption.

## Exit Criteria (machine-checkable)

- [ ] `make test` — full suite green, including a new drift directory-currency test and an install extra_dirs test.
- [ ] `bash tests/test_install_drift_dircurrency.sh` (or the equivalent named test) — seeded controls: sandbox with `session-start.d/` deleted reports drift; sandbox with one stale curator file reports drift; a third control covering the chosen orphan semantics (installed-but-not-in-templates file: flag/prune/ignore per DRQ 3 — or an explicit filed deferral with rationale in the inventory artifact); synced sandbox reports 0.
- [ ] Sandbox rehearsal log shows a full install run into mktemp HOME/project followed by a piped SessionStart event from a pinned real-capture fixture (provenance noted — hand-written fixtures are circularity-prone per the Phase-84 finding) exiting 0 with all three curators sourced (`eval/install-gap/rehearsal.log` or equivalent, command-reproducible).
- [ ] Committed assertion script passes post-install: the basename-normalized multiset of kit-owned hook commands in `~/.claude/settings.json` equals exactly the modules.json `scope:global` script set.
- [ ] Edge-screener post-migration assertion script passes: each kit hook (identity = script basename) appears exactly once across the union of `.claude/settings.json` + `.claude/settings.local.json`, and one real piped event produces exactly one firing-log row.
- [ ] `scripts/check-install-drift.sh ~/.claude; echo $?` → drift 0 on the live maintainer root after the checkpoint-gated install.
- [ ] `make eval` — denominator unchanged (52) with any flip explained in a committed diff note.
- [ ] Dogfood evidence artifact (`eval/install-gap/dogfood-evidence.md` or equivalent) contains: a probe record with the server-start command, its exit code, and a DB row count (grep for the exit-code line, not the section header); and ≥1 observation row each for SessionStart, a PreToolUse decision, and Stop, across ≥2 sessions, in the pinned schema (hook | event | timestamp | helped/neutral/noise).
- [ ] Install-path inventory artifact exists with every hook-shipping path's row matching `^\| .+ \| (fixed|exempt: .+) \|` — empty or unmarked rows fail.

## Checkpoints

- After the install-path inventory + sandbox rehearsal pass, BEFORE any write to `~/.claude`: HARD maintainer checkpoint presenting the rehearsal log, the planned live changes, backup + restore plan, AND a live positive control (a sandbox COPY of the live root with one seeded-stale file → the new checker code reports drift on it) — the sandbox test alone doesn't prove the new code path against the real root shape. Wait for approval.
- BEFORE any write to edge-screener (migration + reinstall): second HARD checkpoint with the dedupe plan, union-uniqueness assertion, `.bak` disposition, and rollback. Wait for approval.
- If the settings-merge research (DRQ 1) contradicts the double-fire assumption: STOP and re-present the migration design — the dedupe step may be unnecessary or differently shaped.
- If the maintainer-root `session-start.d/` diff shows divergence from templates: STOP and present the diff before any overwrite.
- If the memory-layer liveness probe fails in edge-screener: report it, file couldnt-fire, and continue the dogfood round — do not silently record a zero.

## Assumptions

- `session-start.d` is the only extra_dirs entry today. If false (more added): the fix must already be list-driven from `modules.json`, not hardcoded — verify by adding a synthetic second dir in the sandbox test.
- Edge-screener has real work available to exercise in a dogfood round. If false: the install verification half still completes; the usage-evidence half downgrades to a scripted harness-exercise session, recorded as such (weaker A5 evidence, stated plainly).
- The maintainer's hand-repaired `~/.claude/hooks/session-start.d/` matches templates. If false: reconcile explicitly at the checkpoint (diff presented; hotfix either upstreamed into templates or overwritten with rationale).
- The memory MCP server can start inside edge-screener sessions. If false: record couldnt-fire with the probe output; A5 evidence is "blocked", never a silent zero.
- Claude Code merges `settings.json` + `settings.local.json` such that duplicate hook entries double-fire. If false (verified during DRQ 1): adjust the migration to the verified semantic and update the union-uniqueness assertion accordingly.
- Edge-screener's `.claude/settings.json.bak` is the only rollback artifact from the hand-patch era. If false (others found): inventory and disposition all of them at the edge-screener checkpoint.
