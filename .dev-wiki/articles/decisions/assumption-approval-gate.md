---
title: "Assumption-Approval Gate (Phase 81)"
aliases: ["assumption-approval-gate", "phase-81-assumption-gate", "assumption-gate"]
category: decisions
tags: [assumption-interrogation, gate, ledger, naive-surfacer, all-accept, dont-know, cost-of-error, mandatory-over-advisory, dogfood]
parents: [phase-81-assumption-approval-gate]
created: 2026-06-09
updated: 2026-06-09
source: plan
confidence: high
status: active
---

# Assumption-Approval Gate (Phase 81)

## Context
The earned consequence of Phase 80's `^PROGRAM-VERDICT: INSTRUMENT-DEAD`
([[assumption-surfacer-completeness-screen]]). Phase 80 screened whether an elaborate scope-anchored
"surfacer" beats a naive baseline at recovering load-bearing assumptions; the clean-context control
FAILED — the workflow subagents ran inside nana-dev-kit and inherited always-loaded `working-knowledge.md`
documenting the fixtures' buried assumptions, so the SURFACER *leaked* them (4/5, 5/5, 5/5 on documented
cases, 0/5 on the 2 invented). The leak IS the amplifier-null caught in the act (the 5th null). The clean
signal that survives points **DEGENERATE**: a naive "list the load-bearing assumptions, cost-sorted"
prompt recovered 3/4 silent-class assumptions by pure reasoning — the project's silent failures were
silent because nobody **ASKED** at planning time.

The Phase-80 plan was itself interrogated through this mechanism (the gate eating its own dogfood). Jake's
live verdicts: **A1** engagement → accept; **A2** surfacing-trust → **reject** ("can't trust the
agent-CHOSEN assumption set; solve set-completeness first" — what made Phase 80 a SCREEN not a build);
**A3** ledger → accept (conditional on a debrief forcing-function); **A4** substrate → accept. Three
direction-gate decisions shaped *this* plan: **Q1** positions REPLACE the approval click; **Q2**
all-accept → warn + track + restate (NOT a hard block); **Q3** build the ledger now. See
[[HEU-012]] (mandatory-over-advisory: verify a mechanism FIRES, not that its file exists).

## Decision
Ship the **simplest** gate (the screen's FORWARD recommendation), NOT the scope-anchored machinery whose
only apparent edge was the leak. Four components:

1. **Naive surfacer in dev-plan** — the frozen Phase-80 NAIVE prompt; 3–6 cost-sorted load-bearing
   assumptions; Step-10 T0's single weakest assumption MUST appear as one member of the set (a consistency
   check, regenerate if absent — it is the SINGLE surfacer, not a second list).
2. **Positions accept / reject / don't-know** via AskUserQuestion — positions ARE the gate (no separate
   approval click). reject → revise + re-surface; don't-know → agent defends with evidence or down-scopes
   to drop the dependency, then re-presents, else a deferred don't-know routed to the phase-article
   Blockers + flagged must-revisit (never a silent pass). No unresolved reject/don't-know = direction
   confirmed.
3. **All-accept handling** — warn + track `all_accept: true` in the ledger + restate how each accepted
   assumption shapes the approach. NOT a hard block (Jake's Q2 choice); the mandatory bite is the
   always-fired restatement + cross-phase tracking ([[HEU-012]]-compliant).
4. **Append-only cross-phase ledger** `.dev-wiki/assumption-ledger.md` + a dev-debrief revisit-status
   forcing-function + a deterministic NO-LLM check (`scripts/check-assumption-ledger.sh`) enforced at
   debrief finalization. NO new hook — the debrief-finalization check is the firing point; a session-start
   advisory is deferred.

The gate **REPLACES** the approach-approval step (Step 13 + the Step-15f Gates template are rewritten so
positions are the sole pre-implementation gate), not a second gate bolted on. Value is the human
role-change (rubber-stamp → interrogator), NOT amplification.

## Consequences
- **Efficacy is UNMEASURABLE in-kit** (the amplifier-null + Ph66/69/80 representativeness — you cannot
  measure clean-context surfacing inside the project whose always-loaded `working-knowledge.md` documents
  the answers). Tests assert MECHANICS only (gate writes positions, ledger appends, revisit-status
  enforced); no measured quality delta is claimed.
- The gate's value collapses if all-accept becomes routine — component-3 tracking surfaces that over phases.
- The ledger is **append-only** in `.dev-wiki/` to survive section-rewriting skills; its firing evidence is
  the ledger row ([[HEU-012]]: verify firing, not presence) — the gate is an LLM-executed skill step (no
  exit code), so the row, not the prose, is what the deterministic check asserts on.
- Reviewer hardenings adopted: REPLACE-not-augment asserted (Step 13 + Step-15f Gates template rewritten);
  every new companion carries `parent`/`referenced_at` frontmatter (test_companions); the debrief revisit
  re-scans prior-phase unrevisited rows (later-phase bite caught — the cascade pattern); ONE documented
  ledger-schema source referenced by both skills + the check; append-only + monotonic-row corruption guard.

## Rejected Alternatives
- **The elaborate scope-anchored / framing machinery** — Phase-80 leak artifact, no clean value.
- **A HARD all-accept block** — Jake chose warn + track + restate.
- **A new session-start advisory hook for unrevisited rows** — deferred (subtraction test; the
  debrief-finalization check is the firing point). Re-trigger: debrief-skip leaves rows undetected.
- **Auto-mutating a linked decision's confidence when an assumption bites** — debrief SURFACES the
  suggestion; the maintainer decides.

## Source
[[assumption-surfacer-completeness-screen]], [[HEU-012]]
