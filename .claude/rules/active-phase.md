# Active Phase Context

Phase: 30 - Data-Driven Report Generators (ACTIVE)
Status: 0/4 tasks done
Objective: Update generate-report.py and generate-workflow.py to reflect 7-layer architecture, read from sources of truth, add Enforcement + Memory Bridge sections, staleness regression test, README fix.

Approach: Update in place. No new scripts or architectural changes. Content updates + light data-reading logic.

Tasks: 4 (1S + 2M + 1L)
1. [M] generate-report.py updates — LAYERS 5→7, categorize_files(), test_start counting, MANIFEST
2. [L] generate-workflow.py updates — 7-Layer subtitle, rewrite flows, Enforcement + Memory Bridge sections, dynamic hooks, MANIFEST
3. [M] Staleness regression test — test_templates.sh (depends 1-2)
4. [S] Final verify + README fix (depends 1-3)

Tests: 175 passing. Eval: 43/43.

Gates: [x] spec [x] approach [x] plan-review [x] tasks
