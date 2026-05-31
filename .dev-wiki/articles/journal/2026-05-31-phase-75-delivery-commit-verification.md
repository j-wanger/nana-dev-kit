---
title: "Phase 75 complete — Delivery-Commit Verification (the 2nd dogfood→harden fix)"
aliases: []
category: journal
tags: [dev-debrief, delivery-gate, hooks, session-start, deterministic-validator, dogfood, consuming-project]
parents: [phase-75-delivery-commit-verification]
created: 2026-05-31
updated: 2026-05-31
duration: unknown
source: debrief
---

# Phase 75 complete — Delivery-Commit Verification

## What Happened

The 2nd dogfood→harden fix surfaced by the edge-screener consuming project (after Phase 74's
scaffold defects). The defect: in edge-screener, `/dev-debrief` marked Phase 2 `[x] Delivery
accepted` and wrote its journal while the work was **never committed** — Phase 3 then built on the
uncommitted tree. The harness recorded "phase complete, delivery accepted" as durable state while
`git` had nothing; gate-state and git-state silently diverged.

The decisive reframe happened at the direction gate. The naive framing — "guarantee the commit
fires" — is unachievable, because committing is an agent action and the instruction to commit
(`delivery-flow.md` D3) **already existed and was skipped**. That IS the bug. More skill-text
("verify the commit landed") is the same class of mechanism that just failed. So the objective was
reframed to "make gate-state diverging from git-state **impossible to ignore**" — a deterministic
validator at the boundary, per the technical posture and the kit's own scar tissue (Phase-55
session-start erosion, the functional-smoke invariant, [[decision:memory-architecture-classification]]
"strengthen always-loaded activation points, don't add things that can be unwired").

**T1 [M] — the PRIMARY fix (detector).** Added a fail-open divergence detector to
`templates/.claude/hooks/session-start.sh`, a sibling to the crash-recovery block: when
`active-phase.md` shows `- [x] Delivery accepted` for "Phase N" but `git log` has 0 commits matching
`phase[ _-]?N\b`, it emits `[nana:recovery]`. It fires independent of agent adherence and survives
every compaction/session boundary — exactly where the skipped skill-text could not. Built RED-first:
4 tests added to `test_harden.sh` (fires-on-divergence / silent-when-committed / silent-when-unchecked
/ fail-open incl. the no-phase-number garbled case). The RED run confirmed on the positive
fires-on-divergence test before GREEN. harden 17/17; firing-coverage 21/21 with **no denominator
churn** — session-start was already counted, the new branch just needs the functional assertion the
smoke invariant requires.

**T2 [S] — the SECONDARY fix (skill-text + ordering).** `delivery-flow.md` D3 now (3) verifies the
commit landed (exit status + HEAD advanced + clean tree) and, on a hook-aborted commit, surfaces
loudly + does NOT push + does NOT mark the gate + STOPs; (4) flips the delivery gate to `[x]` and
sets gate-log `delivery=accepted` ONLY after the verified commit. To make the ordering real,
`executor-prompt.md` #11 and `SKILL.md` Step 18 now write the delivery gate **UNCHECKED** (the
executor runs pre-commit) — D3 flips it post-commit. Gate-state now follows git-state. The D3
self-assert specifically covers the hook-abort branch the detector also catches via end-state.

**T3 [S] — regression + deferrals.** make test "All tests passed", make eval 52/52, `git diff
--quiet HEAD -- eval/` clean. Recorded 3 deferrals in Blockers as `[deferred: Phase-75]`.

This very debrief is itself evidence of the installed-copy-drift soft observation (below): the kit's
OWN `/dev-debrief` ran the INSTALLED `~/.claude/skills/dev-debrief/`, so the gate-after-commit
ordering fix (which lives in `templates/`) is not live for this run until install.sh re-syncs — the
orchestrator wrote the delivery gate UNCHECKED by the override in this phase's instructions instead.

## Decisions Made

- [[delivery-commit-verification|Delivery-Commit Verification]] — detector-first fix; finalized to
  `confidence: high` (was `medium` at plan time; the fix is implemented + verified).

## Problems Solved

- Accepted-but-uncommitted divergence — fixed by a deterministic end-state detector (PRIMARY) +
  commit-verify-before-gate ordering (SECONDARY), reframed from "force the commit" to "surface the
  divergence."

## Artifacts Changed

