---
title: "Phase 73 — Cross-Session Substrate Bootstrap (the amplifier program pivots to substrate-construction)"
date: 2026-05-30
category: journal
tags: [phase-73, amplifier-vision, cross-session-persistence, substrate, external-project, dogfood, stock-screener]
phase: 73
---

# Phase 73 — Cross-Session Substrate Bootstrap

## Summary

The first phase after Phase 72 cashed the campaign's first conclusion. At the `/dev-plan`
direction fork Jake chose **Build a real substrate → cross-session persistence**, with a
concrete external workload: *an actually-working stock screener with real edge over the S&P
500, extensively tested.* This is the one surviving harness-value regime the Phase 58–71
campaign never reached, and — crucially — a **real external project removes the
self-measurement confound** that compromised Phases 70–71 (which measured this repo, whose own
git log is decision-comprehensive).

Phase 73 is deliberately **thin**: record the pivot + stand up the external substrate with the
**real** harness + record the deferred-measurement design. No quant code lives in nana-dev-kit;
the screener build proceeds in its own `.dev-wiki/`.

## What was done

- **Decision recorded:** [[cross-session-substrate-stock-screener]] (confidence high) — substrate
  = a new standalone project at `/Users/jwang/edge-screener`, built with the real harness across
  many real sessions. Three framings locked at the direction gate: (1) honest goal = an
  **un-foolable backtest validator, not guaranteed alpha**; (2) the cross-session measurement is
  **DEFERRED** (you cannot measure recovery on session 1 — nothing exists for a fresh session to
  recover until real multi-session history accrues); (3) data = free public (yfinance/Stooq) with
  **loud survivorship/point-in-time guards** (bias interacts with strategy; early edge numbers are
  ceilings).
- **External substrate bootstrapped + committed** (`edge-screener` `5cceac6`, 183 files): Python
  src-layout package on uv (ruff/mypy/pytest green); the **full real harness** (26 skills, complete
  hook tree incl. `session-start.d/` curators, settings, identity rules, pre-commit, CI); AGENTS.md
  retailored to backtest integrity + synced to all four agent surfaces; `.dev-wiki/` bootstrapped
  with a ruler-first 4-phase roadmap (Phase 1 = Data Foundation, active), standard ceremony.
- **Deferred-measurement design recorded** as a standing open question in `_CURRENT_STATE.md`
  (the OFF/ON fresh-session recovery protocol is designed *when* the substrate has history — not
  pre-registered now; pre-registering before the substrate exists would be premature, and the
  campaign's pre-registrations always followed the apparatus).

## Decisions

- [[cross-session-substrate-stock-screener]] — see above. The only formal decision; captured at plan.

## Escape hatches / deviations

- **DISCOVERY:** `dev-init`/`dev-plan` resolve the project via CWD git-root, so they could not be
  invoked to target the *sibling* `edge-screener` project from this nana-dev-kit session. Drove the
  screener's dev-init **manually** with absolute paths. (Noted as a kit limitation below.)
- **DISCOVERY:** `py-init`'s literal new-project steps copy only top-level hooks (`cp .../hooks/*.sh`)
  and would miss `session-start.d/` curators; copied the hook tree **recursively** instead so the
  curator chain survives.

## Health Delta

None in nana-dev-kit — no code/tests/templates touched this session (only the decision article +
state files). `make test`/`make eval` unchanged from Phase 72's green; not re-run (no code-level
change — re-running would be theatre).

## Soft Observations / Phase N+1 Candidates

The first real consuming-project dogfood exposed concrete scaffold gaps in the kit — transferable,
and a natural **Phase 74 engineering candidate** ("harden the consuming-project scaffold path"):

- **py-init curator gap** (evidence: `py-init/SKILL.md` Step 4 `cp .../hooks/*.sh` + `*.md` only): the
  literal new-project steps miss `session-start.d/` curators (`cognitive-readiness.sh`,
  `memory-nudge.sh`, `wk-prune.sh`). A project scaffolded by the literal steps boots without the
  curator chain. Fix: recursive copy, or align py-init with `install.sh --project-local`.
- **Bare pyproject template fails out of the box on a consuming project** (evidence: fresh
  `edge-screener` ruff/mypy run): `uv run mypy` is **targetless** (no `files=` in `[tool.mypy]`), and
  ruff does **not** exclude `.claude/`, so it lints the vendored kit Python (`wiki-index/*.py`) and
  errors. Had to add `files=["src","tests"]` and `extend-exclude=[".claude","data"]`. The template
  should ship these for any project that vendors `.claude/`.
- **AGENTS.md template is a web-app stub** (Pydantic/SQLAlchemy/FastAPI/repositories): wrong default
  for non-web projects; required full retailoring. Consider a domain-neutral base or a `--domain` cue.
- **dev-init/dev-plan can't target a sibling project** from another repo's session (CWD git-root
  coupling). Minor, but it forced the manual dev-init drive here.

These are wiki-capture candidates (kit-improvement insights) and feed the engineering-roadmap fork.

## Activation Quality

No `active-knowledge.md` in nana-dev-kit this phase (none written — thin handoff). Step skipped.

## Gate Compliance

Phase 73: `direction=approved` (AskUserQuestion fork, 2026-05-30), `delivery=accepted` (this debrief).
Both boundary gates present.

## Next

The screener build is the real work, in its own repo. Next concrete step: a **fresh session in
`/Users/jwang/edge-screener`** → `/dev-plan` for Phase 1 (Data Foundation) — which is also the
substrate's first real cross-session event. nana-dev-kit returns to **active phase NONE**, awaiting
the deferred cross-session measurement (trigger: the screener accrues real multi-session history).
A Phase 74 engineering option (harden the consuming-project scaffold path) now has concrete evidence.
