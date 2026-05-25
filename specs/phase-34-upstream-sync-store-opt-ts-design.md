<!-- nana:approved 2026-05-24 -->
# Spec: Phase 34 — Upstream Sync + store() Optimization + TypeScript Design Spec

## Objective

Sync the _sanitize_fts_query fix to nanaclaw upstream, eliminate O(n^2) near-duplicate detection in store(), and produce a design spec for a ts-init skill as the first step toward TypeScript project scaffolding support.

## Context

memory_server/storage.py is vendored from nanaclaw (Phase 4) and has diverged significantly — 903 lines vs ~170 original. Kit-only additions include search_hybrid() with RRF fusion, search_vec() for sqlite-vec, _cosine_similarity(), _find_near_duplicate() with cosine+word-overlap dedup, and full import/export. Phase 33 rewrote _sanitize_fts_query with char-level stripping (`re.sub(r'[^\w\s]', ' ', query)`) to handle FTS5 special characters — this fix needs syncing upstream.

The store() function's _find_near_duplicate() does full table scans on every call: the cosine path fetches ALL active memories with embeddings (line 273-276), and the word-overlap path fetches ALL active memories (line 295-296). During LongMemEval-S benchmarking with ~1,000 entries per database, this became a measurable bottleneck. sqlite-vec is a benchmark-only dependency (not in install.sh), so the optimization must work without it.

The existing py-init skill (168 LOC SKILL.md + scanner.md + transform.md = 368 lines) scaffolds Python projects with pyproject.toml, ruff, mypy, pytest. TypeScript is the next target language. Python is acceptable as a dependency for memory/wiki infrastructure — the TS analysis covers project scaffolding only, not removing Python from the kit.

## Scope

### In scope
- Read nanaclaw upstream storage.py HEAD from https://github.com/j-wanger/nanaclaw, compare _sanitize_fts_query approaches
- Create targeted upstream patch at `patches/nanaclaw-sanitize-fts.patch` (single-function, not full divergence merge)
- Document full divergence inventory (functions that exist only in vendored copy)
- Optimize _find_near_duplicate() cosine path: use sqlite-vec KNN query instead of full scan (when _vec_available)
- Optimize _find_near_duplicate() word-overlap path: use FTS5 candidate pre-filtering instead of full scan
- Preserve exact dedup threshold semantics (cosine >0.90 reinforce, >0.85 warn, word overlap >0.90 warn)
- Create tests/test_memory.sh with threshold equivalence and FTS5-only mode tests
- Produce specs/ts-init-design.md covering: skill structure, AGENTS.md template strategy, install.sh module group, CI template, monorepo edge case

### Out of scope
- Implementing ts-init (design spec only — Phase 35+)
- Changing RRF fusion parameters (alpha=0.4, k=60) or embedding model (nomic-embed-text-v1.5)
- Adding sqlite-vec or fastembed as required dependencies (remain benchmark-only)
- Removing Python dependency from wiki-index or memory_server
- Refactoring py-init into a language-agnostic /init router (may be recommended in design spec)
- Merging full vendored divergence upstream (surgical _sanitize_fts_query patch only)
- Latency benchmarking (correctness-focused optimization)

## Approach

Three sequenced workstreams:

1. **Upstream sync** — Read nanaclaw upstream storage.py HEAD from https://github.com/j-wanger/nanaclaw. Compare _sanitize_fts_query implementations. If upstream has its own fix: document comparison. If not: create a minimal patch containing only the _sanitize_fts_query function with the char-level stripping approach. Write a divergence inventory decision article listing all functions that are kit-only vs upstream-shared. Post-sync, verify all vendored-only functions survive.

2. **store() optimization** — In _find_near_duplicate(), replace the cosine full-scan (`SELECT * FROM memories WHERE active = 1 AND embedding IS NOT NULL` → iterate all) with a sqlite-vec KNN query (`SELECT ... FROM memories_vec WHERE embedding MATCH ? ORDER BY distance LIMIT ?`) that returns only top-k candidates, then apply threshold checks on candidates only. For the word-overlap path, replace the full scan (`SELECT * FROM memories WHERE active = 1` → iterate all) with FTS5 pre-filtering: tokenize the input content, query memories_fts for candidates, then compute word overlap only on candidates. Both paths must preserve exact threshold semantics. When _vec_available is False, the cosine path is skipped entirely (existing gate preserved). Create tests/test_memory.sh with equivalence tests at threshold boundaries.

3. **TypeScript design spec** — Enumerate every py-init assumption and map to TypeScript equivalent or N/A: package manager (npm/pnpm/bun), config (tsconfig.json + package.json), project layout (src/ convention differences), linter/formatter (eslint+prettier vs biome), type checker (tsc is the compiler, not separate like mypy), test runner (vitest/jest), pre-commit hooks. Address AGENTS.md template strategy, install.sh module group design, CI template differences, and monorepo edge cases (nx, turborepo). Output is a decision document, not implementation.