- `templates/.claude/hooks/session-start.sh` (new fail-open divergence-detector branch, sibling to crash-recovery)
- `tests/test_harden.sh` (4 RED-first detector firing tests; harden 17/17)
- `templates/.claude/skills/dev-debrief/delivery-flow.md` (D3 commit self-assert + gate-after-commit ordering)
- `templates/.claude/skills/dev-debrief/executor-prompt.md` (#11 writes delivery gate UNCHECKED)
- `templates/.claude/skills/dev-debrief/SKILL.md` (Step 18 writes delivery gate UNCHECKED)
- `.dev-wiki/articles/decisions/delivery-commit-verification.md` (confidence medium→high, status→accepted)

## Health Delta

- `make test`: "All tests passed" — `test_harden.sh` +4 detector tests → **17 passing**;
  firing-coverage **21/21** (no denominator churn); registration / settings-drift / templates green.
- `make eval`: **52/52 (100%)**, unchanged.
- `eval/` git-diff-clean. make-test script count unchanged (extended `test_harden.sh`, edited skill `.md`; no new scripts).

## Review Gate

Standard ceremony → unified reviewer dispatched at the orchestrator level, **read-only with the diff
passed inline** (Phase-74 isolation lesson: a reviewer running make/git against uncommitted work once
reverted it — here the reviewer never touched the tree).

**Verdict: ACCEPT — Score 9/10.** Reviewer verified the detector is genuinely fail-open under
`set -euo pipefail` (every risky path: `grep -c … || true`, the `[ -eq 0 ] 2>/dev/null` numeric test
on empty/non-numeric values, the `grep|grep|head -1` SIGPIPE chain — none crash session-start), and that
the `phase[ _-]?N\b` predicate correctly rejects numeric-prefix false positives (Phase 24/200/10 for
N=2/1). Two LOW issues, both non-blocking:
- LOW — decimal phase numbers (`Phase 2.5`) would false-*negative* for N=2 (the `\b` sits before the `.`).
  Theoretical only — integer-phase convention; reviewer said no change needed. Not fixed.
- LOW — gate-log write asymmetry: the `active-phase.md` checkbox was made explicitly-unchecked but the
  `tasks.md` gate-log relied on absence-as-pending. **Fixed inline** — `delivery-flow.md` D3 step 4 now
  states D3 is the sole writer of `delivery=accepted` (both halves pending until the verified commit).

**Dogfood self-check found a real defect (the reviewer missed it).** Running the detector against
nana-dev-kit's OWN `active-phase.md` at delivery exposed that the kit's debrief writes
`Phase: NONE — Phase N COMPLETE` (number NOT right after the colon), so the original
`^Phase:[[:space:]]*[0-9]+` extraction returned EMPTY → the detector was **dormant on the maintainer's
own format** (it worked only on edge-screener's `Phase: N — COMPLETE`). Fixed: extract a number that
follows the word "Phase" anywhere on the `Phase:` line (`grep -oiE 'phase[ :_-]*[0-9]+'`), robust to both
formats. Added a 5th RED-first test for the completion format (test_harden 18/18). This is precisely the
value of running the new check against the real repo before shipping — a static review of the regex
couldn't surface a format mismatch with the consuming convention.

### Retro Check (Phases 71-75)

Not triggered this debrief: the retro trigger counts `status: completed` phase **articles** (Glob),
which stands at 72 after marking phase-75 (early collapsed phases have no article); 72 % 5 ≠ 0.
(The last article-count modulo trigger was Phase 70 → article count 70.)

### Gate Compliance (Phase 75)

| Gate | State | Evidence |
|------|-------|----------|
| Direction | approved 2026-05-31 ("yes") | `gate-log:phase-75 direction=approved` in tasks.md |
| Spec | nana:approved | `specs/phase-75-delivery-commit-verification.md` |
| Delivery | UNCHECKED at debrief; orchestrator flips after verified commit | this phase's own fix — gate-state follows git-state |

No gate violations. The delivery gate is intentionally left unchecked by this executor (the
phase's own commit-verify-before-gate ordering) — the orchestrator marks it `[x]` only after the
commit verifies.

## Soft Observations / Phase N+1 Candidates

- **Installed-copy drift (2nd concrete instance)** | a `make test` guard or session-start check that diffs `templates/.claude` vs `~/.claude` and warns on drift | nana-dev-kit's OWN `/dev-debrief` runs the INSTALLED `~/.claude/skills/dev-debrief/`, so the Phase-75 fix (which lives in `templates/`) is not live for the kit's own debrief until install.sh re-syncs — the same class flagged as a Phase-74 soft observation, now with a 2nd instance (this very debrief run). Strengthens the case for an installed-copy-drift guard.
- **The dogfood→harden loop is producing real kit fixes** | expect more findings as edge-screener accrues sessions; keep routing them as harden phases | Phase 74 (scaffold defects) and Phase 75 (commit-verification) both originated from the edge-screener consuming-project dogfood / third-eye review — the loop is functioning as designed.
- **3 Phase-75 deferrals recorded in Blockers** | re-trigger: any recurs in real consuming-project use | (1) same-session Stop-time catch (`session-stop.sh`) — session-start is the load-bearing compaction-surviving point; (2) broader state-store drift (edge-screener `active-phase.md` never advanced to Phase 3 — rules/git/dev-wiki stores drifted); (3) lifecycle eval scenario for the divergence detector (the `test_harden` firing test is the gate).

## Related

- [[phase-75-delivery-commit-verification|Phase 75: Delivery-Commit Verification]] — parent phase
- [[cross-session-substrate-stock-screener]] (Phase 73, the substrate that surfaced the defect)
- [[harden-consuming-project-scaffold]] (Phase 74, the prior dogfood→harden fix)
- [[2026-05-30-phase-74-harden-consuming-scaffold|Phase 74 journal]]
