# Spec: Wire the Lifecycle (Phase 15)

## Objective

Make nana-dev-kit a complete one-command install of all three subsystems (Python scaffolding, dev-wiki lifecycle, knowledge-wiki pipeline) with modular opt-out, and add compaction resilience via PreCompact hook and explicit memory guidance in session-start.

## Context

Phase 14 shipped adversarial thinking (T0 + spec Step 2.5, 67 tests, v0.3.0). The kit currently installs py-init, spec, 3 rules, and memory_server. Two other skill sets (dev-wiki lifecycle: 6 dirs/47 files; knowledge-wiki: 11 dirs/64 files) exist at `~/.claude/skills/` but aren't distributed by the kit. Users who install nana-dev-kit get references to `/dev-init` and `/wiki-init` that don't exist. A 3-agent architectural review confirmed monorepo with modular install flags as the correct approach. 111 total skill files need importing.

## Scope

### In scope

- Import dev-wiki skill directories (dev-wiki/, dev-check/, dev-debrief/, dev-init/, dev-plan/, dev-scan/) into `templates/.claude/skills/`
- Import knowledge-wiki skill directories (knowledge-wiki/, wiki-absorb/, wiki-add/, wiki-bootstrap/, wiki-consolidate/, wiki-health/, wiki-index/, wiki-init/, wiki-query/, wiki-reorg/, wiki-registry/) into `templates/.claude/skills/`
- Refactor install.sh to use directory-based iteration (not per-file cp)
- Add install flags: `--all` (default), `--core-only` (identity + memory only), `--no-python` (skip py-init)
- Add `--dry-run` flag that prints actions without copying
- Add PreCompact hook (`templates/.claude/hooks/pre-compact.sh`)
- Enhance session-start.sh to output memory_search topic guidance
- Update test suite to cover new skills and flags
- Module group definitions with dependency validation (dev-* requires dev-wiki base; wiki-* requires knowledge-wiki base)
- Generate MANIFEST file for import reproducibility

### Out of scope

- Modifying skill SKILL.md content (import as-is from ~/.claude/skills/)
- Language-agnostic refactoring of dev-scan's Python-specific files (Phase 18)
- Memory ↔ dev-wiki bridge / auto-store decisions (Phase 16)
- Enforcement hooks (spec-enforcement, stop-hook exit criteria) (Phase 16)
- Per-skill versioning or changelogs
- Upgrading the memory_server or changing its interface

## Approach

**Import strategy:** Copy from `~/.claude/skills/{dev-*,wiki-*,knowledge-wiki}/` into `templates/.claude/skills/`. These are the canonical, tested versions currently in use. After import, the monorepo becomes the canonical source.

**Installer refactor:** Replace per-file cp commands with a module-group pattern:
```
MODULES="core python dev-wiki knowledge-wiki"
# Each module defines: source dirs, target dirs, dependencies
# --core-only sets MODULES="core"
# --no-python removes "python" from MODULES
```

**Module dependency graph:** `core` (no deps) → `python` (requires core) → `dev-wiki` (requires core) → `knowledge-wiki` (requires core). Install with missing prerequisite must exit non-zero with named missing module.

**PreCompact hook:** Pure bash. Reads `_CURRENT_STATE.md`, `tasks.md`, `active-phase.md`. Outputs a structured summary for context injection. Does NOT call MCP tools (shell limitation). Ensures the agent has enough post-compaction context to resume.

**Session-start enhancement:** After reading dev-wiki state, extract the active task topic and output: `[memory] Suggested memory_search query: "<topic>"`. The agent (not the hook) executes the MCP call.

**Import manifest:** Generate `templates/.claude/skills/MANIFEST` with sorted file listing + checksums at import time. Tests verify manifest matches tree.

## Constraints (CRITICAL)

