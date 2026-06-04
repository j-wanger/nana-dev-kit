---
title: "Codebase Snapshot 2026-06-04 (Phase 77 complete)"
aliases: []
category: status
tags: [snapshot, phase-77]
parents: [phase-77-cross-session-retention-screen]
created: 2026-06-04
updated: 2026-06-04
source: debrief
---

# Codebase Snapshot — 2026-06-04

## Metrics

| Metric | Value |
|--------|-------|
| Version | 0.5.0 |
| Skill .md files (templates) | 114 |
| Hook .sh files (templates) | 21 |
| Test scripts | 19 (`make test`, UNCHANGED — Phase 77 apparatus is repo-only, not a make-test script) |
| Eval scenarios | 52 (`make eval` 100%, UNCHANGED) |
| Decision articles | 164 |
| Phase articles | 77 (76 completed; Phase 77 complete, delivery gate pending commit-verify) |

## Module Structure

Unchanged from prior snapshots (see `_ARCHITECTURE.md`). This session added ONLY a repo-only measurement apparatus (no change to the kit's installed surface):
- `eval/amplifier/xsession-screen/` — NEW frozen cross-SESSION retention-headroom screen (sibling to `anchor-screen/`, `retention-screen/`; NOT wired into install.sh/Makefile/make test/make eval). `residual-audit.sh` (deterministic provenance absence-grep over OFF corpus = code+tests+git-MESSAGES, `git log -p` EXCLUDED, NO LLM; `--selftest` both ways) + `assert-subject-untouched.sh` (read-only guard) + `token-list.tsv` (14 discriminators) + `pre-registration.md` + `.prereg-commit` (`21a6c52`) + `residual.md` (0/14) + `screen-record.md` (`PROGRAM-VERDICT: TERMINATE`).
- `.dev-wiki/articles/decisions/cross-session-retention-headroom-screen.md` — RESULT section appended (high; TERMINATE).
- `.dev-wiki/articles/phases/phase-77-cross-session-retention-screen.md` — status → complete, exit criteria checked.

## Test Status

- `make test`: 19 scripts green ("All tests passed", UNCHANGED — apparatus repo-only, no new make-test script).
- `make eval`: 52/52 (100%, UNCHANGED).
- Firing-coverage / registration / settings / README: UNCHANGED (no hook/skill/surface change). `eval/` working tree is exactly the new apparatus dir.

## Recent Commits

```
c063685 Phase 77 T2 — residual audit result: RESIDUAL 0/14 → GATE TERMINATE
21a6c52 Phase 77 — plan + pre-registration (cross-session retention screen, audit-gated)
0e7d702 Phase 76: Installed-Copy-Drift Guard — detect a stale installed ~/.claude vs templates/
abfa7b8 Phase 76 — Installed-Copy-Drift Guard (plan)
add2ee7 Phase 75 — Delivery-Commit Verification (+ debrief)
```

(Phase 77 debrief commit pending — the orchestrator runs delivery-flow / commit separately. The delivery gate flips to `[x]` only after the commit verifies: gate-state follows git-state.)

## Notes

- **Phase 77 closes the amplifier decision-retention line across all three regimes** (single-decision Ph70 DEGENERATE 5/5, single-session Ph71 TERMINATE-by-summary-robustness, cross-session Ph77 residual-0 TERMINATE). Headline: "a decision that has been implemented IS in the implementation" — the residual is 0 from code+tests before commit messages are even consulted.
- Substrate (edge-screener) kept on OPERATIONAL grounds; no measured harness-value claim. Surviving untested avenue stays the Ph70 proprietary/post-cutoff-retrieval one.
- Un-sampled sliver (Phase-78 candidate, low): process/sequencing-roadmap retention (the Ph71 "diffuse process discipline" sub-thread) — strong prior also degenerate.
- `_CURRENT_STATE.md` 139>100 line-budget overage is chronic / pre-existing (noted, not fixed this phase) — standing cleanup candidate.
- `_ARCHITECTURE.md` broader file inventory predates several phases; flagged for a `/dev-scan` refresh.
