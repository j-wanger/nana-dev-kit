---
title: "Phase 34: Upstream Sync + store() Optimization + TypeScript Design Spec"
aliases: []
category: phases
tags: [nanaclaw, upstream, performance, storage, typescript, ts-init, design]
parents: [phase-33-hybrid-retrieval-benchmark-memory-server-fixes]
created: 2026-05-24
updated: 2026-05-24
source: plan
status: completed
scope: ["patches/*", "memory_server/storage.py", "tests/test_memory.sh", "specs/ts-init-design.md", ".dev-wiki/articles/decisions/nanaclaw-divergence-inventory.md", "Makefile"]
entry_criteria: "Phase 33 complete, 190 tests passing, 47/47 eval, spec approved"
exit_criteria: "Vendored-only functions survive, no unbounded full scans in _find_near_duplicate, tests/test_memory.sh passes, ts-init design spec >= 80 lines with TS-specific content, divergence documented, patch exists or skip documented, make test passes"
---

# Phase 34: Upstream Sync + store() Optimization + TypeScript Design Spec

## Objective

Sync the _sanitize_fts_query fix to nanaclaw upstream via surgical patch, eliminate O(n^2) near-duplicate detection in store() by replacing full table scans with indexed lookups (vec0 KNN + FTS5 MATCH), and produce a design spec for a ts-init skill as the first step toward TypeScript project scaffolding support.

## Scope

Files and modules affected:
- `patches/nanaclaw-sanitize-fts.patch` -- surgical upstream sync for _sanitize_fts_query
- `.dev-wiki/articles/decisions/nanaclaw-divergence-inventory.md` -- kit-only vs shared function inventory
- `memory_server/storage.py` -- _find_near_duplicate() optimization (cosine + word-overlap paths)
- `tests/test_memory.sh` -- threshold equivalence tests (cosine 0.84/0.86/0.91, word-overlap 0.89/0.91)
- `Makefile` -- wire test_memory target
- `specs/ts-init-design.md` -- TypeScript scaffolding design spec

## Exit Criteria

- [ ] Vendored-only functions survive (search_hybrid, search_vec, export_memories)
- [ ] No unbounded `SELECT * FROM memories WHERE active = 1` in _find_near_duplicate
- [ ] tests/test_memory.sh exists and passes
- [ ] ts-init design spec >= 80 lines with tsconfig.json, package.json, AGENTS.md coverage
- [ ] Divergence inventory documented
- [ ] Patch exists or skip documented
- [ ] make test passes (no regression in 190 existing tests)

## Constraints

- Upstream patch is surgical single-function only -- no vendored-only code enters nanaclaw
- store() optimization preserves exact dedup thresholds (cosine >0.90 reinforce, >0.85 warn; word overlap >0.90 warn)
- FTS5-only mode must work when _vec_available=False
- No changes to store() public function signature
- FTS5 pre-filtering bounded by LIMIT clause

## Checkpoints

- After reading nanaclaw upstream: report whether _sanitize_fts_query exists, state, patch feasibility
- After cosine path optimization: run threshold equivalence tests at boundary values
- After word-overlap path optimization: run threshold equivalence tests at boundary values
- After tests/test_memory.sh passes: report test count before proceeding to TS design spec
- If nanaclaw repo inaccessible: skip patch, document, continue

## Assumptions

- nanaclaw upstream repo accessible for reading. If false: skip patch, document inaccessibility.
- sqlite3 and Python 3.10+ available for tests. If false: verify optimization via code review.
- py-init skill pattern representative for ts-init. If false: survey other patterns first.
- FTS5 pre-filtering returns sufficient candidates. If false: degrade to bounded full scan with LIMIT.

## Notes

- Three workstreams sequenced: upstream sync -> store() optimization (with baseline tests first) -> TS design spec
- Tasks 3 and 4 (cosine/word-overlap optimization) depend on Task 2 (baseline tests) but are independent of each other
- Formal spec at specs/phase-34-upstream-sync-store-opt-ts-design.md (approved)