- install.sh must remain idempotent — running twice produces identical results. Prevents: incremental state corruption on re-install.
- Module dependency graph: `core` (no deps) → `python` (requires core) → `dev-wiki` (requires core) → `knowledge-wiki` (requires core). Install with missing prerequisite must exit non-zero with named missing module. Prevents: broken installs from invalid flag combinations.
- PreCompact hook must be pure POSIX shell + git — no Python, no MCP calls, no language-specific deps. Prevents: hook failure in non-Python projects.
- No modification to imported SKILL.md content — copy verbatim. Prevents: divergence from tested behavior; content changes belong in dedicated phases.
- install.sh `--all` completes in <10s. Prevents: user-perceived performance degradation from 111-file copy. If violated: profile and optimize bottleneck (likely venv/pip, not file copy).
- Existing v0.3.0 installations must upgrade cleanly — new dirs appear, no orphan cleanup needed (we're adding, not moving). Prevents: breaking existing users.

## Deliverables

1. `templates/.claude/skills/dev-wiki/` (6 subdirectories, ~47 files) — imported verbatim
2. `templates/.claude/skills/knowledge-wiki/` + 10 wiki-* subdirectories (~64 files) — imported verbatim
3. Refactored `install.sh` — module-group iteration, `--all`/`--core-only`/`--no-python`/`--dry-run` flags
4. `templates/.claude/hooks/pre-compact.sh` — compaction state summary hook
5. Updated `templates/.claude/hooks/session-start.sh` — memory_search topic guidance
6. Updated `tests/test_install.sh` — flag combinations, module dependency validation, new skill dirs
7. Updated `tests/test_templates.sh` — presence checks for imported skills
8. `templates/.claude/skills/MANIFEST` — sorted file listing with checksums, generated at import time

## Exit Criteria (machine-checkable)

- [ ] `test -d templates/.claude/skills/dev-plan && test -f templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `test -d templates/.claude/skills/wiki-query && test -f templates/.claude/skills/wiki-query/SKILL.md`
- [ ] `bash install.sh --dry-run 2>&1 | grep -q 'dev-plan'`
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh --core-only && test ! -d "$THOME/.claude/skills/dev-plan" && test ! -d "$THOME/.claude/skills/wiki-query" && test -f "$THOME/.claude/rules/nana-soul.md" && rm -rf "$THOME"`
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh --no-python && test ! -d "$THOME/.claude/skills/py-init" && test -d "$THOME/.claude/skills/dev-plan" && rm -rf "$THOME"`
- [ ] `test -f templates/.claude/skills/MANIFEST && wc -l < templates/.claude/skills/MANIFEST | grep -q '[0-9]'`
- [ ] `test -f templates/.claude/hooks/pre-compact.sh && bash -n templates/.claude/hooks/pre-compact.sh`
- [ ] `grep -q 'memory_search\|memory.*query' templates/.claude/hooks/session-start.sh`
- [ ] `make test`
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -d "$THOME/.claude/skills/dev-plan" && test -d "$THOME/.claude/skills/wiki-query" && rm -rf "$THOME"`

## Checkpoints

- After skill import (deliverables 1-2): verify file count matches source, run `bash -n` on all .sh files, report before proceeding to install.sh refactor
- After install.sh refactor (deliverable 3): run existing tests to catch regressions before adding new tests
- After PreCompact hook (deliverable 4): run against a fixture `.dev-wiki/` directory and verify output contains phase name and task status
- If total test execution time exceeds 30s: simplify test approach (spot-check representative skills, not all 111 files)

## Assumptions

- `~/.claude/skills/{dev-*,wiki-*,knowledge-wiki}/` on this machine represent the canonical, current versions of these skills. If false: identify the authoritative source repo and import from there instead.
- The 17 skill directory names are stable and won't conflict with future Claude Code built-in skill names. If false: add a `nana-` prefix namespace.
- PreCompact hooks receive the project working directory as CWD (same as other hooks). If false: use absolute paths or detect CWD from git.
- install.sh's `cp -r` of 111 files completes in <10s on typical hardware. If false: use rsync or tar for bulk copy.
