---
title: "Companion file for spec auto-invocation"
aliases: [spec-auto-invoke-companion, companion-file-auto-invoke]
category: decisions
tags: [spec, dev-plan, companion-file, ux]
parents: [phase-18-spec-dev-plan-ux-unification]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

Phase 18 needs dev-plan Step 0.6 to auto-invoke /spec when no spec exists, replacing the current STOP block. The auto-invocation logic requires: user notification, Skill tool invocation, three terminal states (approved/rejected/failed), and a restart protocol to re-enter planning with the new spec. dev-plan SKILL.md is at 338/350 lines with only 12 lines of headroom.

## Decision

Use a companion file `spec-auto-invoke.md` (~30-40 lines) referenced from SKILL.md Step 0.6. Step 0.6 becomes a ~3-line pointer replacing the current STOP block. The companion defines the full auto-invocation protocol: notification, Skill tool call, terminal states, and restart instructions.

Alternative considered: inline the logic directly in SKILL.md. Rejected because 12-line headroom is too fragile for the required terminal-state logic, notification text, and restart protocol. Companion files are the established pattern in the codebase (approach-reviewer-prompt.md, plan-reviewer-prompt.md, adversarial-constraints-prompt.md all follow this convention).

## Consequences

- SKILL.md gains ~3 lines (net reduction from STOP block removal), staying well under 350-line ceiling.
- New file `spec-auto-invoke.md` must be copied by install.sh (added to dev-wiki module group).
- Future modifications to auto-invocation behavior are isolated to the companion file without touching the main SKILL.md orchestration.
- Pattern consistency: this is the 4th companion file in the dev-plan/spec skill family.
