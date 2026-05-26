<!-- nana:approved 2026-05-25 -->
# Spec: Phase 41 — Harness Hardening & Process Safeguards

## Objective

Resolve remaining anti-patterns (#3 momentum risk, #5 companion proliferation) with targeted fixes: jq install guard, session-aware phase-cooldown advisory, bidirectional companion metadata validation, debrief duration tracking, and required soft observations.

## Context

After 40 phases at ~10/day velocity, the review identified 3 unresolved anti-patterns. Anti-Pattern #3 (momentum causing process violations) has evidence: "5 phases in one session creates pattern-matching that overrides protocol." Anti-Pattern #5 (companion proliferation without cross-reference validation) is measurable: dev-plan has 16 files with no parent/step metadata. A new issue emerged in Phase 40: jq is now a hard install-time dependency (7 calls in install.sh) without an upfront check. The debrief lacks duration/token tracking and inconsistently captures soft observations.

## Scope

### In scope
- install.sh: add jq presence guard before first jq call (2-3 lines)
- session-start.sh: write `.claude/.session-start-ts` (epoch seconds) for cooldown anchor
- Delivery flow: session-aware phase-cooldown advisory (fires only when ≥2 phases completed in session)
- Companion files: add `parent:` and `referenced_at:` frontmatter to all companions in templates/.claude/skills/
- Validation test: bidirectional companion check (orphaned companions AND dangling references)
- Debrief: duration field in template (estimate, post-compaction aware)
- Debrief: "Soft Observations" as required section (forward-only — existing entries remain valid)

### Out of scope
- Token tracking (unreliable post-compaction — defer until harness can reliably count)
- Retroactive fixing of existing 39 journal entries
- Companion files outside templates/.claude/skills/ (memory_server/, scripts/)
- Version bump (separate phase)
- New skills or hooks
- Phase dependency tracking (frontmatter `triggered_by:` field — lower priority)
- Documentation report staleness tests (Anti-Pattern #6 — separate phase)

## Approach

Six surgical fixes, each independently testable. Order: jq guard first (zero risk, immediate value), then session timestamp (1 line, enables cooldown), then companion metadata (largest surface area), then debrief enhancements (template changes), then cooldown advisory (uses session timestamp).

## Constraints (CRITICAL)

- install.sh must remain idempotent — jq guard is a pre-flight check, not a mode change
- Companion metadata is YAML frontmatter (---delimited) visible to Read tool as literal text — agents skip it, no parsing occurs. Must not break `cp -r` distribution.
- Cooldown advisory must be advisory-only (exit 0) — never block delivery
- Cooldown fires only when ≥2 phases completed since `.claude/.session-start-ts` — uses `git log --since=@$(cat .session-start-ts)` to count "Phase N" commits. Falls back to "last 4 hours" if timestamp missing.
- Soft Observations requirement applies forward-only — no retroactive validation of historical entries. "Required" means: section header must appear, content can be "none identified."
- Bidirectional companion validation has two independent checks:
  - Direction A: every non-SKILL.md .md file in a skill directory has `parent:` frontmatter naming its owning skill
  - Direction B: every `Read ~/.claude/skills/<path>` instruction in any SKILL.md resolves to an existing file
- `parent:` = owning skill directory name (always the sibling SKILL.md). `referenced_at:` = step within parent SKILL.md where it's referenced (e.g., "Step 2.5", "Step 8a-bis"). Cross-skill references (e.g., dev-plan referencing dev-wiki/state-template.md) are covered by Direction B only — the companion's `parent:` is still dev-wiki.
- No regressions in `make test` or `make eval`

## Deliverables

1. `install.sh` with jq guard (lines +2-3)
2. `templates/.claude/hooks/session-start.sh` — write `.claude/.session-start-ts` (1 line addition)
3. ~90 companion .md files with `parent:` + `referenced_at:` frontmatter added
4. `tests/test_companions.sh` — bidirectional validation test
5. `templates/.claude/skills/dev-debrief/SKILL.md` — updated with required Soft Observations + duration field
6. `templates/.claude/skills/dev-debrief/executor-prompt.md` — duration + soft observations instructions
7. Delivery flow cooldown advisory (in debrief SKILL.md, after executor returns — outside fallback path)
8. Makefile update (test_companions in test target)

## Exit Criteria (machine-checkable)

- [ ] `grep -q 'command -v jq' install.sh`
- [ ] `grep -q 'session-start-ts\|session.start.ts' templates/.claude/hooks/session-start.sh`
- [ ] `bash tests/test_companions.sh` (Direction A: all companions have parent field. Direction B: all SKILL.md Read references resolve.)
- [ ] `grep -qi 'soft.observation' templates/.claude/skills/dev-debrief/SKILL.md && grep -qi 'required\|must include\|mandatory' templates/.claude/skills/dev-debrief/SKILL.md`
- [ ] `grep -qi 'duration' templates/.claude/skills/dev-debrief/executor-prompt.md`
- [ ] `grep -qi 'cooldown\|phase.*session\|new.*session' templates/.claude/skills/dev-debrief/SKILL.md`
- [ ] `grep -q 'test_companions' Makefile`
- [ ] `make test && make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After jq guard + session timestamp: run `make test` to confirm no regression
- After companion metadata (largest batch change): run `bash tests/test_companions.sh` before proceeding
- After all changes: full `make test && make eval` verification

## Assumptions

- All companion .md files in templates/.claude/skills/ follow a consistent pattern (one parent SKILL.md per directory). If false: handle multi-parent cases by using owning directory as `parent:` — the file lives in one directory regardless of who references it.
- Session timestamp (.session-start-ts) is writable at ~/.claude/ by session-start.sh. If false: use git log --since="4 hours ago" as approximation (no timestamp needed).
- The debrief executor-prompt.md subagent can estimate duration from session context. If false: make duration field optional with "unknown" as valid value.
- Existing companion files all live under templates/.claude/skills/*/. If false: count actual files via `find templates/.claude/skills -name '*.md' ! -name 'SKILL.md' ! -name 'MANIFEST'` and adjust scope.
