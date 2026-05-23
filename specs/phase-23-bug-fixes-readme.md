# Spec: Phase 23 — Bug Fixes + README Rewrite

## Objective

Fix two confirmed bugs (orphaned pre-compact.sh hook registration, memory-harvest.md MCP API mismatches) and rewrite the README to reflect v0.4.0 capabilities.

## Context

An external review of v0.4.0 found that pre-compact.sh exists at `templates/.claude/hooks/pre-compact.sh` but is never registered — not in `templates/.claude/settings.json` (per-project) and not in `install.sh` (global). Gap 1.5 was marked CLOSED in Phase 15, but the hook never fires. Separately, `memory-harvest.md` uses invalid MCP categories (`lesson`, `constraint`), wrong API shape (nested object instead of flat params), and wrong param name (`confidence` instead of `trust`). The correct pattern exists in `memory-bridge.md` (Phase 19). The README describes v0.3.0 and mentions only 4 skills — the tool now has 22 skills, enforcement hooks, eval harness, modular installer, and memory-wiki bridge. 133 tests, 38/38 eval at v0.4.0.

## Scope

### In scope
- Register pre-compact.sh in `templates/.claude/settings.json` under `PreCompact` hook type (nested format matching existing entries)
- Add pre-compact.sh to install.sh dev-wiki module group (global copy to `~/.claude/hooks/` + PreCompact JSON merge using existing Python merge format)
- Verify pre-compact.sh still works against current file formats
- Rewrite `memory-harvest.md` to use correct MCP API: `category="custom"`, `tags=["harvest-*"]`, flat params, `trust` not `confidence`
- Rewrite README.md to reflect v0.4.0 (~90-100 lines)
- Update tests for new hook registration and README structure

### Out of scope
- Adding enforcement hooks to per-project settings.json (documented design choice — `global-hooks-project-opt-in`)
- dev-plan SKILL.md line budget (companion-file any additions, separate concern)
- PostCommit hook (Gap 1.6 — separate phase)
- Language-agnostic core (Gap 4.1 — separate phase)
- Fixing test_sync_rules.sh unwritable tests (not reproducible locally)
- New eval scenarios (hook-pre-compact-active-phase already exists)

## Approach

**Pre-compact fix:** Verify `PreCompact` is a valid Claude Code hook event name first (gated task). Add `"PreCompact"` entry to `templates/.claude/settings.json` using the same nested format as existing entries (`{hooks: [{type: "command", command: "..."}]}`). Add pre-compact.sh to the dev-wiki module group in install.sh — global copy to `~/.claude/hooks/` and PreCompact JSON merge using the existing Python merge pattern. Run pre-compact.sh against a fixture to verify output.

**memory-harvest.md fix:** Rewrite the Output Format section to match memory-bridge.md conventions: `category="custom"`, flat params with `trust` (not `confidence`), `tags=["harvest-correction"]` / `tags=["harvest-preference"]` / `tags=["harvest-lesson"]`. Check eval/ and tests/ for references to old API shapes.

**README rewrite:** Expand from ~58 to ~90-100 lines. Supersede the prior ~58-line target — the tool is 4x larger. Structure: Quick Start, What You Get (7 layers table), Skill Reference (grouped by module: Python quality, lifecycle, knowledge wiki, identity), Memory & Wiki, Eval, Per-Project Sync, Upgrading. Every claim maps to a file that install.sh distributes.

## Constraints (CRITICAL)

- **Pre-compact hook must be in dev-wiki module, not core:** Users who run `--core-only` should NOT get PreCompact (it reads .dev-wiki/ files). Prevents: hook errors in projects without dev-wiki.
- **JSON merge idempotency:** Running install.sh twice must not duplicate PreCompact entries in settings.json. Prevents: growing hook arrays on every re-install.
- **memory-harvest.md must match memory-bridge.md API pattern exactly:** Same `memory_store` param names, same `category="custom"` convention, same flat call structure. Prevents: API drift between two files calling the same MCP tool.
- **README claims must map to installed artifacts:** Each capability claim (skills, enforcement hooks, eval) must correspond to files that install.sh actually distributes. Prevents: documenting features that don't reach the user.
- **No eval/test regression:** `make test` and `make eval` must pass after all changes. Prevents: breaking existing coverage while fixing bugs.

## Deliverables

1. Modified `templates/.claude/settings.json` — PreCompact hook registration (nested format)
2. Modified `install.sh` — pre-compact.sh in dev-wiki module copy + PreCompact JSON merge
3. Rewritten `templates/.claude/skills/dev-debrief/memory-harvest.md` — correct MCP API
4. Rewritten `README.md` — v0.4.0 capabilities (~90-100 lines)
5. Updated `tests/test_install.sh` — PreCompact registration assertions
6. Updated `tests/test_templates.sh` — README structure + memory-harvest API assertions

## Exit Criteria (machine-checkable)

- [ ] `jq -e '.hooks.PreCompact' templates/.claude/settings.json`
- [ ] `grep -q 'pre-compact' install.sh`
- [ ] `! grep -q 'category.*lesson\|category.*constraint\|confidence' templates/.claude/skills/dev-debrief/memory-harvest.md`
- [ ] `grep -q 'category.*custom' templates/.claude/skills/dev-debrief/memory-harvest.md && grep -q 'trust' templates/.claude/skills/dev-debrief/memory-harvest.md`
- [ ] `grep -qi 'enforcement' README.md && grep -qi 'eval' README.md && grep -qi 'dev-plan' README.md && grep -qi 'dev-init' README.md`
- [ ] `[ $(wc -l < README.md) -ge 70 ] && [ $(wc -l < README.md) -le 120 ]`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After verifying PreCompact event name: if not valid, STOP and determine correct name before proceeding
- After pre-compact.sh registration + install.sh change: run install.sh --dry-run to verify PreCompact appears, then run pre-compact.sh against a fixture to verify output format
- After memory-harvest.md rewrite: verify no eval/test references to old API shapes
- After README draft: verify every capability claim maps to an installed file before finalizing

## Assumptions

- `PreCompact` is the correct hook event name in Claude Code settings.json. If false: check Claude Code documentation for the exact event name and adjust.
- pre-compact.sh still produces valid output against current _CURRENT_STATE.md and tasks.md formats. If false: fix the script first, then register it.
- No eval scenarios or tests reference memory-harvest.md API shapes. If false: update those references as part of the fix.
- The prior README ~58-line target (from `readme-concise-format` working-knowledge) is superseded by this spec's 90-100 line budget. If false: compress further, but the tool's scope has grown 4x.
