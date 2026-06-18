---
title: "Phase 93 — install.sh Idempotent Update / Consuming-Project Re-sync Mode"
aliases: []
category: journal
tags: [phase-93, install, consuming-projects, hooks, deregistration, dedupe, idempotency, build-only, controls-first]
parents: [phase-93-install-resync]
created: 2026-06-18
updated: 2026-06-18
source: debrief
duration: ~3h
---

# Phase 93 — install.sh Idempotent Update / Consuming-Project Re-sync Mode

## What Happened
- Built `install.sh --update`: an idempotent re-sync mode that reconciles an already-installed consumer's
  project-local hooks + `settings.local.json` to the current kit — ADD/UPDATE changed hooks, dedupe
  registrations by basename, and automated deregistration of cut hooks behind safety rails. BUILD +
  SANDBOX-VERIFY ONLY — ZERO live consumer writes (`git diff` is kit-only; no external repo touched).
- Controls-first TDD held the line: T1 stood up the mktemp fixture harness for 3 drift classes (no-hooks /
  staged+detect-loop-ghost / Phase-79 duplicate-registration) PLUS a seeded synthetic cut-hook + a seeded
  duplicate registration, and proved the harness FLAGS both seeded defects before any reconcile logic was
  written (clean-on-seed = instrument-dead, would have STOPPED). The seeded controls confirmed genuinely
  discriminating (reviewer Consider 3).
- Shipped the first deregistration mechanism the kit has ever had. `register-settings.py` was upsert-only;
  added `--dedupe` (dedupe_by_basename on `hooks`) + a `deregister` subcommand, both basename-normalized
  per DRQ-1 (Claude Code dedupes by command STRING, so same-script-two-strings both fire — must normalize
  by basename). Reused by `--update`, NOT a separate `scripts/resync.sh` (subtraction test).
- Two-tier cut handling: LIBERAL warn (any unknown basename → flagged, never removed — protects a
  consumer's custom hooks) vs CONSERVATIVE removal (only `modules.json .cut_hooks` → destructively
  dereg). Destructive dereg is gated: timestamped `.claude/.dereg-backup.<ts>/` BEFORE any removal →
  survivor functional smoke (block-dangerous-bash fires exit-2-block / exit-0-allow, payload-driven) →
  revert-on-failure. Arming DECOUPLED — `.claude/enforce` untouched unless `--arm`.
- Consumer fixtures built PROGRAMMATICALLY from the live `modules.json` via `register-settings.py
  --scope project-local` (the real install path) — stale-proof; a manifest declares only the mutation +
  expected detections, so a new drift class is one `fixtures/<class>/manifest.json`.
- `check-install-drift.sh --consumer <root>`: read-only detect-and-warn complement to the destructive
  `--update` (missing / duplicate / cut by basename).
- Review gate (unified reviewer, Score 8/10, revise): one MEDIUM — `registered_basenames` was NOT
  genuinely fail-open (the `2>/dev/null` hid jq's message but not its exit code, which aborts under
  `set -e`) → a malformed consumer `settings.local.json` could half-sync. FIXED inline: a `jq -e .`
  validity gate that fail-STOPS at the top of `--update` before any cp/mutation (no half-sync) + a
  genuine fail-open path for `registered_basenames`. New T37 assertion covers it.

## Decisions Made
- [[deregistration-as-register-settings-subcommands|Deregistration + dedupe as register-settings.py subcommands]]
  -- the first dereg mechanism placement, two-tier cut handling, basename-normalized per DRQ-1.
  (The high-level build decision was captured at planning time: [[install-resync-update-mode]].)

## Problems Solved
- Fail-open that wasn't -- `2>/dev/null` suppresses jq's stderr but the nonzero exit still trips `set -e`.
  Replaced with an explicit `jq -e .` validity check + fail-STOP-before-mutation, making both the
  fail-open helper and the malformed-input guard genuine. (Review-gate MEDIUM, fixed inline.)
- README test-count drift -- T4's Makefile registration bumped 27→28 test scripts; fixed the README
  count + a line-budget trim inline (DISCOVERY) to keep `make test` (test_templates) green.

## Open Questions
- The revert-on-failure auto-trigger branch is INSPECTION-verified, not fault-injection-tested: the
  survivor probe is always refreshed from real templates before the smoke, so it always passes on the
  `--update` path — the JSON-validity fail-stop is the only live fallback exercised. Carrying forward as
  a known limitation; a future fault-injection seam would close it.

## Artifacts Changed
- `install.sh` (NEW `--update [--arm]` short-circuit mode; helpers `registered_basenames`, `survivor_smoke_ok`)
- `scripts/register-settings.py` (NEW `--dedupe`/`dedupe_by_basename` on `hooks`; NEW `deregister` subcommand; `_entry_basename`, `_is_canonical`)
- `scripts/check-install-drift.sh` (NEW `--consumer <root>` mode)
- `modules.json` (NEW `cut_hooks: ["detect-loop"]`)
- `tests/test_install_update.sh` (NEW, 37 assertions; registered in Makefile test target)
- `eval/install-update/` (README + 3 fixture manifests)
- `Makefile` (+1 test script), `README.md` (test count 27→28 + line-budget trim)
- `.dev-wiki/{_CURRENT_STATE,assumption-ledger,index,log,tasks}.md`, `.claude/rules/active-phase.md`
- `eval/dogfood-round/evidence/window-events.md` (Phase-93 attestation row + window-close note)

