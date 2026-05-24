<!-- nana:approved 2026-05-23 -->
# Spec: Phase 29 — v0.5.1 Grade Push

## Objective

Close the remaining gaps from the v0.5.0 five-lens critique to move all critic grades to A: in-session skill discovery (/nana), test robustness (root-skip, MANIFEST freshness), memory consolidation via Claude (no Qwen dependency), and spec provenance enforcement with event logging.

## Context

v0.5.0 shipped 28 phases with 169 tests and 43 eval scenarios. A five-lens critique (DX, Python Dev, Portability, Memory, Harness) graded the kit B+/A-/B/B+/A-. Each lens identified specific "move to A" items. Investigation reveals that the Portability item (cross-skill reference validation test) was already implemented in Phase 26 — it validates all ~120 references in test_templates.sh. The remaining Portability gap (Claude Code exclusivity for Layers 2-4) is architectural and documented. The Portability improvement in this phase is a MANIFEST freshness test replacing the duplicate request.

Key constraints from investigation:
- dev-plan SKILL.md is at 341/350 lines — companion extraction needed for headroom
- install.sh is at 350 lines — no changes needed (new skills auto-distribute via cp -r)
- Specs lack YAML frontmatter — provenance marker will use HTML comment format
- 20 existing specs lack markers — enforce-spec.sh must remain backward-compatible
- memory_server consolidator.py is vendored from nanaclaw — avoid Python changes
- MANIFEST lives at `templates/.claude/skills/MANIFEST` in the repo, not inside a skill directory — the /nana skill reads it via the kit path marker

## Scope

### In scope
- **New /nana skill** — SKILL.md that reads MANIFEST descriptions, groups by module, outputs formatted skill list
- **Root-detection skip** — add `id -u` check to 2 writability tests in test_sync_rules.sh
- **Dev-plan companion extraction** — extract Step 3 (Explore Phase Scope) to create ceiling headroom (target: SKILL.md ≤ 320 lines)
- **MANIFEST freshness test** — new test function comparing skill directories to MANIFEST entries
- **Memory consolidation skill** — /memory-consolidate SKILL.md using memory_search/memory_store/memory_forget MCP tools (Claude-powered, no Qwen)
- **README consolidation note** — brief note on memory maintenance options
- **Spec provenance marker** — /spec Step 6 writes `<!-- nana:approved YYYY-MM-DD -->`, enforce-spec.sh validates
- **Enforcement event log** — enforce-spec.sh and enforce-loop.sh append to `.dev-wiki/enforcement.log`
- **Tests + eval** — assertions for all new behavior, existing suite passes

