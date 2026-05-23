---
title: "Test missing-tool fallback paths only in eval"
aliases: [eval-missing-tool-fallback-only]
category: decisions
tags: [eval, hooks, external-deps, fallback, ci]
parents: [phase-21-eval-expansion]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

Three hooks depend on external tools: auto-ruff-format.sh requires ruff (via uv), scan-secrets.sh requires gitleaks, and check-tests-were-run.sh requires python3. Eval scenarios could test both the tool-present and tool-absent code paths, but requiring these tools in the eval environment would reduce portability.

## Decision

Test missing-tool code paths (graceful skip/fallback) for hooks with external dependencies. Do NOT require those tools in the eval environment. Rationale: eval must run on any machine with bash+jq; graceful skip is the realistic CI path. The tool-present paths are validated by the tools' own test suites and by integration use.

Alternative considered: require tools in eval env and test both paths. Rejected because eval portability is a hard constraint -- adding tool installation to eval setup defeats the "run anywhere" design.

## Consequences

Eval scenarios for auto-ruff and scan-secrets test the "tool not found" exit path (exit 0, no crash). If a developer has these tools installed, the hooks still work -- but eval doesn't validate that path. This is acceptable because the hooks' graceful-skip logic is the more failure-prone code path that benefits from eval coverage.
