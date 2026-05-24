---
title: "Phase 30: Data-Driven Report Generators"
aliases: [data-driven-reports]
category: phases
tags: [reports, generate-report, generate-workflow, data-driven]
parents: []
created: 2026-05-23
updated: 2026-05-23
source: plan
status: completed
scope: ["scripts/generate-report.py", "scripts/generate-workflow.py", "tests/test_templates.sh", "docs/*", "README.md"]
entry_criteria: "Phase 29 complete, 175 tests passing, 43/43 eval"
exit_criteria: "Reports show 7-Layer, no stale strings (MEMORY.md, 5-Layer), Enforcement + Memory Bridge sections in workflow.html, staleness regression test in test_templates.sh, README numbers fixed"
---

# Phase 30: Data-Driven Report Generators

## Objective

Update generate-report.py and generate-workflow.py to reflect the current 7-layer architecture, read from sources of truth (settings.json, MANIFEST, test files) instead of hardcoded strings, and add missing documentation sections (Enforcement, Memory Bridge). Add staleness regression tests to catch future drift.

## Scope

- `scripts/generate-report.py` — LAYERS 5->7, WORKFLOWS v0.5.0, categorize_files() adds Eval/Specs, replace count_tests() with test_start counting, read MANIFEST
- `scripts/generate-workflow.py` — subtitle 7-Layer, rewrite 5 flows, add Enforcement + Memory Bridge sections with diagrams, parse settings.json hooks dynamically, read MANIFEST for template purposes, document global hooks
- `tests/test_templates.sh` — staleness regression test for report/workflow output
- `docs/report.html`, `docs/workflow.html` — regenerated output
- `README.md` — fix stale test counts

## Approach

Update in place. No new architectural decisions needed. Both generators are standalone Python scripts with no external dependencies beyond stdlib. Changes are content updates (hardcoded strings, section additions) plus light data-reading logic (MANIFEST parsing, settings.json hooks).

## Exit Criteria

- [ ] `! grep -q '5-Layer' docs/report.html && grep -q '7-Layer\|7 Layer' docs/report.html`
- [ ] `! grep -q 'MEMORY.md' docs/report.html`
- [ ] `! grep -q '5-Layer' docs/workflow.html && grep -q '7-Layer\|7 Layer' docs/workflow.html`
- [ ] `grep -q '<h[23].*[Ee]nforcement' docs/workflow.html && grep -q '<h[23].*[Mm]emory.*[Bb]ridge' docs/workflow.html`
- [ ] `grep -q 'report_staleness' tests/test_templates.sh && make test`
- [ ] `make eval` passes (43/43)
- [ ] README test/eval counts match reality

## Tasks

4 tasks (1S + 2M + 1L). See tasks.md Phase 30 section.

## Notes

No new decisions. Approach is update-in-place for existing generator scripts. Spec decisions from Phase 29 carry forward.
