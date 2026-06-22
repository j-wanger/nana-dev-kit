---
title: "Phase 98: Frontier Watch (rung-B) — Two-Speed Tripwire Watch"
aliases: [frontier-watch, rung-b-frontier-watch, quarterly-frontier-watch]
category: decisions
tags: [frontier-watch, rung-b, positioning, anti-retrofit, companion-research, heu-012]
parents: [phase-98-frontier-watch]
created: 2026-06-21
updated: 2026-06-21
source: plan
confidence: high
---

## Context

Phase 97 ([[frontier-positioning-sweep]]) closed the Ph92 shrink question — both arms agree NO shrink
(internal [[memory-layer-disposition]] = KEEP; external frontier verdict = INCONCLUSIVE-forced,
differentiated-leaning). The verdict named a **rung-B charter**: watch two tripwires — (1) the B5
boundary-validator contest (a 2nd primary lab ships a value-capturing GA deterministic boundary-validator
like OpenAI's auto-Pydantic tool-arg validation, OR OpenAI's regresses → either resolves to DIFFERENTIATED);
(2) the COMMODITIZED early-warning (ANY lab ships value-capturing, default-on B1 opinionated blocking
*content* or B4 enforced assumption/plan-adjudication → moves the CORE toward COMMODITIZED, reopens shrink).
rung-B was deferred "if/when justified"; the maintainer selected it for Phase 98.

## Decision

Build a **re-runnable, frozen, controls-validated TWO-SPEED tripwire WATCH** — not a sweep re-run, not an
always-on full pipeline. Cadence is split by **cost**, not one global clock (the maintainer rejected the
verdict's quarterly recommendation — "things change too fast, weekly if not daily" — and rejected the narrow
scope):

- **Primary — fast, cheap, BROAD scan (WEEKLY):** scan a broad set of lab release-feeds/changelogs/blogs
  (Anthropic, OpenAI, Google, Microsoft, MCP — primary; OSS bellwethers — secondary) for the **narrow
  value-capture-passing tripwire signal only**. Broad *sources*, narrow *signal* → cheap + high
  signal-to-noise (won't fire on the constant attach-surface churn that fails value-capture).
- **Escalation — rare, expensive (ON-HIT):** a tripwire fires → re-run the full FROZEN `pre-registration.md`
  (sha `600e1c9f`) for a mechanical verdict (A3 accept — anti-retrofit holds; can't swap the rule after
  seeing it bite).
- **Deep backstop — low-frequency (MONTHLY):** a full re-derivation against the Ph97 baseline to catch the
  scan's keyword-level false-negatives + rebaseline (the Q1 blind-spot worry, handled by depth).

Controls-first detector (`run-watch.sh --selftest`, HEU-012 anti-dormancy): seed synthetic tripwire-firings,
assert each is FLAGGED, plus an attach-surface-churn control + a baseline control that must read
`WATCH: QUIET`. Clean-on-seed = dormant watch = instrument-dead → STOP. Watch the tripwire CONDITIONS
directly; escalate to the full rule only on a fire. Don't re-run the sweep now (Ph97 read 2026-06-21 is the
baseline). Lives entirely in gitignored `companion/research/watch/`; the frozen watch-charter is the spec
(Ph97 gitignored-deviation precedent). Zero shippable-kit change; `make test` PASS, drift 0.

**Alternatives considered:** (a) quarterly narrow watch (the verdict's recommendation) — REJECTED by the
maintainer (too slow / too narrow for a fast-moving frontier). (b) daily *full* re-fetch-and-reclassify of a
broad list — REJECTED (the cost-burning standing pipeline the verdict warned against; watches the fast layer
that churns but doesn't move the verdict; causes alarm fatigue → dormancy by the back door). The two-speed
split is the reconciliation: the maintainer's speed on the cheap tier, the verdict's cost/half-life logic on
the expensive tier.

## Consequences

A recurring obligation (weekly cheap scan + monthly deep + on-hit escalation). The watch reads
DECLARED/productized frontier only (honesty bound inherited from Ph97 — internal lab harnesses unseen). On a
B1/B4 tripwire firing → shrink reopens via a fresh full frozen-instrument re-sweep; on a B5 firing → the
verdict resolves to DIFFERENTIATED (both resolutions, per the charter). Primary risk: **dormancy** (a
built-but-never-run watch is worse than none — false security; HEU-012, 3 prior cascade failures) —
mitigated by a real scheduled trigger + the controls-first self-test. Secondary risk: **alarm fatigue** on a
too-fast watch — mitigated by the narrow-signal filter (the cheap scan only flags value-capture-PASSING core
signals, not "anything shipped"). The known over-conservatism of the frozen escalation rule (the Ph97 B5
zero-tolerance bite) is recorded, not fixed — the B1/B4 COMMODITIZED tripwire rides the K_low path, not the
B5 contest clause.
