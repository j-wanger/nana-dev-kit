---
title: "Personal profile template for shipping"
aliases: [personal-template, nana-personal-template]
category: decisions
tags: [install, personal, template, shipping]
parents: [phase-13-final-polish-and-ship]
created: 2026-05-20
updated: 2026-05-20
source: plan
confidence: high
---

## Context

nana-personal.md in templates/ contains Jake-specific content (name, domain, thinking patterns). The kit ships as a public template; personal identity should not be baked in. Users who already have a personal profile should not have it overwritten on re-install.

## Decision

Make templates/.claude/rules/nana-personal.md a generic placeholder with guidance for users to fill in their own profile. Update install.sh to conditionally copy (skip if user already has one at ~/.claude/rules/nana-personal.md). Jake's expanded 7-line profile lives locally only.

Alternative rejected: interactive install prompt asking for name/domain (adds install.sh complexity for minimal gain). Alternative rejected: defer to Phase 14 (shipping requires this now -- personal content in a public template is a blocker).

## Consequences

Shipped kit contains no personal identity. Existing users keep their profile on re-install (idempotent). New users get a template they can customize. Jake's profile must be maintained separately from the repo.
