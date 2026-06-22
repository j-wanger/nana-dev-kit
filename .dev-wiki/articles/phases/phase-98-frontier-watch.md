---
title: "Phase 98: Frontier Watch (rung-B)"
aliases: [frontier-watch, rung-b]
category: phases
tags: [frontier-watch, rung-b, positioning, anti-retrofit, companion-research]
parents: [frontier-positioning-sweep]
created: 2026-06-21
updated: 2026-06-21
source: plan
status: active
scope: ["companion/research/watch/**", ".dev-wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Ph97 delivered + accepted (cbc057e); rung-B selected by the maintainer; direction gate closed 2026-06-21 (ledger Phase-98)."
exit_criteria: "Frozen watch-charter + controls-validated detector + wired weekly/monthly trigger; ZERO kit code change; make test PASS + drift 0; git ls-files companion/ empty."
---

# Phase 98: Frontier Watch (rung-B)

## Objective

Stand up the Ph97 verdict's rung-B charter as a re-runnable, frozen, controls-validated **two-speed tripwire
watch** — a weekly broad-source/narrow-signal fast scan + a monthly deep re-derivation backstop + on-hit
escalation to the frozen Ph97 instrument — that keeps the differentiated-leaning verdict fresh by detecting
either resolver: the B5 boundary-validator contest or a COMMODITIZED core-primitive early-warning. Detects
and flags; executes no cut.

## Scope

Files and modules affected:
- `companion/research/watch/**` — the gitignored, local-only watch apparatus (charter, detector, fixtures)
- `.dev-wiki/**` — planning + close-out bookkeeping
- `.claude/rules/active-phase.md` — compaction anchor

OUT: any kit code/config change; any actual shrink/cut (gated to a later phase if a tripwire fires); editing
the frozen Ph97 `pre-registration.md`/`verdict.md` (read-only escalation target); `specs/` (the gitignored
frozen watch-charter IS the spec).

## Exit Criteria

- [x] `companion/` gitignored + `git ls-files companion/` empty
- [x] `watch-charter.md` frozen (SHA256 `.frozen` 8ec4af7b): both tripwires + falsifiable observables + broad source list + two-speed cadence + escalation rule, referencing `pre-registration.md` 600e1c9f + the convergence-map baseline
- [x] `run-watch.sh --selftest` flags both seeded tripwires + reads QUIET on the attach-churn + baseline controls (charter-drift guard exit 3 on tamper)
- [x] Weekly + monthly trigger wired — dated Blockers tripwire as the committed fallback (`/schedule` routine OFFERED, maintainer to confirm)
- [x] ZERO kit code/config change; `make test` PASS + drift 0

## Constraints

- Watch-charter FROZEN (SHA256-attested) before the T2 detector — prevents post-hoc redefinition of "what counts as a tripwire" after seeing a lab release (anti-retrofit).
- Controls-first: the detector MUST flag a seeded tripwire AND read QUIET on attach-surface churn — prevents shipping a dormant watch that never fires ([[HEU-012]]).
- Broad SOURCES / narrow SIGNAL — prevents alarm fatigue / cost-burn on the fast attach-surface layer that doesn't move the verdict (the Ph97 half-life finding applied per-tier).
- Escalation re-runs the FROZEN rule, never a fresh one mid-stream — preserves anti-retrofit.

## Checkpoints

- Before T2: confirm the watch-charter is frozen (`.frozen` SHA matches) — no detector against an unfrozen instrument.
- If the detector cannot flag a seeded tripwire (clean-on-seed): STOP, fix the instrument, never ship a dormant watch.
- T3 scheduling: offer `/schedule` for the weekly+monthly trigger; if declined, file the dated Blockers tripwire fallback.

## Assumptions

- A core-primitive commoditization is observable via the broad watched surfaces + the per-cycle scope-completeness scan. If false: the monthly deep re-derivation is the backstop.
- The wired trigger results in the watch actually running. If false: it becomes a dormant artifact (HEU-012) — the controls-first self-test + scheduled trigger are the mitigations.
- Re-running the frozen rule on escalation yields a decision-useful verdict despite its known over-conservatism. If false: a fresh simplified instrument is a later-round decision.

## Notes

The external arm of the Ph92 re-measure ([[frontier-positioning-sweep]]) returned differentiated-leaning;
the internal arm ([[memory-layer-disposition]]) returned KEEP — both agree NO shrink. This watch is the
standing early-warning that keeps that read honest as the frontier moves, not a re-open. Maintainer
overrode the verdict's quarterly cadence (weekly fast scan) and narrow scope (broad sources) at the
direction gate; reconciled via the two-speed design. Decision: [[frontier-watch]].

## Outcome

IMPLEMENTATION COMPLETE 2026-06-21 (3/3 tasks; status stays **active** — delivery gate pending). The watch
is STOOD-UP-NOT-YET-FIRED with the Ph97 read (2026-06-21) as baseline. T1 froze `watch-charter.md` (SHA256
`.frozen` `8ec4af7b`, anti-retrofit seal); T2 built `run-watch.sh` + 4 fixtures (`--selftest` PASS — both
seeded tripwires FIRE, both false-positive controls QUIET, charter-drift guard exit 3 on tamper); T3 filed a
dated Blockers tripwire as the committed scheduling fallback (the `/schedule` weekly+monthly trigger is
OFFERED; maintainer to confirm — the one open question) + documented the escalation path. A macOS awk
`\|`-as-alternation classifier bug was found AND fixed inside the gitignored apparatus, caught only by the
controls-first seeded-positives (the QUIET false-positive controls had passed for the wrong reason — live
[[HEU-012]] / clean-on-seed re-confirmation; fix = `[|]` bracket class). ZERO shipped-kit change; `make test`
PASS (incl. install-update 55/55), drift 0, `git ls-files companion/` empty. On delivery acceptance:
transition active→completed + flip the Delivery gate.
