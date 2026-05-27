---
id: HEU-005
trigger: "applying expensive similarity checks or threshold logic to a large dataset"
domain: architecture
source_phase: 34
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Pre-Filter with Indexes Before Applying Business Logic

## When this applies
You need to apply expensive comparison logic (cosine similarity, fuzzy
matching, regex patterns) against a growing dataset where scanning
everything on every operation is O(n²).

## Always
- Use an index (B-tree, FTS5, KNN, bloom filter) to narrow candidates first
- Apply threshold logic (similarity > 0.9, overlap > 0.8) only on the narrowed candidate set
- Write baseline tests BEFORE optimizing (capture boundary values: 0.84, 0.86, 0.91)
- Verify that the optimization preserves exact threshold semantics

## Never
- Apply thresholds via full table scans when an index exists
- Skip baseline tests ("the optimization is obviously equivalent")
- Change threshold values and index strategy in the same commit

## Why
Separating query strategy (narrowing candidates) from decision logic
(thresholds) is the standard database optimization pattern. It converts
O(n²) to O(k) where k is the candidate set size. Critically, baseline
tests on boundary values ensure the optimization doesn't change behavior.

## Anti-pattern
"Just scan everything and filter" → Works at 100 entries. At 10,000, each
operation takes seconds. At 100,000, it's unusable. The fix isn't "optimize
later" — it's "design with indexed lookups from the start, because the
threshold logic is the same either way."

## Source
Phase 34: _find_near_duplicate optimized from O(n²) full table scan to
vec0 KNN LIMIT 50 (cosine path) and FTS5 MATCH LIMIT 50 (word-overlap path).
Boundary tests at 0.84/0.86/0.91 verified semantic equivalence.
