---
title: "Phase 28: DX Discoverability complete"
aliases: []
category: journal
tags: [dx, hooks, manifest, discoverability, install, status]
parents: [phase-28-dx-discoverability]
created: 2026-05-23
updated: 2026-05-23
source: debrief
---

# Phase 28: DX Discoverability complete

## What Happened
- Normalized hook message prefixes across all 11 hooks to use `[nana:<hook>]` convention. session-start.sh uses semantic sub-prefixes (`[nana:gate]`, `[nana:memory]`, `[nana:recovery]`, `[nana:pending]`, `[nana:enforce]`, `[nana:kit]`). Exception: `[dev-wiki:post-commit]` kept as semantic trigger.
- Added `install.sh --status` flag for runtime inventory: counts skills, hooks, rules, checks memory venv, reads VERSION, checks enforcement marker. Grouped output by module category.
- Enriched MANIFEST with `# <skill-dir>: <description>` comment section after existing checksums. Descriptions extracted from first sentence of each SKILL.md.
- Added `[nana:kit]` dynamic summary line to session-start.sh as final output (skill/hook counts, memory status, VERSION).
- Updated 5 eval scenario assertions to match new `[nana:]` prefixes. All 43/43 eval scenarios pass.

## Decisions Made
- [[hook-prefix-nana-namespace|Hook prefix [nana:<hook>] namespace]] -- confirmed (medium -> high)
- [[status-in-install-sh|Status command in install.sh]] -- confirmed (medium -> high)

## Problems Solved
- Built assertion inventory first (Task 1) to map exact echo/printf lines and eval assertions before touching hooks, preventing missed updates.
- `[dev-wiki:post-commit]` semantic trigger coupling identified: kept as-is since renaming would break cross-cutting contract with dev-wiki-hooks rules.

## Artifacts Changed
- `templates/.claude/hooks/*.sh` (all 11 hooks prefixed), `install.sh` (--status), `templates/.claude/skills/MANIFEST` (descriptions)
- `eval/corpus/` (4 scenario assertions updated), `tests/test_install.sh` + `tests/test_templates.sh` (6 new assertions)

## Related
- [[phase-28-dx-discoverability|Phase 28: DX Discoverability]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- `[dev-wiki:post-commit]` semantic trigger coupling to dev-wiki-hooks.md rules is fragile -- rules file is user-level, not templated. Future users who don't have that rules file won't get the trigger behavior. | candidate: template the dev-wiki-hooks rules | evidence: post-commit.sh emits `[dev-wiki:post-commit]`, rules file matches on it
- MANIFEST is manually generated -- no automation keeps descriptions in sync with SKILL.md changes. A make target or pre-commit check could prevent drift. | candidate: MANIFEST automation | evidence: manual enrichment this phase
- `install.sh --status` doesn't detect version skew (hook files older than kit VERSION). Could add mtime comparison but not critical at current scale. | candidate: version-skew detection | evidence: adversarial constraint from spec review

### Review Gate
Score: 8/10
Issues:
- [MEDIUM] _ARCHITECTURE.md stale -- test count (163) and hook descriptions don't reflect Phase 28 changes (169 tests, `[nana:]` prefix convention, `--status` flag). Updated in this debrief.
- [MEDIUM] Eval scenario count in working-knowledge entry says "41 scenarios" but actual is 43. Stale entry.
Verdict: accept

### Activation Quality
3 source sections in active-knowledge.md. Hit rate:
- "Hook prefix convention" (from [[decision:hook-prefix-nana-namespace]]): USED -- drove all 11 hook prefix edits
- "Status command and MANIFEST" (from [[decision:status-in-install-sh]]): USED -- drove --status implementation and MANIFEST enrichment
- "Hook message patterns and eval" (from [[decision:jq-hook-migration]] + eval): USED -- guided eval assertion updates
Hit rate: 3/3 (100%)

### Gate Compliance
Gates: `spec=9/10(revised) approach=yes plan-review=8/10 tasks=yes`. Standard ceremony expects: spec, approach, plan-review, tasks. All present and passed.
