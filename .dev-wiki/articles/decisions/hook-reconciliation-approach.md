---
title: "Hook Reconciliation Approach for Phase 36"
aliases: [hook-recon, phase-36-approach]
category: decisions
tags: [hooks, reconciliation, audit, phase-36]
parents: [phase-36-hooks-audit-housekeeping]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: medium
---

## Context

Phase 36 housekeeping bundle includes a hooks audit triggered by user-reported Claude Code errors on unspecified hooks. The kit ships 12 hooks in `templates/.claude/hooks/` but Jake's local global install has 11 hooks at `~/.claude/hooks/` with 6 hooks unique to the global install (`context-size-check`, `dev-wiki-post-commit`, `dev-wiki-scope-check`, `post-compact`, `session-stop`, `stale-queue`). Two of those — `dev-wiki-post-commit` and `dev-wiki-scope-check` — are referenced by trigger pattern in the kit-distributed `dev-wiki-hooks.md` rules file (`[dev-wiki:post-commit]`, `[dev-wiki:scope-check]`), meaning the kit's documented contract implies they exist but `install.sh` doesn't ship them. The remaining 4 may be Jake-local additions.

## Decision

Discovery-driven approach with 8 workstreams in dependency order. Note: this file (`hook-reconciliation-approach.md`) is the planning artifact; the per-hook disposition required by spec exit criterion #1 is a separate file `hook-reconciliation.md` written during Task 2.

1. Evidence capture + global/kit diff inventory (S)
2. Per-hook reconciliation decision: backport/delete/tolerate for each of the 6 global-only hooks (S) — disposition for ALL 6 is open, including `dev-wiki-post-commit`/`dev-wiki-scope-check` (these two have higher prior likelihood of backport because they are referenced by trigger pattern in the kit-distributed `dev-wiki-hooks.md`, but the decision is made in Task 2, not pre-judged here)
3. Static lint sweep on all kit hooks: `bash -n`, `set -euo pipefail`, jq fail-open guard (on documented hooks per `jq-hook-migration` decision), stdin contract (M) — parallelizable with 1+2
4. Targeted hook fixes pinned to quoted evidence or specific lint findings; backport candidates pending Task 2 disposition (M)
5. README ts-init coverage + stale "201" count sweep across repo (M) — test count set LAST
6. Nanaclaw upstream PR (S) — push only, single-commit clean branch
7. TS polish spot-check bounded by spec's 4-item "surfaced" definition (S)
8. Cleanup: `.hook-prefix-inventory.md` resolution, MANIFEST regenerate if any skill file touched, full test+eval (S)

Hook fixes are tested in `mktemp -d` tmpdirs, never against the live `.claude/enforce` marker, to avoid locking the author out mid-phase if `enforce-spec.sh` regresses.

### Alternative considered and rejected

**Fix-first, audit-later** (apply common hook hardening patterns to all hooks then test) — rejected because spec constraint mandates each fix be pinned to quoted evidence (error string or specific lint violation); fix-first sequencing violates that constraint and produces fixes without justification trails.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Lint surfaces stdin-contract drift across many hooks (Claude Code spec moved underneath kit) | Medium | High (scope expansion beyond housekeeping) | Spec checkpoint at ">5 issues per hook → STOP" forces escalation; phase aborts cleanly rather than ballooning |
| Hook fix regresses `enforce-spec.sh` and locks author out mid-phase | Low | High (cannot complete phase) | All hook changes tested in `mktemp -d` tmpdir before touching kit; live `.claude/enforce` marker untouched |
| Nanaclaw patch no longer applies cleanly to upstream HEAD | Medium | Low (skip PR with documented reason) | Spec exit criterion #8 accepts `skipped: <reason>` branch; no force-apply |

## Consequences

- 8 tasks total (3S + 5M, no L) — fits under the "no L tasks" YAGNI constraint
- Discovery-first ordering means no fix lands without evidence (matches spec constraint)
- Backport of dev-wiki-post-commit/scope-check is provisional, gated on Task 2 disposition — could become "tolerate-as-local" if user disagrees
- Test count refresh as last step accommodates any new tests added by hook fixes
- Tmpdir testing prevents accidental self-lockout via enforce-spec.sh regression
