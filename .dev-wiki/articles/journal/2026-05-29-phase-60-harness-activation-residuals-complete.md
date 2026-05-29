---
title: "Phase 60 complete — Harness Activation Residuals (AGENTS.md trim + kit-uninitialized nudge)"
aliases: [2026-05-29-phase-60-harness-activation-residuals-complete]
category: journal
tags: [phase-60, harness, agents-md, instruction-budget, session-start, nana-init, cognitive-readiness, deterministic, subtraction-test, roadmap-complete]
parents: [phase-60-harness-activation-residuals]
created: 2026-05-29
updated: 2026-05-29
source: debrief
---

# Phase 60 complete — Harness Activation Residuals

## What Happened

Closed the Phase 57+ harness-activation roadmap with its last two residual fixes, bundled, each shipped with a deterministic, test-backed success criterion (no judge-eval — both changes are mechanical, so an eval would launder variance, not reveal signal).

- **Fix 5 — kit-uninitialized nudge:** `cognitive-readiness.sh` now detects a missing `.dev-wiki/` and emits one actionable `run /nana-init` line, short-circuiting the per-component probes (the enforce/wiki/memory statuses are all moot before bootstrap). Bare-dir output went from a wall of "inactive/none" to 3 actionable lines — a net noise *reduction*. Verified by a new bidirectional firing test (`tests/test_cognitive_readiness.sh`): nudge fires when uninitialized, silent when `.dev-wiki/` exists.
- **Fix 3 — AGENTS.md budget + salience trim:** `templates/AGENTS.md` 86→82 lines. Deduped the lint/type/test triplet (was stated 2× — Toolchain + Pre-commit sequence; now canonical in Pre-commit sequence only), moved Hard Rules above Conventions (lead with highest-leverage), and codified the always-loaded line cap (≤84) as a `test_templates.sh` assertion instead of an unenforced comment — the "caps need assertions, not docs" lesson (Phase 55 session-start.sh erosion) applied.

## Decisions Made

- [[deterministic-success-over-eval-ceremony|Deterministic success criteria over eval ceremony for mechanical changes]] — high confidence. For a byte-identical-output change, the rigorous validator is structural assertions + bidirectional firing tests, not a judge A/B. Subtraction test applied to validation ceremony. Boundary: when a deterministic change sits atop an unverified *behavioral* claim (AGENTS.md:84's "~300 lines degrade instruction-following"), carve that out as a separate research phase — don't launder it.

## Problems Solved

- Adding `tests/test_cognitive_readiness.sh` tripped the existing "README test script count matches reality" assertion (Makefile 10→11 scripts). Fixed README 10→11 — a DISCOVERY-class out-of-declared-scope edit, coupled by the test.
- cognitive-readiness.sh dedup: extracted `_nana_kit_summary()` so the kit-inventory line is shared by the normal and uninitialized paths (no duplication, normal-path output byte-identical — confirmed by reviewer).

## Escape Hatches Used

- **USER OVERRIDE:** user waived the direction gate ("no need to wait for my confirmation on direction... go through all the necessary steps to complete this phase") and authorized an autonomous run plan→implement→debrief. Direction gate marked satisfied-by-override in active-phase.md.
- **DISCOVERY:** README.md test-script count edit (outside declared scope) forced by the Makefile↔README coupling when the new test script was added.

## Health Delta

- +1 test script: `tests/test_cognitive_readiness.sh` (3 firing assertions). Suite 10→11 scripts.
- +4 assertions in `test_templates.sh` (dedup ×2, line-cap, salience ordering). test_templates 169→173 asserts, all green.
- `templates/AGENTS.md`: 86→82 lines (budget cap 84 codified).
- `make test`: 11 scripts green (incl. memory suite — sqlite-vec guard from Phase 58 maintenance holds). `make eval`: 54/54 (100%).
- Review gate: 9/10 accept, 0 CRITICAL/HIGH/MEDIUM, 3 acceptable LOWs.

## Review Gate

Unified reviewer (Standard ceremony): **9/10, accept**. Verified no distinct AGENTS.md rule lost (only duplicated command spelling + "All three must pass" sentence removed); all placeholders + Pre-commit section preserved; `_nana_kit_summary` refactor produces byte-identical normal-path output with no variable-scope bug; firing test checks both directions; deterministic success only. LOWs (all acceptable, none fixed): grep -cF is line-granular (can't realistically be gamed — commands are on separate lines); inline mypy/pytest config hints redirected to pyproject.toml (not lost); no trap-cleanup in the new test (consistent with every sibling test script).

## Gate Compliance

`<!-- gate-log:phase-60 direction=user-waived delivery=accepted -->`. Direction gate: user-waived (explicit USER OVERRIDE — authorized autonomous completion). Delivery gate: accepted (user pre-authorized completion; delivery report generated + summary presented). 2-gate model satisfied.

## Related

- [[phase-60-harness-activation-residuals|Phase 60: Harness Activation Residuals]] — parent phase
- [[phase-57-hook-consolidation-and-enforcement-activation|Phase 57]] — Fix 1, opened the harness-activation roadmap
- [[cut-active-research-step-2-7|Phase 59 CUT]] — Fix 2, the subtraction-test precedent this phase's no-eval decision extends

## Soft Observations / Phase N+1 Candidates

- The instruction-budget claim at `templates/AGENTS.md:84` ("~300 always-loaded lines degrade instruction-following") is asserted but never measured. A genuine research phase (judge-scored instruction-following with long vs short always-loaded context) would either confirm the ceiling or retire the comment. | Candidate: measure the always-loaded-budget effect. | evidence: the claim drives the budget caps but has no data.
- The harness-activation roadmap (Fixes 1–5) is now CLOSED. The two remaining substantive roadmap items are the **vector-search-default-on design call** (does the 91%→~95% recall gain justify adding the sqlite-vec dep that broke `make test` in P56–58?) and **gap 4.1 language-agnostic core** (factor py-* out; the kit still assumes Python — AGENTS.md is hard-Python, AGENTS-ts.md is a parallel file). | Candidate: Phase 61 = one of those two. | evidence: roadmap-gap-analysis 4.1 OPEN; What-NOT-to-build lists FTS5-as-sufficient.
- The kit still has no committed per-project `.claude/settings.json` — it dogfoods via global wiring (deferred since Phase 57). Symptom surfaced here: the Fix 5 nudge fires in every non-nana dir Jake opens (one low-noise line; accepted). | Candidate: give the kit its own per-project settings + marker. | evidence: ~/.claude/settings.json references session-start globally.
- AGENTS-ts.md already had a ≤95-line budget test; AGENTS.md only got one this phase. The two now both have budget asserts but with different caps and duplicated assertion logic. | Candidate: extract a shared "always-loaded budget" assertion helper if a third surface appears. | evidence: test_templates.sh has two near-identical budget blocks.
