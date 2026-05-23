---
title: "Spec routing investigation"
aliases: [spec-routing, skill-routing-failure]
category: decisions
tags: [spec, routing, skill-discovery, claude-code]
parents: [phase-18-spec-devplan-ux]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

/spec routing was reported as broken across 4+ phases: "skill listed in available skills but not recognized as command." This was an open blocker since 2026-05-21. Phase 18 included investigating the root cause.

## Decision

The routing failure is a **Claude Code platform behavior**, not a nana-dev-kit configuration issue.

Investigation findings:
- `~/.claude/skills/spec/SKILL.md` is correctly installed with proper frontmatter (`name: spec`, valid description)
- The skill appears in the available-skills list in session system prompts
- Agent-side invocation via `Skill(skill="spec")` works reliably (confirmed in Phase 18 session)
- User-side `/spec` typing depends on Claude Code's skill discovery and routing, which has been intermittent

The auto-invocation approach (dev-plan calls `Skill(skill="spec")` when no spec exists) bypasses the user-side routing entirely. This makes the routing issue a non-blocker for the primary use case.

No code change in nana-dev-kit can fix user-side skill routing — it's a platform responsibility. If the issue recurs, users can rely on dev-plan's auto-invocation for the spec→plan flow.

## Consequences

- /spec routing blocker is **resolved by mitigation** (auto-invocation), not by fixing the root cause
- The open blocker in _CURRENT_STATE.md can be closed
- If Claude Code fixes the platform-side routing, user-side `/spec` will work as a standalone command in addition to auto-invocation
- No install.sh or SKILL.md changes needed for routing specifically
