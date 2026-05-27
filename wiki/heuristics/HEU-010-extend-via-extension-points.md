---
id: HEU-010
trigger: "adding functionality to a vendored or third-party dependency"
domain: architecture
source_phase: 29
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Extend Via Extension Points, Not Vendored Modification

## When this applies
A vendored or third-party dependency needs new functionality, and you have
access to its source code (vendored copy, fork, or writable package).

## Always
- Check for extension points first: APIs, hooks, plugins, CLI wrappers, MCP tools
- Build the new functionality at the extension layer, calling into the dependency
- Keep the vendored code as close to upstream as possible (near-zero divergence)
- Maintain a divergence inventory if any modifications are necessary
- Create surgical patches (not bulk modifications) for unavoidable changes

## Never
- Modify vendored code to add features when extension points exist
- Fork and diverge without documenting what changed and why
- Add features inline "because it's faster" — the merge cost compounds

## Why
Every modification to vendored code is a merge conflict waiting to happen.
When upstream improves, you must manually reconcile your changes with theirs.
Extension-layer solutions (skills, wrappers, API consumers) are orthogonal
to the dependency — upstream changes don't break them, and they can be
tested independently.

## Anti-pattern
"We already vendor it, so let's just edit the source" → Each edit increases
the divergence surface. After 5 modifications, you've effectively forked.
Upstream bugfixes become cherry-pick exercises. A skill/wrapper that calls
the existing API achieves the same functionality with zero divergence.

## Source
Phase 29: /memory-consolidate skill uses MCP tools (memory_search,
memory_store, memory_forget) instead of modifying vendored consolidator.py.
Phase 34: divergence inventory showed near-zero divergence (900 vs 903 lines)
with only _sanitize_fts_query differing — surgical patch maintained.
