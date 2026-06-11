# Phase 88 verdict table — trim follow-on round
phase-base: 7e9c56f
pin: Phase-87 verdicts stand as recorded under the checker versions that graded them.

Format checked by `check-verdict-table.sh` (controls-first: checker-fixtures/). Status
lifecycle: proposed → approved (T4 HARD checkpoint) → executed (T5, requires
rehearsals/<id>.log) | dropped. All verdicts below are PROPOSED — nothing executes before
the checkpoint. Gate-removed candidates (memory-layer disposition, bridge/harvest writer
trims) are NOT rows here — see the A4/A6 deferral filings (T6).

| id | class | verdict | status | zero-class | revert-trigger | window | blockers-ref | evidence | removal-set |
|---|---|---|---|---|---|---|---|---|---|
| ak-ride-along | trim | trim-trial | approved | n/a | a post-compaction recovery or planning decision demonstrably wrong for lack of phase-pinned knowledge (recovery-protocol step-8 class), observed in any phase of the window | 5 phases (through Phase 93 close) | T6 filing, re-trigger at window end | ceremony-step-verdicts: dev-plan-orchestration=trim (active-knowledge re-presentation, amplifier-null class); evidence/active-knowledge-readers.md (all runtime readers guarded) | dev-plan SKILL.md 15f-bis+15f-ter; artifact-writer-prompt.md §7-8; wiki-query SKILL.md Step 8a (SECOND WRITER — resurrects file, T1 finding); dev-debrief Step 9 activation-quality + Step 19 + active-knowledge-transition.md (companion; test_companions.sh row); active-knowledge-spec.md; doc lines in dev-wiki SKILL/size-budgets/compaction-anchors-spec/dev-init templates; dev-check S10 row optional cleanup |
| loader-writer-heft | trim | trim-trial | dropped | n/a | recurring mid-plan context exhaustion (compaction during planning) or artifact-write defects (missed owned sections) in ≥2 phases of the window | 5 phases (through Phase 93 close) | T6 filing, re-trigger at window end | ceremony-step-verdicts: state-loader/artifact-writer heft is the named ride-along cost; Ph86 cost table (ceremony ~66% adj tokens) | dev-plan SKILL.md Orchestrator Protocol Dispatch 1+2 blocks (state loading + artifact writing return inline); state-loader-prompt.md + artifact-writer-prompt.md (companions; test_companions.sh rows); inline replacements reference existing Step 3-8/15 text which stays |
| wk-seeding | trim | trim-trial | approved | n/a | re-deriving a decision that working-knowledge previously pinned, observed ≥2 times in the window (session evidence) | 5 phases (through Phase 93 close) | T6 filing, re-trigger at window end | ceremony-step-verdicts: debrief-capture=trim, WK seeding ~10k tokens/session; consumption evidence cannot support keep for re-presentation class (amplifier nulls Ph70/71/77/78) | dev-debrief SKILL.md Step 15g WK-seeding block; executor-prompt seeding lines; wk-prune curator UNTOUCHED (extend-wk-prune-not-new-hook — separate kept surface); existing working-knowledge.md content stays (decaying-static cache) |
| journal-prose | trim | trim-trial | dropped | n/a | a debrief retro or crash-recovery demonstrably degraded by missing journal input within the window | 5 phases (through Phase 93 close) | T6 filing, re-trigger at window end | ceremony-step-verdicts: journal prose in the capture half; CAVEAT pre-listed: the debrief RETRO step consumes journals (Ph85 retro read phases 81-85) — fallback input = log.md lines + decision articles; checkpoint weighs this consumer | dev-debrief SKILL.md journal-writing step + executor-prompt journal lines; articles/journal/ history stays (historical, never rewritten) |
| enforce-memory | leftover | keep | approved | didnt-fire | n/a | n/a | n/a | evidence/enforce-memory-snapshot.md: A3 reconstruction SUCCEEDED — 3/7 block episodes verified real memory_search follow-through, 92 memory-consulted allows, marker does real gating work; zeros were never the question post-restoration | n/a (keep) — follow-up filing: resume-artifact (session resume clears marker though session already searched) as a future harden candidate, NOT in-phase |
| detect-loop | leftover | cut | approved | couldnt-fire | n/a | n/a | n/a | Ph84 platform filing: PostToolUse delivers NO exit-code field and NO event for failing Bash — the consecutive-failure counter is structurally unimplementable hook-side; couldnt-fire here is upstream-PERMANENT (defect filed Ph84, not fixable kit-side), distinct from the repairable-plumbing class HEU-012 bars cutting on; re-trigger stands: platform adds failure events | templates/.claude/hooks/detect-loop.sh; modules.json hooks entry + make template + MANIFEST regen; session-start.sh:110 SPLIT (remove .loop-state clear ONLY — VERIFY at execution no other consumer reads .claude/.loop-state: enforce-loop.sh, tests); test fixtures (test_harden .loop-state rows, test_eval_hermeticity tripwire) adjusted; 2 eval scenarios (denominator 52→50 explained); installed-surface dereg own-ghosts-only |
| check-tests-were-run | leftover | harden | approved | didnt-fire | n/a | n/a | n/a | Ph85 dogfood filing: confirmed false-positive class — Stop nudge fires on Read of .py during read-only analysis (3 Stop cycles, full suite re-run); demonstrated bite is real, trigger is wrong | n/a (harden in place): HEU-007 dual-condition — trigger keys on Edit/Write of code files AND retains tests-not-run; paired smoke (Edit-.py-no-test→block exit 2, Read-.py→allow exit 0) wired into make test |
| c2-through-head | checker | tightened | approved | n/a | n/a | n/a | n/a | Ph87 review-gate routing (c4bd9ff): c2 checks addendum byte-frozen between add-commits P..R only — a post-results touch escapes; seeded double-touch fixture must be caught | run-exit-criteria.sh c2 function only (routed file 1/3); fixtures live OUTSIDE frozen tree under checker-fixtures/ |
| instrument-cmp | checker | tightened | approved | n/a | n/a | n/a | n/a | Ph87 review-gate routing: check-instrument.sh greps key lines — a byte-differing-but-grep-matching instrument passes; cmp semantics pinned per file class (bytes-only), trailing-newline + empty-file-pair fixtures | check-instrument.sh only (routed file 2/3) |
| ship-table-dnf | checker | tightened | approved | n/a | n/a | n/a | n/a | Ph87 review-gate routing: check-ship-table.sh:23 `cmdlog|DNF` alternation — a DNF row passes without a cmdlog pointer; empty/absent-table must fail not vacuous-pass | check-ship-table.sh only (routed file 3/3) |

