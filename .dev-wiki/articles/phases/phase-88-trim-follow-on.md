---
title: "Phase 88: Trim Follow-On Round"
aliases: [phase-88, trim-follow-on]
category: phases
tags: [subtraction, trim-trial, prune-on-value, ceremony, dev-plan, dev-debrief, hooks, registration, checkers, memory]
parents: [phase-86-ceremony-lift-measurement, phase-87-stage2-episode-contrast, phase-83-prune-on-value-subtraction]
created: 2026-06-11
updated: 2026-06-11
source: plan
status: active # READY FOR COMPLETION — 6/6 tasks, 10/10 exit criteria ALL-PASS; delivery gate pending
scope: ["templates/.claude/skills/dev-plan/**", "templates/.claude/skills/dev-debrief/**", "templates/.claude/hooks/enforce-memory.sh", "templates/.claude/hooks/detect-loop.sh", "templates/.claude/hooks/check-tests-were-run.sh", "modules.json", "MANIFEST", "templates/.claude/settings.json", "tests/**", "eval/trim-round/**", "eval/ceremony-lift/stage2/run-exit-criteria.sh", "eval/ceremony-lift/stage2/check-instrument.sh", "eval/ceremony-lift/stage2/check-ship-table.sh"]
entry_criteria: "Phase 87 delivery accepted + gate flipped (7e9c56f); spec specs/phase-88-trim-follow-on.md nana:approved 2026-06-11"
exit_criteria: "The spec's 10 machine-checkable criteria via eval/trim-round/run-exit-criteria.sh ALL-PASS"
---

# Phase 88: Trim Follow-On Round

## Objective

Execute the stage-1-authorized ceremony trims — GATE-NARROWED 2026-06-11 — as REVERSIBLE
trim-trials with per-candidate revert triggers: dev-plan ride-alongs (active-knowledge
re-presentation + state-loader/artifact-writer heft) and the dev-debrief knowledge-capture
strand narrowed to working-knowledge seeding + journal prose ONLY (the memory bridge/harvest
writers are deferred per gate A6); dispose of the gate-narrowed prune-on-value leftovers
(enforce-memory.sh demand revisit with A3 attempt+fallback evidence, detect-loop.sh,
check-tests-were-run.sh harden — the kit-side memory-MCP-layer disposition was REMOVED from
scope per gate A4) via verdict-gated serialized cuts/keeps/hardens; and tighten the three
Phase-87-routed stage-2 checker holes (run-exit-criteria.sh c2 function, check-instrument.sh
cmp-not-grep, check-ship-table.sh DNF hole) — all under the claim ceiling that stage-1
verdicts authorize trim-trials and dispositions, never permanent cuts or keeps minted by
this phase. Zero cuts/trims on any strand is a valid outcome.

## Scope

Files and modules affected (full detail: `specs/phase-88-trim-follow-on.md`):
- `templates/.claude/skills/dev-plan/` + `templates/.claude/skills/dev-debrief/` — ride-along
  trims and the gate-narrowed knowledge-capture trims (working-knowledge seeding + journal
  prose only), shipped as reversible trim-trials
- Leftover components: `templates/.claude/hooks/` enforce-memory.sh / detect-loop.sh /
  check-tests-were-run.sh (harden — HEU-007 dual-condition mechanism with paired smoke)
- Full registration chain per cut: `modules.json` + `make template` + MANIFEST regen,
  regenerated-diff ⊆ removal set; sandbox-rehearsed basename-normalized deregistration +
  ghost sweep on all discovered surfaces (incl. settings.local.json)
- `eval/ceremony-lift/stage2/`: ONLY the three routed files (run-exit-criteria.sh c2,
  check-instrument.sh, check-ship-table.sh); fixtures live under `eval/trim-round/`
- NEW `eval/trim-round/`: evidence re-snapshots, verdict table, checker fixtures, removal
  sets, rehearsal logs, ghost-registration sweep, exit-criteria runner
- `.claude/rules/working-knowledge.md` — superseded entries per cut component, never rewrites

Out of scope: the kit-side memory MCP layer disposition + `memory_server/` vendoring menu +
20-surface enumeration (A4 reject — deferred with updated Blockers filing); memory-bridge/
harvest writer trims (A6 reject — writers stay alive so the future layer round gets clean
demand evidence); assumption-approval gate, debrief operational half, reviewer dispatches
(keep verdicts stand), any other frozen-apparatus edit, user-owned `~/.claude/rules/`, ghost
global registrations beyond each cut's own, consuming-project synchronized uninstalls,
Phase-87 episode transcripts as trim-trial evidence (provenance-excluded).

## Approach

