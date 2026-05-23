# Spec: Phase 27 — DX + Ship

## Objective

Fix stale documentation numbers, add regression tests that prevent documentation drift, and ship v0.5.0 as the release marking roadmap completion (26 phases, 1 remaining gap deferred).

## Context

After 26 phases, nana-dev-kit has 22 skills, 11 hooks, 160 tests, and 43 eval scenarios — but the README claims 133 tests across 6 scripts and 38 eval scenarios. These numbers went stale between Phases 22-26 because no test asserts documentation accuracy. The install.sh post-install summary is adequate but could better reflect the full capability set. The kit is feature-complete for its intended scope: the only remaining roadmap gap (4.1, language-agnostic core) is deferred. This is a clean-up and ship phase.

## Scope

### In scope
- `README.md` — fix stale numbers (160 tests/5 scripts, 43 eval scenarios), verify all claims
- `tests/test_templates.sh` — add README accuracy regression assertions (test count, eval count, script count match reality)
- `install.sh` — polish post-install summary (no structural changes)
- `VERSION` — bump to 0.5.0
- Tag v0.5.0, push

### Out of scope
- Runtime skill catalog or `/help` skill (Claude Code's system-reminder already lists available skills)
- Hook error message rewrites (current messages are clear and actionable)
- CHANGELOG file (commit history and dev-wiki journal serve this role)
- Language-agnostic mode (Gap 4.1 — separate future phase if pursued)
- New features, new hooks, new skills

## Approach

**README refresh**: Update hardcoded numbers to match current state. Two locations: the Testing section (`make test` comment) and the Eval section (layer table + eval description). Verify every factual claim in README against the actual codebase.

**Documentation staleness regression**: Add test assertions to `test_templates.sh` that:
- Count test scripts in Makefile, compare to README claim
- Count eval scenarios via `find`, compare to README claim
- Verify VERSION file value appears in or is consistent with README

These tests will fail when future phases add tests/eval/skills without updating README — preventing the same drift pattern.

**Install summary polish**: Minor — ensure module counts in the summary match reality. No structural changes to install.sh.

**Ship**: Bump VERSION, commit, tag v0.5.0, push.

## Constraints (CRITICAL)

- **No new features.** This phase fixes documentation and ships. Every change must trace to accuracy or polish. Prevents: scope creep disguised as "DX improvement."
- **README staleness tests must grep actual counts, not hardcode expected values.** The test computes the real count AND extracts the README claim, then compares. Prevents: the test itself going stale.
- **Single version source of truth.** VERSION file is authoritative. Test that README doesn't contain a conflicting version string. Prevents: version mismatch across files.
- **install.sh changes are cosmetic only.** Diff must be limited to echo/printf statements — no logic changes, no new control flow, no new flag parsing, no new module groups. Prevents: destabilizing a 280-line script for polish.

## Deliverables

1. Modified `README.md` — accurate numbers throughout
2. Modified `tests/test_templates.sh` — 3-4 new README accuracy assertions
3. Modified `install.sh` — polished summary output (cosmetic only)
4. Modified `VERSION` — 0.5.0
5. Git tag v0.5.0

## Exit Criteria (machine-checkable)

- [ ] `make test`
- [ ] `make eval`
- [ ] `grep -qx '0.5.0' VERSION`
- [ ] `git tag -l 'v0.5.0' | grep -q 'v0.5.0'`

## Checkpoints

- After README + tests pass: report before proceeding to version bump
- If any existing test breaks: STOP and investigate before continuing

## Assumptions

- Current test count (160) and eval count (43) are stable — no other changes in flight. If false: use the actual count at time of implementation.
- README has no other stale claims beyond numbers. If false: fix discovered inaccuracies as part of the README task.
- v0.4.0 tag exists and is pushed. If false: verify tag state before creating v0.5.0.
