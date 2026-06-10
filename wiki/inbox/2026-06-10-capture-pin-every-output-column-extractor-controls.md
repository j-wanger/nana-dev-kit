---
source_type: session
source_path: conversation
ingested: 2026-06-10T19:18:42
tier: private
---

# Raw: Pin every output column in extractor controls

## Context
nana-dev-kit Phase 86 built a transcript cost extractor with a hand-labeled positive control.
The control PASSED while one output column — subagent token recovery — was silently dead,
returning zero for all 44 dispatches (two distinct transcript marker forms both missed:
sync colon-form in tool_results, background XML-form in task-notifications).

## Insight
A positive control that does not pin EVERY output column certifies an instrument that is
partially dead — the registered-but-not-working failure class, extractor edition. The control
passed precisely because the dead column had no pinned expectation. Fix pattern: before bulk
processing, hand-pair per-row pins for each output column of the extractor, so any column
that silently degenerates to zero (or any constant) fails the control instead of shipping.

## Evidence
nana-dev-kit commit b7e7e0e: the dead column was discovered mid-task during table construction,
the extractor was fixed, and the control was STRENGTHENED to 13 checks with hand-paired
per-dispatch pins (e.g., total 906965, wiki-add 42363 excluded to implementation-other) plus an
unclassified-dispatch conservation check.
