---
title: "Phase 95 complete — Memory-Layer Disposition (Reconcile-and-Close)"
aliases: [2026-06-21-phase-95-memory-layer-disposition-complete]
category: journal
tags: [memory, disposition, enforce-memory, hook-redesign, det-vs-llm, transcript-forensics, trim-trial, ultracode]
parents: [phase-95-memory-layer-disposition]
created: 2026-06-21
updated: 2026-06-21
source: debrief
duration: ~one long session (plan -> implement -> deliver, single sitting)
---

# Phase 95 complete — Memory-Layer Disposition

## What Happened
- The disposition the Phase 92->94 arc was built toward. Phase 94 REVERSED the demand-zero premise,
  so Phase 95 became **reconcile-and-dispose-then-close** (not the cut apparatus the superseded
  `specs/phase-92-memory-layer-prune.md` drafted): adjudicate EVERY open memory-layer obligation to one
  recorded, evidence-cited verdict; keeps are valid. 4/4 tasks; run-exit-criteria 12/12; make test PASS;
  make eval 50/50 (denominator unchanged); drift 0. Shipped 3d401d5 + b960c70 (delivery accepted, pushed).
- **Verdicts:** memory-mcp-layer KEEP (Phase-94 reversal); bridge-writer + harvest-writer KEEP-by-affirmation
  (direction-gate A3 reject of a fresh kit-side audit — consumer reversal + cheapness suffice; evidence-split
  asymmetry: consumer evidence may KEEP a kit-side writer but not CUT one); enforce-memory REDESIGNED;
  ak-ride-along (d43950f) + wk-seeding (df3e623) trim-trials CONFIRMED permanent (windows clean, zero triggers).
- **The one code change — enforce-memory redesign (T3 maintainer checkpoint call):** replaced the gameable
  agent-touched `.claude/.memory-consulted` marker (an EXISTENCE check, not consultation) with a transcript
  assertion of a REAL `type==assistant` `tool_use` `memory_search` whose `ts >= ~/.claude/.session-start-ts`
  (det-vs-LLM Principle 2 — assert the artifact, not the narration; the session-start bound gives per-session
  freshness). jq-only (the deferred-tool catalog is excluded by the type gate, never grep), fail-open. PreToolUse
  delivers `transcript_path` (confirmed; 600s timeout); the scan is 64ms on a 4.1MB transcript. Test-first (5 paired
  smokes incl. a stale-pass freshness guard), survivor smoke PASS on the live installed hook, installed copy synced.
- **Backlog cleared:** Phase 95 closed a stack of long-deferred obligations — ledger Phase-83 A5 (open->held),
  Phase-88 A4/A6 (memory-layer + writers), both trim-trial re-triggers, the Phase-83 enforce-memory
  keep-with-revisit, and the enforce-memory resume-artifact harden-candidate (the redesign's session-start-ts
  bound FIXES the resume stale-pass). The "close every open obligation" frame paid off as a backlog sweep.

## Decisions Made
- [[memory-layer-disposition|Memory-Layer Disposition (Phase 95)]] (high) — updated with the final
  redesign outcome (the plan-time article had enforce-memory PENDING the checkpoint).

## Health Delta
- Tests: +5 enforce-memory redesign tests (tests/test_tooluse_hooks.sh) + 3 firing-log block tests moved to
  the transcript contract (tests/test_firing_log.sh). make test PASS, no regressions.
- Eval: hook-enforce-memory-{allow,block} scenarios moved to the transcript contract; denominator UNCHANGED
  at 50/50. Firing reasons: memory-consulted -> memory-searched (allow) + no-transcript (fail-open allow).
- New apparatus: `eval/memory-disposition/` (verdict-table, run-exit-criteria with --selftest, tally-firing.py,
  spike-probe.sh, enforce-memory-audit.md, redesign-spike.md). Kit code touched: ONLY enforce-memory.sh
  (modules.json + settings.json unchanged — the event didn't change, only the gate logic).

### Review Gate (the adversarial verification — it earned its keep, twice)
Ultracode multi-agent verification (1 claude-code-guide + 3 adversarial agents) ran against the firing audit
and the redesign spike. It did NOT rubber-stamp:
- **Caught a window-gamed headline.** The first-cut audit reported 71% bite-follow-through at a +20min window —
  but a SINGLE search ~18min after a 7-bite phase-82 burst flipped 6 bites to "value" exactly at the cliff.
  Corrected to an honest **~55% per-episode / 35-70% per-bite band** with SAME-SESSION attribution (the old
  tool flattened all sessions into one timeline — a cross-transcript leak) and controls that catch the cliff +
  the leak (the old --verify-ingest was clean-on-seed). This stopped a gamed number from feeding a live-hook
  decision.
- **Surfaced the resumed-session stale-pass.** sessionId is STABLE across --resume, so "in-session" had to mean
  "since `.session-start-ts`", not "in this transcript". That refutation became the redesign's freshness bound.

### Retro (Phases 91-95, dims 1-3)
- **Blockers:** Phase 95 RESOLVED a backlog that had accreted since Ph82-88 (A5, A4/A6, trim-trials, resume-artifact).
  Lesson: a periodic "close every open obligation to a verdict" round clears deferral debt that individual phases
  keep punting. The assumption-ledger + Blockers filings made the backlog legible enough to sweep.
- **Reversals:** the dominant pattern of this arc is reversal-on-better-evidence — Ph94 reversed the demand-zero
  premise (couldn't-fire), Ph95's adversarial pass reversed my window-gamed 71%. Both came from re-measuring on a
  fixed instrument / refuting before committing. Verify-by-firing + adversarial-verify are the load-bearing habits.
- **Corrections:** the maintainer's Q4 reject (writer audit -> keep-by-affirmation) RIGHT-SIZED the phase; the T3
  redesign choice over keep/retire; the adversarial corrections. Direction came from the gate + checkpoint, not
  from the agent's first instinct — the 2-gate + HARD-checkpoint model worked as designed on a high-stakes change.

### Gate Compliance
- Phase 95: direction=approved, delivery=accepted. Both boundary gates present. Assumption-ledger revisit CLEAN
  (A1/A2/A4 accept + A3 reject, all held — none bit).

## Soft Observations / Phase N+1 Candidates
- **enforce-memory redesign is a fail-open NUDGE, not a hard gate** — one real memory_search per session satisfies
  it. A future round could measure whether the real-event assertion actually reduces ritual vs the old marker
  (does the ~45% ritual share drop?). Evidence: eval/memory-disposition/redesign-spike.md, enforce-memory-audit.md.
- **session-start.sh:110 (`rm .claude/.memory-consulted`) is now vestigial** — the gate no longer reads the marker.
  Harmless; cleanup candidate (deferred to avoid touching the session-start surface this phase).
- **The hook's marginal value over the rules-nudge-alone is still unisolated** (Phase-94 confounded by domain — 2/3
  high-demand consumers are AML). A clean marginal-value measurement on a non-AML rules+hooks consumer would settle
  keep-the-hook-at-all.
- **Strategic: the memory-layer question is now SETTLED (KEEP), not deferred.** The [[strategic-inflection-review]]
  "shrink the re-presentation layer" thread is largely spent; the amplifier program's surviving untested avenue
  (retrieval of genuinely proprietary/post-cutoff correctness derivable from no fair corpus) remains unchartered —
  the honest next frontier if the kit pursues measured harness value.
