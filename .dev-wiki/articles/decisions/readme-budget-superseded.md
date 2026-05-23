---
title: "README budget superseded: 58 -> 90-100 lines"
aliases: [readme-budget-superseded]
category: decisions
tags: [readme, documentation]
parents: [phase-23-bug-fixes-readme]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

The prior README target (~58 lines, decision [[readme-concise-format]]) was set when the kit had 4 skills. The tool has grown 4x since then: 22 skills (dev-wiki lifecycle, knowledge-wiki, spec, py-init), enforcement hooks (3 global hooks), eval harness (38 scenarios), memory bridge (3 channels), and modular installer with flags. The current README underdocuments the tool's capabilities.

## Decision

Supersede the ~58-line budget with a 90-100 line budget and 7-section structure: overview, install, what you get, skills table, enforcement/eval, memory, and contributing/license. This is a full rewrite, not an incremental patch.

Alternative considered: keeping the concise format with a link to detailed docs. Rejected because there are no detailed docs -- self-test.md is the only reference and it's a test spec, not user documentation.

## Consequences

- README grows from ~55 to ~95 lines
- [[readme-concise-format]] is superseded but not deleted (historical record)
- test_templates.sh README line-count assertion updated to allow 70-120 range
