---
title: "templates/.github/"
aliases: []
category: modules
tags: [github-actions, ci, templates]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: scan
type: module
path: "templates/.github/"
files: [templates-github-codeowners, templates-github-pull-request-template, templates-github-instructions-nana-instructions, templates-github-instructions-workflow-instructions, templates-github-workflows-ci]
external_deps: [actions/checkout@v4, astral-sh/setup-uv@v5, gitleaks/gitleaks-action@v2]
internal_deps: []
dependents: []
content_hash: "c72bffb31d2d9d45"
---

# templates/.github/

GitHub platform configuration templates including CI workflow, PR template with AI authorship disclosure, CODEOWNERS, and Copilot instruction files.

## Files

- [[templates-github-workflows-ci|workflows/ci.yml]] — CI workflow with 4 jobs: lint, typecheck, test, security
- [[templates-github-pull-request-template|PULL_REQUEST_TEMPLATE.md]] — PR template with AI authorship disclosure checkbox
- [[templates-github-codeowners|CODEOWNERS]] — Code ownership file with @your-team placeholder
- [[templates-github-instructions-nana-instructions|instructions/nana.instructions.md]] — Copilot instructions for nana conventions
- [[templates-github-instructions-workflow-instructions|instructions/workflow.instructions.md]] — Copilot instructions for workflow patterns

## Key Patterns

- CI has 4 parallel jobs (lint, typecheck, test, security) using uv-based Python toolchain
- PR template includes AI disclosure checkbox for responsible AI usage tracking
- CODEOWNERS uses placeholder @your-team for project customization

## Dependencies

**Internal:** None (deployed to target projects)

**External:** actions/checkout@v4 (CI), astral-sh/setup-uv@v5 (CI), gitleaks/gitleaks-action@v2 (CI security scanning)

## Dependents

None (standalone templates deployed to target projects)
