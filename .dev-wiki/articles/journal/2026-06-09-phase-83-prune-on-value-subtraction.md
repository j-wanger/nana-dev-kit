---
title: "Phase 83 complete — Prune-on-Value Subtraction: 4 of 6 dead-weight zeros were measurement artifacts; 2 cuts, 2 keeps, 2 hardens activated"
aliases: []
category: journal
tags: [subtraction, harness-right-sizing, utilization-evidence, couldnt-fire, assumption-gate, hooks, memory]
parents: [phase-83-prune-on-value-subtraction]
created: 2026-06-09
updated: 2026-06-09
duration: unknown
source: debrief
---

# Phase 83 complete — Prune-on-Value Subtraction

## What Happened
- **T1** installed-surface DISCOVERY (the A3-reject revision): a kit-marker scan found **4 consuming projects beyond the assumed roots** (ab-test/stock-screener, edge-analyst, fate, ai-game) — removal sets defined first, removal-set-exclusion liveness grep over all 7 roots (LIVE vs HISTORICAL). **T2** per-candidate couldnt-fire/didnt-fire arming in hermetic sandboxes. **T3** unconditional checkpoint: 6 maintainer decisions BEFORE any cut. **T4** serialized execution, one commit per candidate. **T5** close-out: 10/10 spec exit criteria via `eval/prune-on-value/run-exit-criteria.sh`.
- **Headline: 4 of the 6 Phase-82 "dead-weight" zeros were measurement artifacts, not absent demand.** enforce-memory's lifetime zero was the event-shape dormancy — its marker is SHIPPED by install.sh (modules.json, contradicting the always-loaded "NOT shipped" claim, now corrected) and it is firing live (69 enforcement.log records in this very session). memory-reinforcement's 0/55 was a structurally unreachable code branch (no fastembed → cosine>0.90 reinforce impossible; word-overlap fallback only warns). audit-log's model field could never hold a value (CLAUDE_MODEL set by nothing). memory-mcp-scaffold had no per-project surface to be unused.
- Executed: **2 cuts** (audit-log-model-field — maintainer override of a couldnt-fire defect-class finding; orphan-companions — 3 files, exemption list emptied so test_companions Direction C is now stricter, −200 repo lines, 18 installed copies removed across 6 roots), **2 keeps** (enforce-memory, memory-mcp-scaffold), **2 hardens IMPLEMENTED via checkpoint override** (fastembed installed into the live venv, cosine reinforcement verified end-to-end with real nomic embeddings; harness-audit wired as `make audit` + functional smoke).
- Gate dogfood: A3 REJECT forced the discovery-based surface (vindicated by the 4 found projects); A4 don't-know resolved by code evidence; A5 don't-know DOWN-SCOPED (kit-side memory-layer value → Blockers, must-revisit). all_accept: false.

## Decisions Made
- [[prune-on-value-subtraction]] -- evidence-first, verdict-gated, serialized subtraction; outcome appended (high). Checkpoint verdicts in `eval/prune-on-value/verdict-table.md` '## Checkpoint decisions'.

## Problems Solved
- USER OVERRIDE x2 (checkpoint): fastembed install-now over filing; harness-audit wire-in over cut — both ≤ per-cut discipline, explicitly approved at T3.
- DISCOVERY: tests/test_audit_log.sh, Makefile, tests/test_scripts_smoke.sh added to phase scope (removal-set member + wire-in surface); phase article updated in the self-check commit.

## Open Questions
- enforce-memory demand question — now answerable with real data (Blockers: revisit at next prune round with the post-restoration firing distribution).
- A5 kit-side memory-layer value (deferred don't-know; ledger revisit-status: open).
- User-owned ~/.claude/rules/dev-wiki-hooks.md "/dev-harness H6" stale ref (Jake fixes manually).

## Artifacts Changed
- `eval/prune-on-value/{verdict-table.md,liveness-grep.log,arming-runs.log,check-artifacts.sh,run-exit-criteria.sh}` (NEW), `templates/.claude/hooks/audit-log.sh` + `tests/test_audit_log.sh` (cut 1), 3 orphan companions deleted + `tests/test_companions.sh` + `templates/.claude/skills/MANIFEST` (cut 2), `Makefile` (`audit` target) + `tests/test_scripts_smoke.sh` (wire-in), live `~/.claude/memory_server/.venv` (fastembed), 23 installed-surface assertions across 6 roots (DEREG lines).

## Health Delta
- make test: 22 scripts green (+1 harness-audit smoke; companions Direction C stricter). make eval: 52/52 (denominator unchanged — no eval-covered component cut). drift 0. −200 repo lines.

## Related
- [[phase-83-prune-on-value-subtraction|Phase 83: Prune-on-Value Subtraction]] -- parent phase
- [[qa-verification-sweep]] -- produced the consumed evidence (Phase 82)

### Review Gate
Reviewer 9/10 ACCEPT. 5 MEDIUM: stale test_companions comment (fixed), vacuous EC6 eval check (fixed — parses the Score line), cut-1 DEREG lines rode cut-2's commit (historical, disclosed in the commit message), stale always-loaded WK opt-in claim (fixed in place — curated file), close-out arithmetic (fixed: 23 = 5 refreshed + 18 removed). Fixes committed f6c7e8d.

### Gate Compliance
gate-log:phase-83 direction=approved delivery=pending — compliant pre-delivery. Direction gate = assumption-approval (A1-A7, all_accept:false; 1 reject revised, 2 don't-knows resolved: 1 defended, 1 down-scoped). Ledger revisit filled at debrief: A2 **bit** (zeros-measure-demand proved false for 4/6 — the arming protocol caught it), A1/A3/A4/A6/A7 held, A5 open.

### Activation Quality
Active knowledge: 3 source sections, 3 referenced (~100% approximate hit rate, literal match) — HEU-012 zero-classification, gate evidence rules, and binding priors all load-bearing this session.

## Soft Observations / Phase N+1 Candidates
- Filed utilization evidence DECAYS — 4 of 6 Phase-82 zeros dissolved under arming within one phase. Framing: any future prune round must re-arm before trusting filed zeros. Evidence: eval/prune-on-value/arming-runs.log vs the Phase-82 Blockers list.
- enforcement.log now accumulates real post-restoration firing data (69 enforce-memory records in one session) — the enforce-memory demand revisit becomes a cheap deterministic analysis (allow/block ratio, block follow-through). Evidence: .dev-wiki/enforcement.log phase:83 records.
- The kit's installed footprint (7 roots) exceeds what drift tooling tracks (~/.claude only). Framing: extend drift comparison to discovered consuming-project roots — the Phase-76 deferred item (B) re-trigger may be approaching. Evidence: eval/prune-on-value/liveness-grep.log ROOTS lines.
- modules.json ships the enforce-memory marker globally (armed-by-default) while the design intent was opt-in — own the default-on or make it truly opt-in. Evidence: modules.json markers list; verdict-table T1 finding 1.
- generate-delivery-report.py functional smoke still deferred (Phase-82 filing stands — needs a stubbed `make`, M design).
