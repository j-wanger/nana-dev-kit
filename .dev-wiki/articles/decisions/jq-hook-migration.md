---
title: "Migrate 6 hooks from python3 -c to jq"
aliases: [jq-hook-migration]
category: decisions
tags: [hooks, jq, performance, dx]
parents: [phase-24-dx-hook-performance]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

Six hooks use `python3 -c` for JSON parsing on stdin: audit-log, auto-ruff-format, block-dangerous-bash, scan-secrets, enforce-spec, and check-tests-were-run. Python startup adds ~40-60ms latency per hook invocation. jq is already a hard dependency for the eval runner (decision: eval-jq-hard-dependency) and starts in <5ms. detect-loop.sh (pure bash, <50ms budget per decision: pure-bash-loop-detection) and wk-prune.sh (no JSON parsing) are explicitly excluded.

## Decision

Replace `python3 -c` with `jq -r` in all 6 hooks. Add a jq fail-open guard (`command -v jq >/dev/null 2>&1 || exit 0`) to audit-log.sh and block-dangerous-bash.sh (the two hooks where a missing-jq failure would be most disruptive). The other 4 hooks either already require jq transitively or are non-critical advisory hooks.

## Consequences

- Hook latency drops ~40-60ms per invocation (python3 startup eliminated).
- jq becomes a runtime dependency for hooks, not just eval. README must document this.
- install.sh Getting Started output should mention jq requirement.
- detect-loop.sh remains pure bash (performance budget); wk-prune.sh remains unchanged (no JSON).
- Eval corpus must still pass 100% after migration.
