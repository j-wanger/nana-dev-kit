---
title: "Ceremony streamlining: 2-gate model"
aliases: [2-gate-model, ceremony-streamlining]
category: decisions
tags: [ceremony, gates, autonomous-flow, dev-plan, dev-debrief]
parents: [phase-37-ceremony-streamlining-autonomous-flow]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

The 4-gate ceremony (spec, approach, plan-review, tasks) adds synchronous human approval at each step. With 240 tests, 47/47 eval, and 36 completed phases of accumulated quality infrastructure, the cost-of-error for intermediate planning steps is low relative to the interruption cost. Human review should focus on direction (expensive to pivot) not details (cheap to fix).

## Decision

Reduce from 4 synchronous human approval gates to 2 boundary gates:

1. **Direction gate** (existing Step 7) — user confirms intent and scope before implementation begins.
2. **Delivery gate** (new) — agent generates HTML report before commit, user accepts/rejects.

Between these gates, the agent operates autonomously: spec creation, task planning, and implementation proceed without blocking on human approval. Subagent reviewers (approach, plan) still run as quality checks but results are incorporated automatically.

Rejected alternatives:
- **Incremental one-gate-at-a-time** — delivery report is the mitigation for removing other gates, must ship together.
- **Full removal (0 gates)** — directional misalignment is costly and hard to detect after the fact.

## Consequences

- Agent can complete a full spec-plan-implement cycle without human interruption.
- Delivery report becomes the primary human quality checkpoint — must be comprehensive.
- Risk: agent may pursue a suboptimal approach without early correction. Mitigated by delivery report allowing rejection before commit.
- Spec still runs (honors spec-always-mandatory), just without blocking approval.
- Gate log format changes from 4/5-gate to 2-gate model across enforcement infrastructure.
