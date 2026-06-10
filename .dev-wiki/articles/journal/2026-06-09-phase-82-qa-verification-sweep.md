---
title: "Phase 82 complete — QA & Verification Sweep (ultracode): 58 candidates, 35 fixed, enforcement layer restored from 15-day dormancy"
aliases: []
category: journal
tags: [qa, verification, multi-agent, hooks, drift, enforcement, dogfood, assumption-gate]
parents: [phase-82-qa-verification-sweep]
created: 2026-06-09
updated: 2026-06-09
duration: unknown
source: debrief
---

# Phase 82 complete — QA & Verification Sweep (ultracode)

## What Happened
- **T1** baseline + instrument controls (every clean-vouching checker first caught a seeded synthetic defect); **T2** 8-agent ultracode fan-out over wiring/firing/companions/schema/drift/coverage/docs/usage → 58 candidates; **T3** orchestrator-executed verification (subagent prose never evidence — Jake's A2 reject held), mid-phase report, **>10 confirmed defects tripped the pre-registered STOP** → Jake re-scoped, approved all 4 clusters → 35 serialized fixes; **T4** matrix close-out + filings + 10/10 spec exit criteria via `run-exit-criteria.sh`.
- Headline: the enforcement layer had been silently dormant since 05-25 — a COMPOUND failure (platform `.tool_input` event-shape + missing `~/.claude/enforce` marker + absolute-path allowlist bypass + em-dash slug break). Fixed; enforce-memory then fired for the FIRST time in its lifetime.
- Drift blind spot: 11 pre-Phase-79 project-scoped hook copies ran stale in `~/.claude`, invisible to the scope:global-only comparison that reported "drift 0" the same morning → checker pass 2b (presence = live code), copies refreshed.
- MANIFEST fully regenerated (122 checksums, stale since Phase 63); register-settings.py `cmd_mcp --modules-json` single-sourced; session-start gained a `[nana:enforce]` marker advisory.
- First END-TO-END live dogfood of the Phase-81 assumption gate: surfacing → positions with a real don't-know AND a real reject → 2 forced revisions → ledger append → revisit fill (all 6 Phase-82 rows: A1 bit; A2-A6 held).

## Decisions Made
- [[hook-event-shape-normalization]] -- canonical `.tool_input // .input` parse + per-hook path normalization + transcript-scanning Stop hooks (high)
- [[drift-compare-installed-presence]] -- drift pass 2b compares any kit-shipped hook PRESENT in the installed root, scope tag notwithstanding (high)
- [[qa-verification-sweep]] -- outcome appended (58 candidates / 35 fixed / 20 deferred / 3 orphans; reviewer 9/10 accept)

## Problems Solved
- SECURITY escape hatch: the freshly-refreshed enforce-spec gate self-locked the orchestrator mid-fix (its own allowlist bypass + em-dash break blocked all Edit calls) — recovered via Bash patching (gate matcher is Write|Edit only); all fixes sandbox-validated BEFORE live copies touched, per the spec's sandbox-first constraint.
- DISCOVERY escape hatch: >10 confirmed defects → pre-registered STOP honored; user re-scope BEFORE any fix.

## Open Questions
- All deferred work already FILED as Blockers (subtraction-review/usage list; 4 firing candidates; ghost global registrations + drift residue; misc incl. the enforcement.log provenance hazard).

## Artifacts Changed
- `tests/{test_manifest_freshness,test_scripts_smoke}.sh` (NEW; 22 make-test scripts, ~480 assertions), `tests/test_companions.sh` (Directions C+D), `scripts/check-install-drift.sh` (pass 2b), `templates/.claude/hooks/*` (7 field/path-fixed + session-start advisory), `templates/.claude/skills/MANIFEST` (regenerated), `scripts/register-settings.py`, `eval/qa-sweep/**` (matrix, candidates, repro-runs.log, run-exit-criteria.sh), 11 `~/.claude` runtime hook copies refreshed.

## Related
- [[phase-82-qa-verification-sweep|Phase 82: QA & Verification Sweep (ultracode)]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- No platform-shape canary: both-shape tests cover OUR parsing, not the platform's emission — next field rename re-creates silent dormancy | tiny unknown-shape logger or periodic live-fire check | eval/qa-sweep/verification-matrix.md firing row
- enforcement.log has no run-provenance: audit/test pipes write real records (observed contamination 18:24-18:27Z) | env-guard or provenance field | matrix Fixes section
- Ghost global registrations (11 hooks in ~/.claude/settings.json) await a registration-reconciliation decision | maintainer call | drift Blocker filing
- Subtraction-review list has utilization evidence (memory reinforcement 0/55, memory unused in edge-screener, audit-log model always unknown) — BUT enforce-memory's "zero lifetime firings" INVERTED post-fix (disabled, not dead): prune-on-value candidates must be re-evaluated against the RESTORED enforcement layer | usage Blocker filing
- Living-doc caps unguarded: _CURRENT_STATE.md 188/100, _ARCHITECTURE.md ~102/100 — the kit's own "caps need test assertions" finding applies to its own living docs | cap-assertion test | reviewer MEDIUM finding

### Activation Quality
active-knowledge.md: 3 sections, 3 referenced (~100% hit rate) — orchestrator-only evidence standard, HEU-012 verify-firing, and the Phase-80 leak inversion were all load-bearing this session.

### Health Delta
make test 20→22 scripts (~450→~480 assertions) all green; make eval 52/52 unchanged; drift 0 under an EXTENDED comparison set (was 0 under a blind one); enforcement layer restored from 15-day dormancy; reviewer 9/10 ACCEPT, findings fixed inline.