Verdict-table-first, serialized execution — the Phase-83 method extended with trim-trial
reversibility; five stages mapped to tasks T1-T6 (full rationale: [[trim-follow-on-round]],
high): T1-T2 evidence re-snapshots (provenance-filtered enforcement.log, drifted 69→385;
block→follow-through reconstruction with `undecidable-on-this-evidence` pre-stated fallback;
~15 active-knowledge reader surfaces enumerated, graceful-on-absent verified) + the ~10-row
verdict table with controls-first checker → T3 checker-tightening strand, A2 severability
spike FIRST, seeded-defect/clean/boundary fixtures before any tightened checker ships → T4
unconditional HARD checkpoint (couldnt-fire = defect, no cut offered) → T5 serialized
per-candidate commits (rehearsed revert + deregistration positive control + ghost sweep) →
T6 close-out (ALL-PASS runner, Blockers filings, baseline-pin note). Trim mechanism:
deletion with rehearsed revert, not config-flip demotion (registered-but-dormant is the
kit's 4×-bitten failure class).

## Direction Gate (closed 2026-06-11, all_accept: false)

- **A1 accept** — Phase-86 stage-1 trim verdicts stand.
- **A2 accept-spike-defended** — three routed files severable from the freeze; the
  severability demonstration (scratch worktree, all 3 edited, both runners + make test
  green) opens T3; failure = STOP/file/drop the strand.
- **A3 accept-attempt+fallback** — enforce-memory block→follow-through reconstruction
  attempted; `undecidable-on-this-evidence` is a valid landing, never argued from the raw
  385 count.
- **A4 REJECT** — the edge-screener dogfood zero is NOT demand evidence; the memory-layer
  disposition is removed from scope and deferred to a future round with better evidence.
- **A5 accept** — consuming-project point-in-time copies need no synchronized uninstall.
- **A6 REJECT** (re-surfaced after A4) — bridge/harvest writer trims deferred with the
  layer; strand 2 narrowed to working-knowledge seeding + journal prose.

## Exit Criteria (10/10 ALL-PASS, 2026-06-11)

- [x] `eval/trim-round/verdict-table.md` + `check-verdict-table.sh` (phase-base SHA header;
      closed-enum verdicts; trims carry revert SHA + trigger + observation window + Blockers
      filing; seeded bad-row control first)
- [x] `check-ghost-registrations.sh` — zero nonexistent-path settings entries on any
      discovered surface (seeded ghost control first)
- [x] `check-stage2-allowlist.sh` — stage-2 diff vs phase-base contains only the three routed
      files; everything else byte-identical via cmp
- [x] `run-seeded-controls.sh` — each tightened checker FAILS on its seeded defect (14/14),
      PASSES on clean, incl. boundary cases
- [x] Paired smoke for the check-tests-were-run harden (block AND allow), wired into make test
- [x] `make test` green (27 scripts, incl. settings-template drift + bidirectional registration)
- [x] `make eval` 50/50 — denominator change 52→50 explained in the verdict table (detect-loop cut)
- [x] `grep -q 'Phase-87 verdicts stand' eval/trim-round/verdict-table.md`
- [x] Per-cut revert rehearsal logged under `eval/trim-round/rehearsals/`
- [x] `eval/trim-round/run-exit-criteria.sh` reports ALL-PASS

## Outcome (executed 2026-06-11 — detail: [[trim-round-outcome]])

T4 decisions executed serially, one commit per candidate: 2 trim-trials SHIPPED
(ak-ride-along d43950f; wk-seeding df3e623 — EXECUTION-CORRECTED, REVERT-COUPLED with
d43950f; windows through Phase 93); detect-loop CUT 75b48af (couldnt-fire
upstream-PERMANENT — impossibility, never demand); check-tests-were-run HARDENED b8bd416
(HEU-007 dual-condition); 3 stage-2 checker tightenings 6677157 (14/14 seeded controls;
Phase-87 verdicts stand as recorded); enforce-memory KEEP (A3 reconstruction SUCCEEDED,
3/7 block episodes verified real follow-through); 2 DROPPED at checkpoint
(loader-writer-heft, journal-prose). Review gate 9/10 accept, 4 MEDIUMs fixed inline.
Ledger: all 6 assumptions held.

## Constraints

See spec Constraints (CRITICAL): serialized one-commit-per-candidate with rehearsed revert;
basename-normalized deregistration + ghost sweep; couldnt-fire vs didnt-fire classification
before any verdict on a load-bearing zero; enforce-memory firing records classified
(follow-through) before keep/cut argued; memory-layer demand disposition BEFORE the
memory-bridge trim executes (pre-trim evidence only); stage-2 diff allowlist; no retroactive
re-grading of Phase-87 evidence; instrument-dead checkers may not ship; harden ships only
with paired mktemp -d smoke; superseded entries, never rewrites; zero cuts/trims is valid.

## Checkpoints

- HARD checkpoint (unconditional): full verdict table to maintainer BEFORE any
  trim/cut/harden executes; couldnt-fire candidates presented as defects, no cut offered
- Per-deregistration: sandbox rehearsal evidence in hand or the candidate does not execute
- Per-candidate commit: survivor smoke + make test; failure → revert immediately
- Tightened checker passes on its seed → STOP that strand (instrument-dead), file
- Routed edits break a non-routed stage-2 criterion → STOP, file, don't widen
- Coupled dependency forces scope beyond a removal set → STOP and ask

## Assumptions

Per spec: Phase-86 stage-1 verdicts stand; three routed files severable from the freeze;
edge-screener zero memory use = absent demand (couldnt-fire cause found → DEFECT, no cut);
point-in-time consuming-project copies need no synchronized uninstall; make template
sufficient per cut; deregistration window quiescent (else re-run ghost sweep + record gap).

## Notes

Stub created by phase-planning state loader 2026-06-11. Source authority:
`specs/phase-88-trim-follow-on.md` (nana:approved 2026-06-11), [[ceremony-step-verdicts]]
(dev-plan=trim, debrief-capture=trim), [[stage2-episode-outcome]] (undecidable — proceed on
stage-1 evidence alone), [[prune-on-value-subtraction]] + [[hook-registration-hygiene]]
(method precedents), _CURRENT_STATE.md Blockers rows (Phase-83 A5, Phase-83 keep-with-revisit,
Phase-84 platform, Phase-85 dogfood).
