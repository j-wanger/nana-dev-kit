<!-- nana:approved 2026-05-23 -->
# Spec: Phase 30 — Data-Driven Report Generators

## Objective

Update generate-report.py (298 lines) and generate-workflow.py (738 lines) to read architecture data from sources of truth instead of hardcoded strings, add a report staleness regression test, decompose the "Other" dump category, and add enforcement + memory-bridge sections.

## Context

The two HTML report generators were written at Phase 5/6 (v0.2.0) and never updated through 23 subsequent phases. They hardcode a 5-layer model (now 7), describe 7 hooks (now 13+ registrations across 5 event types), reference deleted files (.memory/MEMORY.md, PROJECT_STATE.md), list python3 as a hook dependency (now jq since Phase 24), and say "40 automated tests" (now 175). Regenerating at Phase 29 produced HTML with v0.5.0 timestamp but v0.2.0 architecture — actively misleading.

Sources of truth: `templates/.claude/settings.json` (hook registrations, nested structure), `templates/.claude/skills/MANIFEST` (24 skill descriptions as `# <dir>: <text>` comments), `README.md` (7-layer model), `tests/test_*.sh` (count `test_start` calls for test count), `templates/.claude/hooks/*.sh` (hook scripts), `install.sh` (modular installer).

Global enforcement hooks (enforce-spec.sh, enforce-loop.sh, detect-loop.sh) are installed to ~/.claude/hooks/ by install.sh — NOT in templates/.claude/settings.json. Cannot be enumerated dynamically. Must be documented as a known static set.

Note: `.dev-wiki/` files are filtered out by `get_file_tree()` (project-specific, not kit content). No Dev-Wiki category in reports.

## Scope

### In scope
- **generate-report.py** — update LAYERS (5→7), WORKFLOWS, categorize_files() (add Eval, Specs categories), replace `count_tests()` with `test_start` file counting, read MANIFEST descriptions
- **generate-workflow.py** — update subtitle (5→7 Layer), rewrite hardcoded flows, parse settings.json hooks dynamically, read MANIFEST for skill purposes, add Enforcement section with diagram, add Memory Bridge section with diagram
- **Staleness regression test** — new function in test_templates.sh: grep generated HTML for stale strings, verify layer/hook counts
- **Regenerate reports** — `make report && make workflow`

### Out of scope
- CSS/visual redesign (dark theme is fine)
- Mobile responsiveness
- New Makefile targets
- Markdown report alternative
- Automated report generation in CI
- Dev-Wiki category in reports (`.dev-wiki/` intentionally excluded from kit file tree)

## Approach

**Update in place, not rewrite.** The generators' infrastructure (CSS, HTML scaffolding, file counting, git info) is sound. ~250 lines of hardcoded narrative need updating.

1. **generate-report.py (~100 lines changed):**
   - Replace `LAYERS` list with 7-layer model matching README
   - Replace `WORKFLOWS` list with v0.5.0 descriptions (modular installer, 24 skills, enforcement, eval)
   - Add Eval (`eval/`) and Specs (`specs/`) categories to `categorize_files()`
   - Replace `count_tests()` — count `test_start` calls in test files instead of running `make test` (faster, no recursion risk). Count `test_start` only, not `assert_`.
   - Read MANIFEST descriptions for skill purpose column (regex: `^# (\S+): (.+)$`, first colon only)

2. **generate-workflow.py (~150 lines changed):**
   - Update subtitle: "7-Layer" not "5-Layer"
   - Rewrite Install Flow: modular installer with --all/--core-only/--no-python/--dry-run/--status, 24 skills, 4 modules, 5 global hooks
   - Rewrite Scaffold Flow: 7 layers, correct hook count (12 per-project + 5 global)
   - Rewrite Develop Flow: session-start reads 7 sources, enforcement status, crash recovery
   - Rewrite Lifecycle Flow: /dev-init → /spec → /dev-plan → implement → /dev-debrief
   - Add Enforcement section with ASCII diagram: enforce-spec (PreToolUse), enforce-loop (Stop), detect-loop (PostToolUse), provenance markers, enforcement.log
   - Add Memory Bridge section with ASCII diagram: dev-plan → memory_store, wiki-query → memory_search, dev-debrief → memory_harvest, supersession chains
   - Parse settings.json hooks with correct nested traversal (`hooks.EventType[].hooks[].command`)
   - Read MANIFEST descriptions for template inventory "Purpose" column
   - Document global enforcement hooks as static section (5 hooks installed by install.sh)

