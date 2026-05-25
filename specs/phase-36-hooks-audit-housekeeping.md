<!-- nana:approved -->
# Spec: Phase 36 — Hooks Audit & Housekeeping

## Objective

Diagnose and fix the hook errors Claude Code is surfacing in this project, reconcile kit-shipped (`templates/.claude/hooks/`) and globally-installed (`~/.claude/hooks/`) hook sets into an explicit per-hook disposition, and bundle that with README ts-init coverage and an upstream nanaclaw sanitizer PR. Ship as housekeeping — no architectural changes, no L tasks.

## Context

Phase 35 (ts-init implementation) is complete: 224 tests, 47/47 eval, ~300/300 instruction budget (full), v0.5.0 tagged. The kit-shipped hook set (12 files in `templates/.claude/hooks/`) has drifted from the globally-installed set (11 files in `~/.claude/hooks/`): 6 hooks are global-only (`context-size-check.sh`, `dev-wiki-post-commit.sh`, `dev-wiki-scope-check.sh`, `post-compact.sh`, `session-stop.sh`, `stale-queue.sh`); kit names sometimes differ from global names (e.g., kit ships `post-commit.sh`, global has `dev-wiki-post-commit.sh`). The user reported Claude Code throwing errors on some hooks but did not pin specific files or error text. A scratch prefix-refactor inventory at `.dev-wiki/.hook-prefix-inventory.md` is half-finished and explicitly marked "do not commit". README at 110 lines has zero TS coverage despite ts-init shipping in Phase 35; it also still claims 201 tests. `patches/nanaclaw-sanitize-fts.patch` is ready to submit upstream to `https://github.com/j-wanger/nanaclaw` (Jake's own repo). No version bump planned unless something substantial ships.

## Scope

### In scope
- Hook error diagnosis: capture actual Claude Code error surface (debug log, `.dev-wiki/enforcement.log`, or session JSONL grep) into a short evidence file
- Per-hook disposition for the 6 global-only hooks: explicit (a) backport to kit, (b) delete from global, or (c) tolerate as user-local
- Static lint pass on every kit hook: `bash -n` syntax, `set -euo pipefail` presence, jq fail-open guard, stdin contract vs Claude Code hook spec, BSD/GNU portability
- Targeted fixes for hooks flagged by diagnosis + lint (each fix pinned to a quoted error string or specific lint violation)
- README ts-init coverage: Quick Start `/ts-init`, `--no-typescript` row in installer flag table, "TypeScript Quality" skills section, Node requirement bumped (version derived from ts-init's actual engines/CI matrix, not guessed), test count refreshed
- README count refresh propagated across all files (no stale "201" claim left in repo)
- Nanaclaw upstream PR: fork → branch from upstream `main` → apply patch → push → open PR, with `git log upstream/main..HEAD` showing exactly 1 commit and zero `nana-dev-kit/` paths
- TS polish: spot-check `templates/.claude/skills/ts-init/{SKILL.md,scanner.md,transform.md}`, `templates/AGENTS-ts.md`, `templates/.github/workflows/ci-ts.yml`. Issue counts as "surfaced" if it matches one of: (a) broken wikilink/cross-reference (file path or `[[slug]]` target missing), (b) stale tool version reference (e.g., Node/pnpm/Biome version that doesn't match `ci-ts.yml` matrix), (c) typo or grammar error visible on read, (d) reference to a file/skill that doesn't exist. Anything outside this list is out of scope for this phase
- `.dev-wiki/.hook-prefix-inventory.md`: either delete or add to `.gitignore` before any commit
- Regenerate `templates/.claude/skills/MANIFEST` if any skill file under it changes

### Out of scope
- Hook architecture changes (still bash + jq + stdin JSON)
- New hooks (only fixing/reconciling existing ones)
- New ts-init features
- Version bump (defer to debrief decision)
- Language-agnostic core (Gap 4.1) — deferred to a later phase
- Memory benchmark expansion
- Adaptive fusion
- Nanaclaw bidirectional sync (only push, not pull)

## Approach

Discovery-driven, then surgical. Phase 1: collect evidence (hook errors + lint inventory + diff between kit/global). Phase 2: classify the 6 global-only hooks per a single decision matrix. Phase 3: apply targeted fixes — each fix pinned to a captured error string or specific lint finding. Phase 4: README ts-init pass and stale-count sweep. Phase 5: nanaclaw upstream PR. Phase 6: TS polish spot-check. Hook changes are tested against a sacrificial tmpdir spec, not the live phase-36 spec, to avoid locking out the author. The README test-count refresh is set LAST in the phase so any test additions during the phase are reflected.

## Constraints (CRITICAL)

- **No hook fix without quoted evidence** — every hook change must be accompanied in its commit message by a quoted error string (from `claude --debug`, `.dev-wiki/enforcement.log`, session JSONL, or specific lint failure). Guard: `git log --grep='^Fix.*hook'` should show error quotes; review rejects fixes lacking them.
- **No global/kit divergence at end of phase** — for each of the 6 global-only hooks, the phase explicitly states (a) backport, (b) delete, or (c) tolerate-as-local. Guard: a `.dev-wiki/articles/decisions/hook-reconciliation.md` decision article lists all 6 with disposition.
- **No silent settings.json breakage on hook rename** — any kit hook rename must update every `settings.json` reference in the same commit. Guard: `grep -rn '<old-basename>' templates/ install.sh` returns 0 after rename.
- **Nanaclaw PR contains exactly one commit, no kit paths** — Guard: `git log upstream/main..HEAD --name-only` shows 1 commit, all paths under `memory_server/` (not `patches/`, not `nana-dev-kit/`).
- **No stale "201 tests" claim survives** — Guard: `grep -rn '201' --include='*.md' --include='*.sh' Makefile* README*` returns zero test-count matches after the edit.
- **`.hook-prefix-inventory.md` scratch never commits** — Guard: either deleted or in `.gitignore`; pre-commit shows it untracked or absent.
- **Hook changes are tested in a tmpdir, not against the live phase-36 spec** — Guard: test fixtures use `mktemp -d` and write throwaway specs; live `.claude/enforce` marker is not touched mid-phase.
- **Node version claim is derived, not guessed** — Guard: README Node version cited matches `templates/.github/workflows/ci-ts.yml` matrix and/or any `engines` field in ts-init outputs; commit message states the source.

## Deliverables

1. `.dev-wiki/articles/decisions/hook-reconciliation.md` — per-hook disposition for all 6 global-only hooks
2. `.dev-wiki/articles/decisions/hook-error-evidence.md` — captured error strings keyed to fixes (or "no errors found, audit was lint-only")
3. Updated kit hooks in `templates/.claude/hooks/` (only files actually changed)
4. Updated `templates/.claude/hooks/settings.json` references and `install.sh` JSON merge if any hook renamed
5. Updated `README.md` with ts-init coverage and refreshed test count
6. Stale-count refresh across other files (Makefile, install.sh --status, etc.)
7. Nanaclaw PR submitted upstream — URL recorded in `.dev-wiki/articles/decisions/nanaclaw-upstream-pr.md`
8. TS polish fixes (only files actually surfacing issues)
9. `.dev-wiki/.hook-prefix-inventory.md` either deleted or added to `.gitignore`
10. Regenerated `templates/.claude/skills/MANIFEST` if any skill file touched

## Exit Criteria (machine-checkable)

- [ ] `for h in context-size-check dev-wiki-post-commit dev-wiki-scope-check post-compact session-stop stale-queue; do grep -qE "$h.*(backport|delete|tolerate)" .dev-wiki/articles/decisions/hook-reconciliation.md || { echo "missing disposition for $h"; exit 1; }; done`
- [ ] `test -f .dev-wiki/articles/decisions/hook-error-evidence.md && [ $(wc -l < .dev-wiki/articles/decisions/hook-error-evidence.md) -ge 5 ]` (either quoted errors per hook, or "no errors found" branch must list what was checked and where null result came from)
- [ ] `for f in templates/.claude/hooks/*.sh; do bash -n "$f" || exit 1; done`
- [ ] `for f in templates/.claude/hooks/*.sh; do grep -q 'set -euo pipefail' "$f" || { echo "missing safety in $f"; exit 1; }; done`
- [ ] `grep -q '/ts-init' README.md && grep -q 'no-typescript' README.md && grep -q 'TypeScript' README.md`
- [ ] `! grep -rn '\b201\b' README.md Makefile install.sh | grep -iE 'test|scenario'` (no stale "201 tests")
- [ ] `! test -f .dev-wiki/.hook-prefix-inventory.md || grep -q '.hook-prefix-inventory.md' .gitignore`
- [ ] `test -f .dev-wiki/articles/decisions/nanaclaw-upstream-pr.md && grep -qE 'https://github.com/.+/pull/[0-9]+|skipped:' .dev-wiki/articles/decisions/nanaclaw-upstream-pr.md`
- [ ] `make test` (224+ tests still passing)
- [ ] `make eval` (47/47 still passing)
- [ ] `bash install.sh --dry-run >/dev/null` (installer still parses)
- [ ] No skill file changes without `templates/.claude/skills/MANIFEST` regenerated: `bash -c 'cd templates/.claude/skills && find . -type f \( -name "*.md" -o -name "*.sh" \) ! -name MANIFEST -exec md5sum {} \; | sort | diff - <(grep -E "^[a-f0-9]{32}" MANIFEST | sort) >/dev/null'` — informational only

## Checkpoints

- **After hook diagnosis (Workstream A Task 1):** report the captured evidence + per-hook disposition matrix → wait for user confirmation before any hook code changes
- **After hook reconciliation decisions:** report the 6-hook disposition (backport / delete / tolerate) → wait for user approval before executing
- **After nanaclaw PR is opened:** report the PR URL → wait for user confirmation, do NOT close or modify the PR autonomously
- **If hook lint surfaces >5 issues per hook:** STOP, escalate — the audit is bigger than housekeeping
- **If a hook fix breaks `make test` or `make eval`:** STOP, do not commit, ask
- **If the nanaclaw patch no longer applies cleanly to upstream HEAD:** STOP, do not force-apply, ask

## Assumptions

- **Hook errors are reproducible** — they should appear in `claude --debug` output, `.dev-wiki/enforcement.log`, or recent session JSONL files. If false: ask the user to trigger one and copy the exact error string before proceeding with hook fixes.
- **Upstream nanaclaw `main` exists and the maintainer accepts PRs** — Jake owns the repo. If false: skip the PR, document in `nanaclaw-upstream-pr.md` as `skipped: <reason>` and the exit criterion still passes via the `skipped:` regex branch.
- **Existing kit hooks already match Claude Code's current hook stdin/exit-code contract for the events they're registered to** — the `[nana:<name>]` prefix work was done in earlier phases. If false: contract drift is the root cause and surfaces in lint Task 2.
- **`jq` is available locally** — established working-knowledge pattern is fail-open if missing. If false: hooks behave correctly per design (allow), and Claude Code "errors" may actually be expected fail-open warnings — the audit must distinguish "buggy hook" from "correctly fail-open hook user expected to block".
- **224 test count is current at phase start** — verify with `make test 2>&1 | grep -c PASS` before refreshing the README number. If false: use the actual current number.
- **ts-init's required Node version is derivable from `templates/.github/workflows/ci-ts.yml`** — if no version is pinned there or in ts-init outputs, ask user before committing a number to README.
