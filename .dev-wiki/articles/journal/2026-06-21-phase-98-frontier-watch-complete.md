---
title: "Phase 98 implementation complete — Frontier Watch (rung-B), two-speed tripwire watch stood up"
aliases: [phase-98-frontier-watch-complete]
category: journal
tags: [frontier-watch, rung-b, companion-research, anti-retrofit, heu-012, controls-first]
parents: [phase-98-frontier-watch]
created: 2026-06-21
updated: 2026-06-21
source: debrief
duration: ~90 minutes
---

# Phase 98 implementation complete — Frontier Watch (rung-B)

## What Happened

- Stood up the Ph97 verdict's **rung-B charter** as a re-runnable, frozen, controls-validated **two-speed
  tripwire watch** — the EXTERNAL-arm early-warning that keeps the differentiated-leaning Ph97 read honest as
  the frontier moves. Lives entirely in gitignored `companion/research/watch/` (rung B of the companion
  de-risking ladder; NEVER shipped). 3/3 tasks; planned + fully implemented in one session.
- **T1 — froze the watch-charter** (`companion/research/watch/watch-charter.md` + SHA256 `.frozen`
  `8ec4af7b`): the 2 tripwire conditions VERBATIM from the verdict's resolver charter, each with a falsifiable
  observable — (A) **B5 boundary-validator** (a 2nd primary lab ships a value-capturing GA deterministic
  boundary-validator like OpenAI's auto-Pydantic, OR OpenAI's regresses → either → DIFFERENTIATED); (B) the
  **COMMODITIZED early-warning** (ANY lab ships value-capturing, default-on B1 blocking *content* or B4
  assumption/plan-adjudication → CORE toward COMMODITIZED → reopens shrink). Plus the BROAD watch-source list,
  the two-speed cadence, and the on-hit escalation rule (re-run the frozen `pre-registration.md` `600e1c9f`).
  Anti-retrofit: charter frozen BEFORE the T2 detector; the `.frozen` seal VOIDs a fired verdict on any
  post-freeze edit to the frozen sections.
- **T2 — controls-first fast-scan detector** (`run-watch.sh` + 4 fixtures): given a cycle's fetched
  release-feed evidence, classifies each tripwire MET/UNMET vs the frozen charter's delta rule (NOT the 60KB
  pre-registration rule — that's escalation-only) and emits `WATCH: QUIET | TRIPWIRE-FIRED | ESCALATE`.
  `--selftest` PASS: both seeded tripwires FIRE, both false-positive controls (attach-surface churn + the
  OpenAI-B5 baseline) read QUIET, and the charter-drift guard exits 3 on tamper.
- **T3 — two-speed wiring + close-out**: did NOT run a real sweep (Ph97 read 2026-06-21 is the baseline).
  Filed a **dated Blockers tripwire as the committed fallback** so the watch is not dormant; documented the
  escalation path; recorded the watch STOOD-UP-NOT-YET-FIRED. `make test` PASS (incl. install-update 55/55),
  drift 0, `git ls-files companion/` empty.

## Decisions Made

- [[frontier-watch]] (high) — written during planning; the two-speed tripwire-watch design. Not recreated this
  debrief (deduped).

## Problems Solved

- **macOS awk `\|`-as-alternation classifier bug** — the fast-scan classifier silently mis-split fields:
  one-true-awk treats `\|` in a field-separator regex as ALTERNATION, not a literal pipe. Fixed inside the
  gitignored apparatus with a bracket class `[|]`. Caught ONLY by the controls-first seeded-positives — the
  false-positive controls had passed for the WRONG reason (a broken classifier never fires, so it looks
  QUIET/clean); only the seeded tripwires exposed it. Live re-confirmation of HEU-012 / clean-on-seed.
- **enforce-spec blocked the first non-markdown companion write** (`run-watch.sh`). Its satisfaction path for
  the gitignored-spec deviation (Ph97 precedent) is a `[x] spec` marker in `active-phase.md` — the frozen
  watch-charter IS the approved spec. Marker added; preserved verbatim in the active-phase rewrite. (markdown
  companion files never trip enforce-spec — only non-markdown ones like `.sh` do.) enforce-memory also
  required a real in-session `memory_search` before writes.

