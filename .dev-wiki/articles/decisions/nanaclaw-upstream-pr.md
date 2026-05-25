---
title: "Nanaclaw Upstream PR: _sanitize_fts_query Fix"
aliases: [nanaclaw-pr, t6-pr, upstream-sync-pr]
category: decisions
tags: [nanaclaw, upstream, pr, sync, phase-36, t6]
parents: [phase-36-hooks-audit-housekeeping]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Phase 36 Task 6 deliverable: submit the char-level FTS5 sanitizer fix from `patches/nanaclaw-sanitize-fts.patch` upstream to `https://github.com/j-wanger/nanaclaw`. Fix originated in nana-dev-kit (Phase 33) and provides recall improvement on technical queries containing FTS5 special characters.

## Decision

PR submitted: **https://github.com/j-wanger/nanaclaw/pull/1**

- **Branch:** `fix/fts-sanitizer-special-chars` on `j-wanger/nanaclaw`
- **Base:** `main`
- **Commit:** `82cb100` (single commit, signed by Jake Wang <wang.jan.tried@gmail.com>)
- **Files changed:** `memory_server/storage.py` only (4 insertions, 2 deletions, zero `nana-dev-kit/` paths — spec exit criterion #8 verified pre-push)

## Workflow used

1. `git clone --depth 5 https://github.com/j-wanger/nanaclaw /tmp/nanaclaw-upstream`
2. `git checkout -b fix/fts-sanitizer-special-chars`
3. Manual edit of `memory_server/storage.py` `_sanitize_fts_query` function (4 line change; `import re` already at module scope upstream)
4. Commit with descriptive message documenting old vs new behavior, known limitation (`C++` → `C`), and OR-join preservation
5. Pre-push verification: `git log --name-only origin/main..HEAD` confirmed 1 commit, only `memory_server/storage.py`
6. `git push -u origin fix/fts-sanitizer-special-chars` (gh CLI authed as `j-wanger`)
7. `gh pr create --base main --head fix/fts-sanitizer-special-chars` with summary + test plan body

## Notes

- The kit's local `patches/nanaclaw-sanitize-fts.patch` was NOT used directly — it has stale `/tmp/` absolute paths that `git apply` rejects. The 4-line change was small enough to hand-apply. Future patches should use `git format-patch` output for direct `git am` compatibility.
- Per dev-plan checkpoint, PR is not closed or modified autonomously — Jake reviews/merges on his own timeline.
- If accepted: kit's vendored `memory_server/storage.py` and upstream converge. Future re-sync from nanaclaw will not need this patch.
- If rejected or unmerged: kit retains the patch file as a local divergence record.
