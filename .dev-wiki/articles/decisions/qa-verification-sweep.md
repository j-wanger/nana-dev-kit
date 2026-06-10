---
title: "QA & Verification Sweep (ultracode)"
aliases: [qa-sweep, phase-82-qa]
category: decisions
tags: [qa, verification, multi-agent, coverage, silent-breakage, heu-012]
parents: [phase-82-qa-verification-sweep]
created: 2026-06-09
updated: 2026-06-09
source: debrief
confidence: high
---

## Context

Jake invoked `/dev-plan` with "ultracode mode and do QA and checks on the project implementation." make test (20 scripts, ~450 assertions) and make eval (52/52) are green, so the sweep's value lies in what the deterministic suites do NOT cover — the project's recurring silent-breakage class (registered-but-dormant hooks, the 30+-phase wrong-CWD MCP config, the eroded line cap no test asserted). Planning itself already surfaced one finding: a 6-file installed-copy drift (~/.claude ran the pre-Phase-81 dev-plan/dev-debrief) — found by check-install-drift.sh, resynced via install.sh during planning. Phase 82 is the first live dogfood of the Phase-81 assumption-approval gate.

## Decision

A coverage-defined, two-stage multi-agent sweep (spec: specs/phase-82-qa-verification-sweep.md, nana:approved): controls-first baseline (every checker vouching for a `clean` verdict must first catch a seeded synthetic defect — instrument-dead otherwise), then a 7-area read-only audit fan-out (wiring / firing / companions / schema / drift / coverage / docs) via the Workflow tool, then adversarial verification under an executed-command evidence standard with orchestrator RE-EXECUTION of every clean-row command (the in-kit working-knowledge context leak makes subagent prose AND subagent-reported transcripts inadmissible for clean verdicts — Ph80 recitation class plus the fabrication hole), then serialized single-writer fixes under a pre-registered boundary: kit-managed + non-frozen + S/M + test-covered blast radius; coverage-gap exception — writing the missing S/M functional test IS the fix (functional-smoke invariant); >10 confirmed defects → stop and re-scope. Deliverable: eval/qa-sweep/verification-matrix.md (`| area | command | evidence | verdict |`, enum clean/defect-found/deferred/instrument-dead) where verified-clean is mechanically distinguishable from never-checked.

Rejected alternatives: (a) permanently extending make test directly as the phase — the sweep produces the verified gap list that test-writing consumes; the coverage exception closes the S/M portion in-pass; (b) depth-first audit of only the newest surface (Phase-81 artifacts) — breadth is the point when the suites are green; the Phase-81 surface is instead quarantined (ledger read-only, gate defects confirmed via --selftest and filed).

## Gate outcome (first live dogfood of the Phase-81 assumption-approval gate)

The gate did real work — NOT a rubber-stamp. Round 1: A1 don't-know (Jake named a missing axis: utilization — "is the MCP memory server even used?") → resolved by adding the eighth `usage` area feeding Phase-79 prune-on-value; A2 REJECT (leak-is-acceptable-with-re-execution not believed) → resolved by demoting subagents to candidate-generators with orchestrator-executed commands as sole verdict evidence; A3/A4 accept. Round 2: revised A1'/A2' both accepted. Ledger block appended (6 rows, all_accept: false); both revisions are spec-recorded.

## Outcome (realized 2026-06-09)

58 candidates from the 8-agent fan-out → 35 fixed / 20 deferred-with-filings / 3 orphans routed to the subtraction list. The >10-confirmed-defects STOP fired as pre-registered; Jake re-scoped, selecting ALL 4 clusters before any fix was applied. Headline finds: the enforcement layer dormant since 05-25 (compound — event-shape + missing marker + allowlist bypass + em-dash slug; see [[hook-event-shape-normalization]]) and 11 project-scoped hooks running stale in ~/.claude invisible to the scope-tagged drift comparison (see [[drift-compare-installed-presence]]). Reviewer 9/10 accept; findings fixed inline (2 pipe tests, count residue, SIGPIPE, smoke-note). Close: make test 20→22 scripts all green, make eval 52/52, drift 0 under the EXTENDED comparison set, 10/10 spec exit criteria via run-exit-criteria.sh.

## Consequences

Zero confirmed defects is a valid success — the phase succeeds on coverage evidence, not defect count, so agents must not manufacture findings. The frozen eval apparatus (eval/amplifier/*, eval/assumption-screen/) is read-only; findings there are filed. The planning-time resync gets a retrospective git-history audit (was any overwritten installed copy an unbackported hot-fix?). Fix definition-of-done couples repo and runtime: both copies converged + MANIFEST/make-template regen in the same change, preventing the fixed-in-repo-broken-in-runtime seam. The verification matrix becomes the durable record future phases can consult for "what was actually verified when."
