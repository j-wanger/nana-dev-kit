---
title: "Delivery report before commit"
aliases: [delivery-report, pre-commit-report]
category: decisions
tags: [delivery, dev-debrief, ceremony, report]
parents: [phase-37-ceremony-streamlining-autonomous-flow]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

With intermediate gates removed (2-gate model), the delivery gate is the sole human quality checkpoint before changes land. The timing of report generation (before vs after commit) determines the cost of rejection.

## Decision

Generate the delivery report BEFORE commit. The report reads git diff, tasks.md, decision articles, and runs make test/eval to produce an HTML summary. User reviews the report and accepts, rejects, or requests fixes. Only after acceptance does auto-commit + push proceed.

Rejected alternative:
- **After commit** — cheaper to produce from real diff, but rejections require reverts, adding complexity and risk.

## Consequences

- Agent can fix issues before they land — no revert complexity.
- Report must work from staged/unstaged changes rather than committed diff.
- User reviews output (working code + test results), not plan (speculative).
- Auto-push only proceeds after explicit user acceptance.
- New script: `scripts/generate-delivery-report.py` (~200-300 lines).