## Constraints (CRITICAL)

- Upstream sync MUST be a surgical single-function patch — prevents: carrying vendored-only code into nanaclaw or dropping vendored code from the kit. Guard: post-sync grep for `def search_hybrid`, `def search_vec`, `def _ensure_vec`, `def export_memories`, `def import_memories` in kit storage.py confirms no loss.
- store() optimization MUST preserve exact dedup thresholds — prevents: changing which memories get reinforced vs newly stored, causing silent data corruption. Guard: before/after equivalence test with known near-duplicates at boundary values (cosine 0.84, 0.86, 0.91; word overlap 0.89, 0.91) must produce identical StoreResult.action outcomes.
- Optimization MUST work in FTS5-only mode (_vec_available=False) — prevents: introducing hard dependency on sqlite-vec for store(), a core production path. Guard: test store() with _vec_available=False, confirm word-overlap fallback runs without error or degradation.
- ts-init spec MUST NOT inherit Python assumptions uncritically — prevents: producing a skill that confuses TypeScript developers with Python conventions. Guard: every py-init assumption explicitly enumerated with TypeScript equivalent or N/A justification in the design spec.
- No changes to the public store() function signature — prevents: breaking MCP server (server.py) and all downstream callers. Guard: store() parameter list identical before and after.
- FTS5 pre-filtering candidate count MUST be bounded — prevents: FTS5 query returning unbounded results that negate the optimization. Guard: LIMIT clause on FTS5 candidate query (e.g., LIMIT 50).

## Deliverables

1. `patches/nanaclaw-sanitize-fts.patch` — diff file for nanaclaw's _sanitize_fts_query
2. `.dev-wiki/articles/decisions/nanaclaw-divergence-inventory.md` — documents kit-only vs shared functions
3. `memory_server/storage.py` — optimized _find_near_duplicate() with indexed lookups
4. `tests/test_memory.sh` — threshold equivalence tests, FTS5-only mode test, n=1 edge case
5. `specs/ts-init-design.md` — TypeScript scaffolding design spec (~100-150 lines)

## Exit Criteria (machine-checkable)

- [ ] `grep -q 'def search_hybrid' memory_server/storage.py && grep -q 'def search_vec' memory_server/storage.py && grep -q 'def export_memories' memory_server/storage.py` (vendored-only functions survive)
- [ ] `! (awk '/^def _find_near_duplicate/,/^def [a-z]/' memory_server/storage.py | grep -q '"SELECT \* FROM memories WHERE active = 1"')` (no unbounded full scans remain in _find_near_duplicate — bounded LIMIT 50 fallback is acceptable)
- [ ] `test -f tests/test_memory.sh && bash tests/test_memory.sh` (memory tests exist and pass)
- [ ] `test -f specs/ts-init-design.md && [ $(wc -l < specs/ts-init-design.md) -ge 80 ] && grep -q 'tsconfig' specs/ts-init-design.md && grep -q 'package.json' specs/ts-init-design.md` (TS design spec exists with TypeScript-specific content)
- [ ] `test -f .dev-wiki/articles/decisions/nanaclaw-divergence-inventory.md` (divergence documented)
- [ ] `test -f patches/nanaclaw-sanitize-fts.patch || grep -qi 'inaccessible\|archived\|skip' .dev-wiki/articles/decisions/nanaclaw-divergence-inventory.md` (patch exists or skip documented)
- [ ] `make test` (no regressions in existing 190 tests)

## Checkpoints

- After reading nanaclaw upstream: report whether _sanitize_fts_query exists there, what state it's in, and whether a patch is feasible or the upstream has diverged too far.
- After cosine path optimization (sqlite-vec KNN): run cosine threshold equivalence tests. If any boundary case changes behavior, STOP and investigate.
- After word-overlap path optimization (FTS5 pre-filtering): run word-overlap threshold equivalence tests. If any boundary case changes behavior, STOP and investigate.
- After tests/test_memory.sh passes: report test count and coverage areas before proceeding to TS design spec.
- If nanaclaw repo is inaccessible or archived: skip upstream patch, document in divergence inventory, continue with store() optimization.

## Assumptions

- nanaclaw upstream repository is accessible for reading current storage.py HEAD. If false: skip upstream patch deliverable, document inaccessibility in divergence inventory, proceed with remaining workstreams.
- sqlite3 and Python 3.10+ are available for running tests. If false: skip test_memory.sh, verify optimization via code review only.
- The py-init skill at templates/.claude/skills/py-init/ is representative of the scaffolding pattern that ts-init should follow. If false: survey other scaffolding patterns before designing ts-init.
- Word-overlap FTS5 pre-filtering returns a sufficient candidate set (content terms as FTS5 query). If false: fall back to a bounded full scan with LIMIT (degrade gracefully, not fail).