## Checkpoint decisions (T4 HARD checkpoint — maintainer, 2026-06-11)

Presented: full table + A2 spike log + 14/14 seeded-control results. Zero commits existed
at presentation time. Decisions:

- TRIM-TRIALS APPROVED (2): ak-ride-along, wk-seeding — serialized execution with rehearsed
  reverts, 5-phase observation window (through Phase 93 close), Blockers filings at T6.
- TRIM-TRIALS DROPPED (2): loader-writer-heft (maintainer kept the subagent indirection;
  evidence on record — ~280k tokens/planning run vs mid-plan-compaction risk),
  journal-prose (the every-5-phases retro is a live consumer; weakest trim case withdrawn).
- LEFTOVERS: enforce-memory KEEP (snapshot shows real follow-through — 3/7 block episodes
  verified memory_search; resume-artifact filed as future harden candidate, not in-phase);
  detect-loop CUT (couldnt-fire upstream-PERMANENT — platform delivers no failure events;
  cut argued on structural impossibility, never demand; re-trigger = platform adds failure
  events); check-tests-were-run HARDEN (HEU-007 dual-condition + paired smoke).
- CHECKER TIGHTENINGS APPROVED (3): c2-through-head, instrument-cmp, ship-table-dnf —
  commit as routed, Phase-87 verdicts stand as recorded (grandfathers pinned per instance:
  SETUP-SHA 4ed8071 live record, deadbeef frozen fixture).
- No standing-decision contradiction arose (memory-layer question out of scope per gate A4).
- Zero-cuts validity was on the table; the maintainer chose 2 trims + 1 cut + 1 harden + 1
  keep + 3 tightenings on the evidence presented.
