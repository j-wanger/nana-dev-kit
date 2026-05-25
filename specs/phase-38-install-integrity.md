<!-- nana:approved 2026-05-25 -->
# Spec: Phase 38 — Install Integrity & Functional Verification

## Objective
Fix known install gaps (5 missing skills, wrong hook matchers, broken JSON field parsing) and add post-install functional verification so structural-only tests never hide a broken artifact again.

## Context
Phase 37 completed the 2-gate ceremony model. A post-phase audit discovered the MCP memory server had been non-functional since Phase 4 (33 phases) due to a bad CWD path in settings.json. The root cause: tests checked "does settings.json contain the key" but never "can the server actually start." The CWD bug is now fixed (commit 76e7303), but the audit revealed 3 additional broken artifacts and the systemic gap of structural-only testing.

Known broken artifacts:
1. **5 skills never installed:** `nana`, `memory-consolidate`, `py-lint`, `py-review`, `py-test` exist in templates/ but absent from install.sh skill lists
2. **MultiEdit matcher gap:** template settings.json uses `Write|Edit|MultiEdit` but install.sh registers `Write|Edit` — hooks don't fire on MultiEdit
3. **dev-wiki-scope-check.sh wrong field:** uses `.tool_input.file_path` but PreToolUse contract is `.input.file_path` — hook is silently no-op

Additional finding: PostToolUse hooks have inconsistent field paths (3 use `.input`, 2 use `.tool_input`). Both patterns appear in working hooks and passing eval scenarios. The eval schema was derived from Bash-matcher hooks only. This inconsistency is documented but NOT fixed in this phase — requires live verification of Claude Code's actual PostToolUse stdin format.

## Scope
### In scope
- Add 5 missing skill directories to install.sh: `nana`, `memory-consolidate` → core module; `py-lint`, `py-review`, `py-test` → python module
- Fix MultiEdit matcher in install.sh for ALL 7 affected hook registrations:
  - Global PreToolUse (3): enforce-spec, enforce-memory, dev-wiki-scope-check
  - Global PostToolUse (1): stale-queue
  - Project-local PostToolUse (3): audit-log, auto-ruff-format, scan-secrets
- Fix dev-wiki-scope-check.sh: `.tool_input.file_path` → `.input.file_path`
- Add post-install functional verification tests to test_install.sh
- Regenerate MANIFEST with the 5 newly-installed skills
- Document PostToolUse field path inconsistency as a known issue in _ARCHITECTURE.md

### Out of scope
- Adding new hooks or skills
- Fixing PostToolUse field path inconsistency (requires live contract verification)
- Full MCP JSON-RPC smoke test (import check from commit 76e7303 is sufficient)
- Refactoring install.sh architecture
- Changing hook behavior beyond the scope-check field path fix

## Approach
Fix bugs first (skills, matchers, field path), then add functional tests that would have caught each. Tests use isolated $HOME dirs (existing pattern) with behavioral checks: pipe fixture JSON through hooks, verify MCP server import from configured CWD, verify skill companion files present after install.

## Constraints (CRITICAL)
- MultiEdit must be added to ALL 7 hook registrations (3 global PreToolUse + 1 global PostToolUse + 3 project-local PostToolUse). Prevents: divergence where some hooks fire on MultiEdit and others don't.
- Skill module assignment: `nana` and `memory-consolidate` to core; `py-lint`, `py-review`, `py-test` to python. `--core-only` must NOT install python skills. Prevents: over-install breaking module isolation.
- Functional tests must run in `HOME=$(mktemp -d)` isolation. Prevents: tests depending on developer's existing ~/.claude/ state.
- MANIFEST must be regenerated after adding skills. Prevents: `/nana` skill showing stale inventory.
- Eval scenarios for dev-wiki-scope-check must be updated if existing scenarios use the old field path. Prevents: eval regression.
- No new hard Python dependency in `make test`. Prevents: breaking CI for bash-only environments.
- Do NOT change PostToolUse hooks' field paths — document the inconsistency only. Prevents: breaking working hooks without live contract verification.

## Deliverables
1. `install.sh` — updated skill lists (5 additions), updated matchers (7 registrations → MultiEdit)
2. `templates/.claude/hooks/dev-wiki-scope-check.sh` — field path fix
3. `templates/.claude/skills/MANIFEST` — regenerated
4. `tests/test_install.sh` — functional verification tests (~15-20 new assertions)
5. `eval/corpus/` — updated scenarios if needed for field path change
6. `.dev-wiki/_ARCHITECTURE.md` — PostToolUse field path inconsistency documented in Known Issues

## Exit Criteria (machine-checkable)
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -d "$THOME/.claude/skills/nana" && test -d "$THOME/.claude/skills/py-lint" && test -d "$THOME/.claude/skills/py-review" && test -d "$THOME/.claude/skills/py-test" && test -d "$THOME/.claude/skills/memory-consolidate" && rm -rf "$THOME"`
- [ ] `test $(grep -c "Edit|Write'" install.sh) -eq 0` — no Write|Edit-only matchers remain
- [ ] `grep -q '.input.file_path' templates/.claude/hooks/dev-wiki-scope-check.sh && ! grep -q '.tool_input.file_path' templates/.claude/hooks/dev-wiki-scope-check.sh`
- [ ] `make test` — all tests pass
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'` — eval 100%
- [ ] `grep -q 'nana' templates/.claude/skills/MANIFEST` — MANIFEST includes new skills
- [ ] `grep -qi 'PostToolUse.*field.*inconsisten\|field.*path.*PostToolUse' .dev-wiki/_ARCHITECTURE.md` — inconsistency documented

## Checkpoints
- After fixing all 3 bugs (before writing tests): run make test + make eval to verify no regressions
- After adding functional tests: run full suite, verify new tests catch the bugs they're designed for

## Assumptions
- PreToolUse stdin uses `.input.file_path` for Write/Edit and `.input.command` for Bash. Evidence: enforce-spec.sh, block-dangerous-bash.sh, eval schema, 3/4 PreToolUse hooks consistent. If false: check Claude Code docs.
- The 5 missing skills have no dependencies beyond their companion .md files. If false: add dependency validation per skill.
- MultiEdit fires PreToolUse/PostToolUse hooks with the same matcher syntax as Write|Edit. Evidence: scan-secrets.sh and auto-ruff-format.sh comments already reference MultiEdit. If false: adding to matchers is harmless (no-op).
