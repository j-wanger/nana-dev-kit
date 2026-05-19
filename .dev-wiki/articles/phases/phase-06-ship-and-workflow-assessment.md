---
title: "Phase 6: Ship & Workflow Assessment"
aliases: []
category: phases
tags: [ship, github, workflow, html, assessment, version]
parents: []
created: 2026-05-19
updated: 2026-05-19
source: plan
status: completed
scope: ["scripts/generate-workflow.py", "docs/workflow.html", "VERSION", "Makefile", "README.md", "docs/report.html"]
entry_criteria: "Phase 5 complete, all prior phases done"
exit_criteria: "Versioned workflow.html covers all flows/layers/hooks/templates/quality, all work committed, pushed to GitHub, tagged v0.2.0"
---

# Phase 6: Ship & Workflow Assessment

## Objective

Get the kit live on GitHub with a versioned HTML workflow breakdown for usability and build quality assessment.

## Approach

1. **Workflow breakdown generator**: Python script at scripts/generate-workflow.py → docs/workflow.html. Comprehensive single-page assessment: end-to-end flows, layer deep-dives, hook walkthrough, template inventory, quality signals, dependency map, memory/dev-wiki integration. Version-stamped from VERSION file.

2. **Version bump + report regeneration**: Bump VERSION to 0.2.0, regenerate both report.html and workflow.html.

3. **Ship to GitHub**: Two commits (Phase 5 work, Phase 6 work) for phase attribution. Push to GitHub remote, annotated tag v0.2.0. CI verification manual post-push.

## Scope

- `scripts/generate-workflow.py` -- new workflow breakdown generator
- `docs/workflow.html` -- generated output
- `docs/report.html` -- regenerated with new version
- `VERSION` -- bump to 0.2.0
- `Makefile` -- add `make workflow` target
- `README.md` -- add `make workflow` mention

**NOT in scope:** kit code changes, new features, refactoring. Ship + document only.

## Tasks (3 total: 1M + 2S)

1. **[M]** Create workflow breakdown generator + README update
2. **[S]** Bump version to 0.2.0 + regenerate reports
3. **[S]** Commit + push to GitHub + tag v0.2.0

## Exit Criteria

- [ ] Versioned workflow.html at docs/workflow.html covering all flows, layers, hooks, templates, quality signals
- [ ] All Phase 5 + Phase 6 work committed
- [ ] Pushed to GitHub remote
- [ ] Tagged v0.2.0
- [ ] README mentions `make workflow`
