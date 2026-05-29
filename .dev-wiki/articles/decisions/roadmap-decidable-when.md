---
title: "Every deferred roadmap item carries a canonical decidable-when: line"
aliases: ["roadmap-decidable-when", "decidable-when-line", "roadmap-not-a-backlog"]
category: decisions
tags: [roadmap, deferral, decidability, eval-validity, process]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: medium
---

## Context

The 58/59/61 phases each ended with deferred open questions ("untested on novel topics," "re-test if the store grows past the cap," "judge inter-run variance"). These accumulate as a backlog of the same stuck decision — re-derived each phase, never resolved — because nothing states the observable that would make them decidable. A remediation roadmap that just lists "consider X later" reproduces the stuck cycle this phase exists to break.

## Decision

Every deferred remediation item in the Phase-63 roadmap must carry a canonical `decidable-when:` line stating the observable that resolves it ("becomes a clear cut / clear build when X observable holds"). An item without a `decidable-when:` line is not roadmap-ready. The roadmap's item count (`grep -c '^- '`) must equal its `decidable-when:` count — every item has exactly one, none gamed by repetition. Confidence is medium: the discipline is sound, but whether a crisp observable can always be named for every deferred item (some are genuinely open research questions) is the part most likely to bend in practice.

## Consequences

Deferral becomes a commitment to a future trigger rather than an open-ended punt: Phase 64+ can scan the roadmap and act on any item whose observable now holds. The standing 58/59/61 open questions get retrofitted with `decidable-when:` lines where possible (e.g. "re-test D2 memory overflow when the MCP store exceeds the 100-entry hot-cache cap with valuable distinct entries"). Items that genuinely cannot name an observable surface as such — that itself is information (an unfalsifiable deferral is a flag, not a roadmap entry).
