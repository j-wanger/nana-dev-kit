---
title: "Assumption-gate direction filter — assumptions must be falsifiable, not direction restatements"
aliases: [assumption-gate-direction-filter]
category: decisions
tags: [dev-plan, assumption-gate, comply-in-form, forcing-function, fable-5]
created: 2026-06-13
updated: 2026-06-13
source: debrief
confidence: high
---

## Context

signal-watch dogfood (Jake's recurring correction — raised once before after fable→opus, where it worked that session but did NOT persist): the dev-plan assumption-approval gate degenerated back into "approve the approach? → blind yes" — opus surfaced direction/approach CHOICES dressed as assumptions, which the maintainer can't meaningfully reject. Root cause: `assumption-gate.md` Surfacing defined a load-bearing assumption as "the plan's outcome would change were it false" — a test that DIRECTION CHOICES satisfy ("we should use Y" → if false, the outcome changes), with no filter excluding them. Same comply-in-form class Phase 90 ([[fable-distillation-round]]) targeted; the gate's own degeneration Phase 90 missed.

## Decision

Add a checkable **"assumption, not direction"** filter to `assumption-gate.md` Surfacing (run before the gate). A load-bearing assumption is a belief about something the agent does NOT control — a domain fact, the maintainer's intent, an infrastructure reality — that the plan takes on faith and could be FALSE; NOT a restatement of the chosen approach. **Checkable test:** write "If this is FALSE, then [specific breakage]"; if the negation is incoherent or the only consequence is "then I'd have picked a different approach," it is a DIRECTION CHOICE → drop it. The maintainer's verdict adjudicates a fact the agent LACKS (what a `don't-know` marks), never blesses a decision the agent MADE. Inline ✗/✓ example pair. Shipped as a checkable forcing-function (Phase-90 lesson: a test, not vibey prose), both-landings (global `~/.claude` + `templates/`) + MANIFEST regen + the 4 synced consuming projects; signal-watch inherits via global. Feedback persisted to memory ([[assumptions-not-direction-restatements]]).

## Consequences

Efficacy is unmeasurable in-kit (ships on judgment); the real verdict is the next signal-watch `/dev-plan`. The most-likely-wrong claim: it's still an instruction, and opus can comply-in-form even with checkable rules — if the filter still degenerates, the heavier fix is a **clean-context surfacing subagent** (surface assumptions from an agent that never sees the chosen approach → structurally can't restate it; the B2 move Phase 90 staged). Logged as a Phase-90 follow-on hotfix (commit 9309fe0), not a new phase. Refines [[assumption-approval-gate]] (Phase 81) — the surfacing step it left under-specified.
