# Active Knowledge
# userEmail
The user's email address is wang.jan.tried@gmail.com.
# currentDate
Today's date is 2026-05-19.

# Phase 6 Key Facts

## Workflow Breakdown
- Generator script: scripts/generate-workflow.py (new)
- Output: docs/workflow.html (generated, single-page, versioned)
- Different from docs/report.html (package inventory) — this is a workflow assessment
- Content: end-to-end flows, layer deep-dives, hook walkthrough, template inventory, quality signals
- Makefile target: make workflow

## Version & Ship
- Bump VERSION from 0.1.0 to 0.2.0
- Two commits: Phase 5 (venv bootstrap + report), Phase 6 (workflow + version bump)
- Push to GitHub remote, tag v0.2.0
- CI verification manual post-push
