---
title: "Phase 95: Memory-Layer Disposition (Reconcile-and-Close)"
aliases: [phase-95-memory-layer-disposition, memory-layer-disposition-phase]
category: phases
tags: [memory, disposition, subtraction, enforce-memory, trim-trial]
parents: []
created: 2026-06-20
updated: 2026-06-20
source: plan
status: active
scope: ["eval/memory-disposition/**", ".dev-wiki/**", "specs/phase-92-memory-layer-prune.md", "eval/dogfood-round/evidence/window-events.md", "scripts/check-assumption-ledger.sh", "templates/.claude/hooks/enforce-memory.sh", "modules.json", "templates/.claude/settings.json"]
entry_criteria: "Phase 94 delivery accepted (45cb12b; consumer reversal banked); spec specs/phase-95-memory-layer-disposition.md nana:approved; Phase-95 ledger block appended + validated; direction gate closed (all_accept:false)"
exit_criteria: "every open memory ledger obligation (Phase-83 A5, Phase-88 A4/A6/A5-trim, enforce-memory revisit, 2 trim-trial windows) reaches a recorded evidence-cited closed-enum verdict; run-exit-criteria.sh ALL-PASS; make test + check-install-drift green"
---

# Phase 95: Memory-Layer Disposition (Reconcile-and-Close)

## Objective

Adjudicate **every** open memory-layer obligation to a single recorded, evidence-cited closed-enum
verdict, so that no obligation remains silently open — whatever the verdicts turn out to be. This is a
**reconcile-and-dispose-then-close** round, NOT a shrink/cut hunt; keeps are valid outcomes.

## Scope

Files and modules affected:
- `eval/memory-disposition/*` (verdict-table.md, run-exit-criteria.sh, enforce-memory-audit.md,
  redesign-spike.md, *.py)
- `.dev-wiki/**` (assumption-ledger A5 flip ONLY, Blockers, phase/index/log/state)
- `specs/phase-92-memory-layer-prune.md` (supersede note)
- `eval/dogfood-round/evidence/window-events.md` (Phase-95 trim attestation)
- `scripts/check-assumption-ledger.sh` (ONLY if `--append-only` forbids the legitimate A5 open→held)
- CONDITIONAL on a destructive enforce-memory verdict: `templates/.claude/hooks/enforce-memory.sh`,
  `modules.json`, `templates/.claude/settings.json`, `eval/cases/**`, `tests/**`

Zero kit code change UNLESS enforce-memory is redesigned/retired at the checkpoint.

## Exit Criteria

- [ ] `run-exit-criteria.sh --selftest` — controls-first: the runner rejects a seeded malformed table
      (out-of-enum cell, non-`keep` writer row, missing component row, destructive enforce-memory row
      missing its zero-class line). Clean-on-seed = instrument-dead.
- [ ] The 4 component rows present, each carrying a closed-enum verdict in COLUMN 2; both writer rows
      `keep` (evidence-split asymmetry); both trim-trials `confirm|restore`.
- [ ] `enforce-memory-audit.md` exists with `POSITIVE-CONTROL: PASS`; `redesign-spike.md` records
      `SPIKE: PASS|FAIL`; `redesign` only when the spike PASSED.
- [ ] A destructive enforce-memory verdict carries its `enforce-memory-zero-class:` marker; a
      non-`keep` verdict carries `supersedes: enforce-memory@Phase-88`; `SURVIVOR-SMOKE: PASS` or
      `N/A (no destructive verdict)`.
- [ ] The Phase-83 A5 row is no longer `revisit-status: open`; `check-assumption-ledger.sh` +
      `--gate 95` green.
- [ ] `## Phase 95` window-events attestation recorded; phase-92 spec carries a supersede note.
- [ ] `make test && make eval && bash scripts/check-install-drift.sh` — green, eval denominator 50
      (or the verdict table explains an enforce-memory-driven delta), drift 0.

## Constraints

- Every verdict cell is closed-enum and cites its own evidence pointer — prevents unfalsifiable rows.
- Evidence-split asymmetry honored + stated: consumer evidence may KEEP a kit-side writer, never CUT one.
- An enforce-memory `keep` cites FOLLOW-THROUGH evidence (real `memory_search` correlated to a block),
  never raw allow-counts (the marker is agent-touched — allow-counts measure self-attestation).
- No verdict cites a memory-subsystem ZERO (reinforcement count, access_count) as demand evidence —
  couldnt-fire/untracked, the exact mismeasure this arc corrects ([[HEU-012]]).
- Verify-by-FIRING (pipe a real event, assert exit), never presence — the registered-but-broken class
  bitten 5×.
- No rewriting history: prior records + the Phase-89 demand evidence are SUPERSEDED with notes.

## Checkpoints

- After the firing audit AND the redesign spike, BEFORE filling the enforce-memory cell: HARD
  maintainer checkpoint — present the allow/block ratio, follow-through-vs-ritual split,
  zero-classification, spike result; the maintainer picks `keep | redesign | retire`. No execution on
  direction-gate authority.
- If `retire`: present the removal set + `unreachable-installs:` degradation finding before any live
  settings edit. If a redesign survivor/paired smoke fails: revert before proceeding.
- keep/confirm rows need no checkpoint — evidence-cited re-affirmations, no destructive action.

## Notes

Supersedes `specs/phase-92-memory-layer-prune.md`. Closes ledger Phase-83 A5 (open→held) +
Phase-88 A4/A6/A5-trim. Direction gate closed 2026-06-20 (all_accept:false — A3 writer-audit rejected
→ keep-by-affirmation). Decision [[memory-layer-disposition]] (high); the load-bearing evidence is the
Phase-94 reversal ([[consumer-memory-remeasure]]).
