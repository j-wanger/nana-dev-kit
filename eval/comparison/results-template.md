# Harness Effectiveness — Results

> Date: 2026-05-26
> Model: Claude Opus 4.6 (1M context)
> Claude Code version: CLI session + subagents
> Run: Clean (no implementation leakage from C into A/B prompts)

## Quality Metrics

## SWE-bench Task: django__django-16263

**Task:** Strip unused annotations from Django ORM `count()` queries.
**Difficulty:** 1-4 hours (SWE-bench Verified "hard" subset)
**Gold patch:** 4 files modified (expressions.py, query_utils.py, query.py, where.py)
**Evaluation:** 3 fail-to-pass tests + 1 regression test (applied post-hoc)

### Verified Results

| Metric | A (Baseline) | B (Context) | C (Full Harness) |
|--------|:---:|:---:|:---:|
| **Acceptance tests** | 3/4 | 3/4 | **4/4** |
| **Regression suite** | 738/739 | 738/739 | **739/739** |
| **Total tokens** | 149,541 | 120,875 | ~200K+ (est.) |
| **Tool calls** | 180 | 132 | ~60+ |
| **Duration** | 22m 35s | 18m 17s | ~45 min |
| **Lines added** | +143 | +90 | +110 |
| **Files modified** | 1 | 1 | 1 |

### Acceptance Tests Detail

| Test | A (Baseline) | B (Context) | C (Full Harness) |
|------|:---:|:---:|:---:|
| `test_non_aggregate_annotation_pruned` | PASS | PASS | PASS |
| `test_unreferenced_aggregate_annotation_pruned` | **FAIL** | PASS | PASS |
| `test_unused_aliased_aggregate_pruned` | PASS | **FAIL** | PASS |
| `test_referenced_aggregate_annotation_kept` | PASS | PASS | PASS |

### What Each Condition Got Wrong

**A failed `test_unreferenced_aggregate_annotation_pruned`**: Fully removed aggregate annotations (including their joins) instead of keeping them for GROUP BY. The test expects a subquery (2 SELECTs) with the aggregate masked from SELECT; A produced no subquery (1 SELECT). Too aggressive.

**B failed `test_unused_aliased_aggregate_pruned`**: Kept aliased aggregates in `existing_annotations`, triggering a subquery. The test expects no subquery (1 SELECT) because `.alias()` aggregates can be fully removed. Too conservative.

**C passed both**: Implemented 3-tier pruning — non-aggregates fully removed, selected aggregates masked, aliased aggregates fully removed. Reached this through 4 iterations of test-fix-test.

### Regression Analysis

Both A and B's sole regression IS the failed acceptance test — no pre-existing Django tests were broken. All three conditions produced correct implementations for the cases they handled; they differ only on the aggregate/alias boundary.

## Observations

### 1. All three conditions independently solved the core problem

Each agent read the codebase, identified `get_aggregation()`, understood the annotation mechanism, and implemented reference detection + pruning. The same high-level architecture emerged independently: walk expression trees for Ref/identity refs → transitive closure → prune.

### 2. The aggregate/alias boundary is the hard edge case

The distinction between "keep aggregate for GROUP BY" and "fully remove aliased aggregate" requires understanding that:
- `.annotate(x=Count(...))` adds joins that inflate row counts → must keep for subquery GROUP BY
- `.alias(x=Count(...))` also adds joins → but since it's not selected, can be fully removed WITH join cleanup

A was too aggressive (removed everything). B was too conservative (kept everything with `contains_aggregate`). C found the middle ground through iteration.

### 3. Context injection (B) was more token-efficient but didn't improve quality

| | A | B | Delta |
|---|---|---|---|
| Tokens | 149,541 | 120,875 | B used 19% fewer |
| Duration | 22m 35s | 18m 17s | B was 19% faster |
| Tool calls | 180 | 132 | B used 27% fewer |
| Acceptance | 3/4 | 3/4 | Same score |
| Lines | +143 | +90 | B was more concise |

B was consistently more efficient (fewer tokens, faster, more concise code) but achieved the same acceptance score. The soul/rules files may have encouraged a more focused approach, or this could be stochastic variance.

### 4. Interactive iteration is what separates 3/4 from 4/4

C's advantage was not hooks, skills, or memory — none were exercised on this Django task. C's advantage was **4 rounds of test-driven debugging**:

1. First attempt: too aggressive (like A) → 2 regression failures
2. Added base-table check → fixed but missed `values_select`
3. Added `has_select_fields` check → fixed but mask=None crash
4. Fixed mask=None + 3-tier distinction → all pass

Neither subagent had this iterative opportunity. Both got their single-pass implementation to 3/4 — the 4th test required debugging that only happens with test feedback.

### 5. Token cost of the last 25% quality

| Quality level | Cheapest path | Tokens |
|---|---|---|
| 3/4 acceptance, 0 pre-existing regressions | B (single pass) | 120,875 |
| 4/4 acceptance, 0 regressions | C (interactive) | ~200K+ |

The last acceptance test costs roughly 80-100K additional tokens — spent on iterative debugging rather than initial implementation.

## Conclusions

1. **The interactive session (C) is the only condition that achieved 4/4.** The advantage is iterative debugging, not harness tooling.

2. **Context injection showed no quality improvement.** B scored 3/4 same as A, with a different failure. B was more token-efficient (19% fewer tokens) but this could be variance.

3. **Both subagents produced strong partial solutions.** 3/4 acceptance with zero pre-existing regressions is a solid result for single-pass execution on a hard SWE-bench task.

4. **The hardest part is the boundary between pruning strategies.** All three conditions solved reference detection and basic pruning. Only the interactive session navigated the aggregate vs aliased-aggregate distinction correctly, through trial and error.

5. **For harness effectiveness validation**, this task doesn't exercise the harness's unique features (hooks, skills, enforcement, memory). A proper test would use a nana-dev-kit Python project where py-lint, py-review, dev-plan, and enforcement hooks are active.
