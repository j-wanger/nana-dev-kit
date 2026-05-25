---
title: "Spec --internal mode"
aliases: [spec-internal, internal-spec]
category: decisions
tags: [spec, ceremony, autonomous-flow]
parents: [phase-37-ceremony-streamlining-autonomous-flow]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

The spec skill produces valuable quality artifacts and audit trail. The spec-always-mandatory memory entry (confirmed across multiple sessions) establishes that spec should never be skipped. However, in the 2-gate model, the spec approval step (Step 5 user review) blocks autonomous flow between direction and delivery gates.

## Decision

Add `--internal` mode to spec SKILL.md. When invoked with `--internal`:
- Auto-run Steps 2-4 and Tier 0/1 quality checks.
- Incorporate findings automatically (no user block).
- Persist with marker.
- Skip Step 5 user approval.

Direct `/spec` invocation remains unchanged — full interactive flow with user approval.

Rejected alternatives:
- **Remove spec entirely** — violates spec-always-mandatory.
- **Make spec conditional on phase size** — loses quality value even on small phases.

## Consequences

- Spec artifacts still exist for audit trail and delivery report.
- Quality checks (Tier 0 structural lint, Tier 1 semantic review) still run.
- Human review of spec quality shifts to delivery report stage.
- ~15 lines added to spec SKILL.md; must stay within 160-line budget.
