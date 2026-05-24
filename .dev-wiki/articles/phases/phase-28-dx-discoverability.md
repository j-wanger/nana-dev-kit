---
title: "Phase 28: DX Discoverability"
aliases: []
category: phases
tags: [dx, hooks, manifest, discoverability, install]
parents: []
created: 2026-05-23
updated: 2026-05-23
source: plan
status: completed
scope: ["templates/.claude/hooks/*.sh", "install.sh", "templates/.claude/skills/MANIFEST", "tests/", "eval/corpus/"]
entry_criteria: "Phase 27 complete, 163 tests passing, 43/43 eval, v0.5.0 tagged"
exit_criteria: "Hook message format normalized across 11 hooks, install.sh --status command works, MANIFEST enriched with descriptions, make test + make eval pass"
---

# Phase 28: DX Discoverability

## Objective

Normalize hook message format across 11 hooks using a `[nana:<hook>]` prefix convention, add a runtime status command (`install.sh --status`), enrich the MANIFEST with skill descriptions, and add a session-start kit summary line -- so users and Claude can discover what's installed, what's active, and what each piece does.

## Scope

Files and modules affected:
- `templates/.claude/hooks/*.sh` -- all 11 hooks get prefix normalization
- `install.sh` -- new `--status` flag handler
- `templates/.claude/skills/MANIFEST` -- descriptions section
- `eval/corpus/` -- 4 scenario files updated for new prefixes
- `tests/test_install.sh`, `tests/test_templates.sh` -- new assertions

## Exit Criteria

- [ ] All 11 hooks use `[nana:<hook>]` prefix (exception: `[dev-wiki:post-commit]` kept)
- [ ] `install.sh --status` produces grouped inventory output
- [ ] MANIFEST has `# <skill-dir>: <description>` section
- [ ] Session-start emits `[nana:kit]` summary line
- [ ] `make test` passes
- [ ] `make eval` passes (43/43 with updated assertions)

## Constraints

- Eval assertions use substring matching -- preserve key substrings to minimize eval changes. Prevents silent false passes.
- `[dev-wiki:post-commit]` is a semantic trigger referenced by dev-wiki-hooks rules. Renaming it would break cross-cutting contract.
- MANIFEST descriptions are additive (comment section after existing checksums). Existing checksum lines must not change.

## Assumptions

- All 11 hooks have identifiable echo/printf output lines. If false: some hooks may be silent-only and need no prefix.
- Eval scenarios use `stdout_contains`/`stderr_contains` for assertion matching. If false: check assertion type before modifying.

## Outcome

All 6 tasks completed. 11 hooks normalized to `[nana:<hook>]` prefix, `install.sh --status` implemented, MANIFEST enriched with 22 skill descriptions, session-start emits `[nana:kit]` summary. Tests: 163 -> 169. Eval: 43/43 (5 assertion strings updated).

## Notes

- Three work streams ordered by blast radius: (1) hook prefix normalization, (2) install.sh --status, (3) MANIFEST enrichment + session-start summary.
- Approach: build assertion inventory first (Task 1) to map exact changes needed before touching any hooks.