## Open Questions

- The `/schedule` weekly+monthly trigger mechanism is OFFERED but not yet chosen by the maintainer; a dated
  Blockers tripwire is the committed fallback, so the watch is not dormant. Carry forward.
- `companion/` version-control durability is NOW ACTIVE (rung B landed; the watch accumulates cycle history) —
  already filed in Blockers, preserved verbatim.

## Artifacts Changed

- `companion/research/watch/watch-charter.md` (NEW, gitignored — the frozen instrument / spec)
- `companion/research/watch/.frozen` (NEW — SHA256 attestation `8ec4af7b`, anti-retrofit seal)
- `companion/research/watch/run-watch.sh` (NEW — controls-first fast-scan detector, `--selftest` + charter-drift guard)
- `companion/research/watch/fixtures/**` (NEW — 4 fixtures: 2 seeded tripwires + 2 false-positive controls)
- `companion/research/watch/README.md` (NEW — escalation path + usage)
- `.dev-wiki/tasks.md` (T1/T2/T3 marked `[x]`)
- `.dev-wiki/_CURRENT_STATE.md` (owned sections refreshed)
- `.dev-wiki/articles/phases/phase-98-frontier-watch.md` (exit criteria checked; status stays active — delivery gate pending)
- `.claude/rules/active-phase.md` (status → implementation-complete; `[x] spec` gate preserved; Delivery `[ ]`)

## Related

- [[phase-98-frontier-watch|Phase 98: Frontier Watch (rung-B)]] — parent phase
- [[frontier-positioning-sweep|Phase 97: Frontier Positioning Sweep]] — the verdict this watch stands up

## Health Delta

ZERO shipped-kit code/config change (git diff = `.dev-wiki/` + `active-phase.md` + 2 new articles only).
`make test` PASS (all suites incl. install-update 55/55). `check-install-drift` drift 0. The awk classifier
bug was found AND fixed inside the gitignored apparatus (caught by the controls-first selftest). No
shipped-kit test-count change. `docs/*.html` regenerated by `make test` (timestamp + git-log only) were
reverted as out-of-scope.

## Soft Observations / Phase N+1 Candidates

- **DIRECTION (Phase-99+):** invest marginal effort in the OPINIONATED CONTENT (IRON RULES, block policies,
  assumption-gate questions, lifecycle ceremony), not more plumbing/hooks. The Ph97 finding: the frontier
  commoditizes attach surfaces (hooks/middleware/guardrails/elicitation) but structurally leaves the
  opinionated default-on enforcing CONTENT to the consumer — that content layer IS the moat. | content-layer
  investment phase | `companion/research/convergence-map.md`, `verdict.md`; [[frontier-positioning-sweep]]
- **DIRECTION (Phase-99+):** a "ride the rails" posture — periodically ADOPT the commoditizing attach surfaces
  (MCP elicitation for the assumption gate, OpenAI guardrails patterns) so the kit's enforcement rides standard
  plumbing while keeping its opinion. | adopt-standard-plumbing phase | Ph97 B1–B5 classifications (all
  attach-surfaces GA + standardizing)
- **DIRECTION (rung D, Phase-99+):** generalization to a high-stakes opinion-heavy domain
  (AML/financial-crime / trading) is VALIDATED by the findings — the moat is "opinionated enforcing content +
  lifecycle ceremony", and opinion is exactly what transfers. | rung-D generalization phase | the
  convergence-map's commoditization-order signal (generic→first, opinionated→last)
- **LESSON (wiki-capture candidate):** macOS one-true-awk treats `\|` in a regex FS as alternation, not a
  literal pipe — silently breaks field splitting; use a bracket class `[|]`. Caught here ONLY by controls-first
  seeded-positives (a QUIET false-positive control passed for the wrong reason — a broken classifier never
  fires, so it looks clean). Generalizes HEU-012 / clean-on-seed.
- **OPEN:** the `/schedule` weekly+monthly trigger mechanism is offered, maintainer to confirm.
