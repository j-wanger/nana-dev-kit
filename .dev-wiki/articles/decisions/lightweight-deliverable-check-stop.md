---
title: Lightweight deliverable check at Stop
status: accepted
confidence: high
date: 2026-05-22
source: plan
tags: [hooks, enforcement, verification]
---

# Lightweight deliverable check at Stop

## Context

The Stop hook needs to verify phase exit criteria are being met, but full success-field re-execution (running test suites, builds, complex pipelines) risks latency and false positives. Need to balance enforcement rigor with developer experience.

## Decision

Stop hook (enforce-loop.sh) runs only file-existence exit criteria (`test -f`, `test -d`) extracted from `specs/<slug>.md`. It does NOT execute full success: field commands from tasks.md. Open tasks and debrief status are advisory (stdout) not blocking (exit 2).

## Rationale

- **Latency:** File-existence checks are <10ms. Test suites can be 5-30s. Stop hooks should not add noticeable latency.
- **False positives:** Test suites fail for many reasons (network, deps, flaky tests). Blocking on false positives erodes trust in enforcement.
- **Layered defense:** Full verification is already handled by task-level TDD cycle and dev-debrief. Stop hook is a lightweight checkpoint, not a replacement.
- **Advisory signals:** Open task counts and debrief reminders inform without blocking. Developer retains agency.

## Consequences

- Stop hook blocks ONLY on missing deliverable files (hard failures)
- Open tasks and missing debrief produce advisory stdout, not exit 2
- Full success-field verification remains at task completion (dev-wiki hooks discipline)
- Spec exit criteria should include file-existence checks to be Stop-verifiable

## Related

- [[layered-gate-enforcement-automated]] — tiered verification pattern (preventive + detective)