## Related
- [[phase-93-install-resync|Phase 93]] -- parent phase
- [[install-resync-update-mode]] (planning), [[drq-1-settings-merge-semantics-are-string-keyed]] (DRQ-1),
  [[prune-on-value-subtraction]] (upsert-only baseline), [[hook-registration-hygiene]] +
  [[install-gap-dir-currency]] (the manual jq surgery this codifies), [[HEU-012]] (verify-by-firing,
  sandbox-first).
- Re-sequenced from [[strategic-inflection-review]] (product-for-consumers frame); successors: Phase 94
  consumer memory re-measure → Phase 95 memory-layer shrink (and trim-trial confirm).

## Trim-Trial Window Disposition (ak-ride-along / wk-seeding — windows close at this debrief)
The two Phase-88 trim-trials (ak-ride-along d43950f, wk-seeding df3e623; revert-coupled) had a 5-phase
observation window through Phase-93 close. **No trigger event was observed in any window phase (88-93):**
every `eval/dogfood-round/evidence/window-events.md` row reads `event: none`; the ak window saw probative
kit-side planning/recovery sessions (Ph91, Ph92) that reached correct decisions WITHOUT active-knowledge
re-presentation; the wk window was kit-side-suppressed (always-loaded working-knowledge still presents the
pinned decisions, so no removed-class entry was re-derivable to count) — recorded honestly, not back-filled.
Per the trim-round design the disposition authority is THIS debrief, but the act of making the trims
permanent is the Phase-95 memory-layer shrink (roadmap: "make the Ph88 trim-trials permanent if windows
close clean"). **Recommendation surfaced to the maintainer: CONFIRM both trims (windows closed clean, zero
triggers) at Phase 95 — not restore.** The Phase-93 window-events row is appended; the trim-trial Blockers
entries stay open until Phase 95 records the confirm.

## Review Gate
Unified reviewer dispatch (Standard ceremony). **Score 8/10, Verdict revise.** One MEDIUM —
`install.sh registered_basenames` fail-open gap → silent half-sync on a malformed consumer
`settings.local.json` — FIXED inline (a `jq -e .` validity fail-STOP before any mutation + a genuine
fail-open `registered_basenames`; new assertion added). Three non-blocking Considers, all dispositioned:
(1) dedupe matcher-granularity (collapses same-script-two-matchers-in-one-event) — documented as a known
limitation, NOT implemented (no kit hook triggers it; a dry-run-first live follow-on catches a real
consumer; implementing risks a matcher-mismatched-duplicate edge bug); (2) `survivor_smoke_ok` `[-x]`
vacuous-pass branch is dead on the `--update` path — intentional defensive code; (3) seeded controls
confirmed genuinely discriminating.

### Retro Check (Phases 71-93)
| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 1 (registered-but-broken / ghost-registration class — the exact class this phase's dereg automates away) | low |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 0 this window (the assumption gate's all-accept A1-A5 ran clean) | none |

Recommendations:
- No systemic issue. The one low-signal recurring blocker (registered-but-broken, bitten 5× across
  Ph79/82/84/85/88) is precisely what Phase 93 set out to mechanize — the dereg-behind-rails primitive +
  `check-install-drift.sh --consumer` directly target it. The remaining residual is that the primitive is
  sandbox-only this phase; the gated live-application follow-on (Blockers) is the close-the-loop step.

## Soft Observations / Phase N+1 Candidates
- The revert-on-failure branch is unexercised by automated tests (survivor always passes post-refresh) |
  a future fault-injection seam (force a corrupt survivor / mid-dereg failure) would close it |
  evidence: `install.sh survivor_smoke_ok`.
- dedupe matcher-granularity collapses same-script-two-matchers-in-one-event | documented limitation, no
  kit hook triggers it; the dry-run-first live follow-on catches a real consumer | evidence:
  `register-settings.py dedupe_by_basename` docstring.
- `_CURRENT_STATE.md` is ~207 lines (>100 budget); the Blockers section has ~60 accumulated items back to
  Phase 66 | a Blockers archival/pruning pass is overdue | pre-existing, surfaced by self-check Cat 2.
- `.dev-wiki/tasks.md` is ~399KB and never collapses completed phases | a tasks.md compaction pass
  (collapse completed phases into `<details>` per size-budgets) is overdue | pre-existing, surfaced this debrief.
- Only 8 file-articles exist repo-wide; the kit does not maintain `.dev-wiki/articles/files/`
  comprehensively | either commit to the convention or relax the Cat-7 self-check expectation |
  pre-existing.