### Out of scope
- Python changes to vendored memory_server/ (use skill-based consolidation instead)
- install.sh modifications (new skills auto-distribute via directory copy)
- Qwen sidecar documentation (superseded by skill-based consolidation)
- Language-agnostic core (Gap 4.1 — deferred)
- dev-plan feature additions (extraction is for headroom only)
- New eval scenarios (test assertions sufficient for this phase's items)

## Approach

**Seven work items, sequenced test-first:**

1. **Root-skip fix** (trivial) — Add `[ "$(id -u)" = "0" ] && skip "cannot test writability as root"` before each of the 2 writability tests in test_sync_rules.sh (lines 72-93). Zero risk.

2. **Dev-plan companion extraction** — Extract Step 3 (Explore Phase Scope, ~25 lines including the code-article path and raw-file fallback) to a new companion file `templates/.claude/skills/dev-plan/scope-exploration-spec.md`. Replace inline content with a 2-line Read pointer: `Read ~/.claude/skills/dev-plan/scope-exploration-spec.md for the full scope exploration protocol.` Target: SKILL.md ≤ 320 lines.

3. **/nana skill** — New `templates/.claude/skills/nana/SKILL.md` (~30-40 lines). Reads MANIFEST via kit path marker: constructs path as `$(cat ~/.claude/.nana-dev-kit-path)/templates/.claude/skills/MANIFEST`. Parses `# <skill-dir>: <description>` comment lines. Groups by module prefix (dev-*, wiki-*, py-*, spec, knowledge-wiki, other). Outputs formatted grouped list. Fallback if kit path marker absent: list `~/.claude/skills/*/SKILL.md` directory names without descriptions.

4. **/memory-consolidate skill** — New `templates/.claude/skills/memory-consolidate/SKILL.md` (~30-40 lines). Search strategy: run memory_search three times — (a) with tags `bridge-decision`, (b) with tags `harvest`, (c) with category `custom`. Deduplicate by memory ID across results. Identify clusters with overlapping content/tags. For each cluster: write merged entry via memory_store, forget originals via memory_forget. Budget cap: 10 merges per invocation. Dry-run mode: list clusters without modifying.

5. **Spec provenance marker** — /spec SKILL.md Step 6: prepend `<!-- nana:approved YYYY-MM-DD -->` as first line of the persisted spec file.

6. **Enforcement hardening** — Two changes to enforce-spec.sh:
   - **Provenance check:** Augment the existing spec-file validity check at lines 50-53. Change the condition from "exit criteria present → allow" to "(provenance marker present OR exit criteria present) → allow". Add `grep -q 'nana:approved' "$SPEC_FILE"` as an additional OR condition before the existing `grep -qE '^\- \[ \] ` check. All 20 existing specs continue working because they have exit criteria.
   - **Event logging:** After every allow/block decision (just before each `exit 0` and `exit 2`), append one-line JSON to `.dev-wiki/enforcement.log`: `{"ts":"<ISO>","hook":"enforce-spec","action":"allow|block","reason":"<why>"}`. Add same logging to enforce-loop.sh. Truncate log to last 500 lines after each write: `tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"`.

7. **Tests + MANIFEST** — MANIFEST freshness test in test_templates.sh: list all `templates/.claude/skills/*/SKILL.md` parent directory names, verify each has a matching `# <dir>:` description line in MANIFEST. Add assertions for nana and memory-consolidate SKILL.md existence. Update MANIFEST with new skill entries. Add 2-3 lines to README about /memory-consolidate.

## Constraints (CRITICAL)

- **Backward compatibility for enforce-spec.sh.** The 20 existing specs lack provenance markers. The enforcement check MUST use OR logic: (approved marker present) OR (exit criteria present, legacy check). Prevents: breaking enforcement on existing projects.
- **No vendored Python changes.** memory_server/ is vendored from nanaclaw. The consolidation skill uses MCP tool calls, not Python-level changes. Prevents: fork divergence from upstream.
- **Enforcement log bounded.** Each hook append must truncate to ≤500 lines after writing. Prevents: unbounded disk growth.
- **Dev-plan extraction must not change behavior.** The extracted content moves to a companion file referenced by `Read`. No orchestration logic changes. Run cross-skill reference test after extraction. Prevents: broken subagent dispatch.
- **MANIFEST freshness test must not duplicate cross-skill ref test.** The existing test validates SKILL.md path references. The new test validates MANIFEST description coverage. Different concern. Prevents: redundant test maintenance.

## Deliverables

1. `templates/.claude/skills/nana/SKILL.md` — in-session skill discovery (~30-40 lines)
2. `templates/.claude/skills/memory-consolidate/SKILL.md` — Claude-powered memory consolidation (~30-40 lines)
3. Modified `templates/.claude/skills/dev-plan/SKILL.md` — extracted Step 3, ≤320 lines
4. New `templates/.claude/skills/dev-plan/scope-exploration-spec.md` — extracted scope exploration protocol
5. Modified `templates/.claude/skills/spec/SKILL.md` — provenance marker in Step 6
6. Modified `templates/.claude/hooks/enforce-spec.sh` — provenance check + event logging
7. Modified `templates/.claude/hooks/enforce-loop.sh` — event logging
8. Modified `tests/test_sync_rules.sh` — root-detection skip
9. Modified `tests/test_templates.sh` — MANIFEST freshness test + new skill assertions
10. Modified `README.md` — consolidation note
11. Updated `templates/.claude/skills/MANIFEST` — new skill entries

## Exit Criteria (machine-checkable)

- [ ] `make test` (all existing + new tests pass)
- [ ] `make eval` (43/43 scenarios pass)
- [ ] `test -f templates/.claude/skills/nana/SKILL.md`
- [ ] `test -f templates/.claude/skills/memory-consolidate/SKILL.md`
- [ ] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 320 ]`
- [ ] `grep -q 'nana:approved' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -q 'enforcement.log' templates/.claude/hooks/enforce-spec.sh`
- [ ] `grep -q 'enforcement.log' templates/.claude/hooks/enforce-loop.sh`
- [ ] `grep -q 'id -u' tests/test_sync_rules.sh`
- [ ] `grep -q 'manifest_freshness\|MANIFEST.*fresh' tests/test_templates.sh`

## Checkpoints

- After root-skip fix + dev-plan extraction: run `make test` to verify no regressions before proceeding
- After /nana + /memory-consolidate skills: verify MANIFEST updated with new entries
- After enforce-spec.sh changes: manually test backward compatibility — verify existing specs (which have exit criteria but no marker) still pass the hook
- If enforce-spec.sh change causes unexpected blocks: STOP — this affects all opted-in projects

## Assumptions

- MANIFEST description format (`# <skill-dir>: <description>`) is stable from Phase 28. If false: adapt /nana parser to actual format.
- Specs are written to `specs/<slug>.md` without YAML frontmatter (HTML comment marker is the only option). If false: use YAML frontmatter field instead.
- memory_search/memory_store/memory_forget MCP tools are available in sessions where /memory-consolidate is invoked. If false: add availability check with graceful skip message.
- dev-plan Step 3 (Explore Phase Scope) is self-contained enough to extract without breaking step references. If false: extract a different section or relax target to ≤330.
- Enforcement log path `.dev-wiki/enforcement.log` won't conflict with existing .dev-wiki files. If false: use `.dev-wiki/.enforcement.log` (hidden file).
