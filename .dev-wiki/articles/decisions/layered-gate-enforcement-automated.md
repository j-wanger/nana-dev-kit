---
title: "Layered gate enforcement (automated)"
aliases: [gate-enforcement-automated, preventive-detective-gates]
category: decisions
tags: [process, enforcement, gates, compliance, audit]
parents: [phase-11-process-hardening]
created: 2026-05-19
updated: 2026-05-19
source: plan
confidence: high
---

## Context

Retro check across Phases 1-10 identified 3 user corrections, all process discipline failures (gate skipping, spec ceremony shortcuts). Gates existed as documentation but nothing enforced them — compliance was voluntary. The fail-open default in LLM pipelines means documentation alone is insufficient.

## Decision

Layered enforcement: preventive + detective. Two structural layers replace voluntary compliance:

1. **Pre-flight gate verification** (preventive) — implementation-guide.md parses active-phase.md Gates section and refuses to proceed if any gate is unchecked. Instructional enforcement at the agent-compliance boundary.
2. **Gate-compliance audit** (detective) — dev-debrief retro-check parses tasks.md gate log comments, verifies all expected gates for the ceremony level are logged, flags SKIPPED without justification.

Plus template-level reinforcement: session-start.sh emits a gate-check warning when unchecked gates exist, and regression tests assert the enforcement logic persists.

Alternatives rejected:
- **Documentation-only**: Proved insufficient across 10 phases — violations happened despite clear documentation.
- **Shell-level blocking**: Gates are process checkpoints (spec review, approach approval), not shell-verifiable preconditions. Cannot be enforced by bash conditionals.

## Consequences

- Agent must parse active-phase.md before implementing — adds ~1 tool call per session start.
- False refusal possible if active-phase.md is stale (mitigated by dev-plan always writing fresh gates).
- Audit trail in tasks.md gate comments becomes auditable history of gate compliance across all phases.
- Pattern mirrors "Tier 0 structural + Tier 1 semantic" review design from /spec skill.
