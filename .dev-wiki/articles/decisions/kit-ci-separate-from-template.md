---
title: "Kit CI separate from template"
aliases: [kit-ci.yml, kit CI workflow, separate CI]
category: decisions
tags: [ci, github-actions, shellcheck]
parents: [phase-03-distribution-and-polish]
created: 2026-05-15
updated: 2026-05-15
source: plan
status: accepted
confidence: medium
---

## Context

The kit needs its own CI workflow, but `templates/.github/workflows/ci.yml` already exists as a Python CI template for scaffolded projects. Using the same path would conflate the kit's own CI with the template it distributes. Options considered: (1) kit CI at `.github/workflows/kit-ci.yml` (distinct path), (2) kit CI at `.github/workflows/ci.yml` (same path as template).

## Decision

Kit's own CI lives at `.github/workflows/kit-ci.yml`, distinct from `templates/.github/workflows/ci.yml`. The workflow runs shellcheck on all .sh files and `make test`, triggered on push and PR to main. shellcheck is CI-only (available on ubuntu-latest), not a local dependency, preserving the zero-dependency principle.

Same-path was rejected because it creates confusion between the kit's CI and the Python CI template distributed to scaffolded projects.

## Consequences

- Clear separation between kit infrastructure and template content
- shellcheck linting without adding a local dependency
- Developers can run `make test` locally; shellcheck runs only in CI
- Two distinct CI files in the repo (one at root `.github/`, one in `templates/.github/`) with different purposes