3. **Staleness test (~25 lines in test_templates.sh):**
   - Generate both reports to temp dir
   - Grep for known-stale strings: `.memory/MEMORY.md`, `5-Layer`, `python3 (json)`, `PROJECT_STATE.md` — fail if any found
   - Verify `7-Layer` or `7 Layer` appears in both reports
   - Count hook entries in workflow HTML, verify >= 9
   - Verify enforcement section header exists in workflow HTML
   - Verify memory bridge section header exists in workflow HTML

4. **Global hooks (static):** Enforcement hooks are installed globally by install.sh. Document as static "Global Enforcement Hooks" section listing: enforce-spec.sh, enforce-loop.sh, detect-loop.sh, pre-compact.sh, post-commit.sh.

## Constraints (CRITICAL)

- **No half-accurate reports.** Every hardcoded string must be audited. Guard: staleness test greps for known-stale strings and fails if any appear.
- **No `make test` in generators.** Replace with `test_start` counting in test files. Guard: `! grep -q 'make.*test' scripts/generate-report.py`.
- **MANIFEST parser handles colons.** Regex `^# (\S+): (.+)$` matches first colon only. Guard: generated HTML contains spec description (which has a colon).
- **settings.json nested traversal.** Structure is `hooks.EventType[].hooks[].command`. Guard: staleness test verifies hook count in HTML matches jq count from settings.json.
- **No CSS regression.** Only content/narrative changes. Guard: CSS block in generated HTML is unchanged.

## Deliverables

1. Modified `scripts/generate-report.py` — data-driven layers, workflows, categories, test counts, MANIFEST
2. Modified `scripts/generate-workflow.py` — data-driven hooks, flows, enforcement section, memory-bridge section
3. Modified `tests/test_templates.sh` — staleness regression test
4. Regenerated `docs/report.html`
5. Regenerated `docs/workflow.html`

## Exit Criteria (machine-checkable)

- [ ] `make test` (all existing + new tests pass)
- [ ] `make eval` (43/43 unchanged)
- [ ] `! grep -q '5-Layer' docs/workflow.html && ! grep -q '5-Layer' docs/report.html`
- [ ] `grep -q '7-Layer\|7 Layer' docs/workflow.html && grep -q '7-Layer\|7 Layer' docs/report.html`
- [ ] `! grep -q 'MEMORY.md' docs/workflow.html && ! grep -q 'MEMORY.md' docs/report.html`
- [ ] `grep -q '<h[23].*[Ee]nforcement' docs/workflow.html` (enforcement section exists)
- [ ] `grep -q '<h[23].*[Mm]emory.*[Bb]ridge' docs/workflow.html` (memory bridge section exists)
- [ ] `grep -q 'report_staleness\|report.*stale' tests/test_templates.sh`

## Checkpoints

- After generate-report.py updates: regenerate report.html, verify no stale strings via `grep -c 'MEMORY.md\|5-Layer\|PROJECT_STATE' docs/report.html` = 0
- After generate-workflow.py updates: regenerate workflow.html, verify enforcement and memory-bridge section headers present via grep
- After staleness test: verify it would catch stale strings (test the test)
- If any existing test breaks: STOP — generator changes should not affect non-report test assertions

## Assumptions

- The 7-layer model is stable. If false: make layer list a data file.
- settings.json hook structure (`hooks.EventType[].hooks[].command`) is stable. If false: add structural assertion that fails on format change.
- MANIFEST description format (`# <dir>: <text>`) is stable. If false: fall back to listing skill directories without descriptions.
- `make report` and `make workflow` Makefile targets need no changes. If false: update targets.
- CSS variable block (lines 111-157 in workflow.py) is reusable as-is. If false: extract to shared file.
