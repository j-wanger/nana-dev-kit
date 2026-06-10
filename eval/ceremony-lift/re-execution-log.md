# Re-Execution Log — Phase 86 (orchestrator-executed verdict evidence)

Every entry below was executed by the orchestrator (pre-registration: Admissibility).
Agent prose was used only to locate candidates; verdicts rest on these commands.

### r-ph85-review-gate

**Claim:** Phase-85 review-gate reviewer (8/10) caught 3 stale harness-audit.sh 4b
predicates that false-DRIFTed post-migration; deterministic gates missed it.
**Pre-fix recovery:** git pre-fix state UNRECOVERABLE (fix rode inside commit 5bf2640
— verified: `git diff 5bf2640..3f04979 -- scripts/harness-audit.sh` is EMPTY).
Recovered via TRANSCRIPT-EXTRACTED file state: 4 Edit calls on scripts/harness-audit.sh
in session 74a6533b reverse-applied (4/4 matched) in worktree at 5bf2640.
**Defect present at pre-fix:** `bash scripts/harness-audit.sh` on the reconstructed
state emits false DRIFT rows: "DRIFT: py-init SKILL.md missing recursive/glob cp of
hooks/*.sh" + same for ts-init (both verified exempt-recursive in Phase 85 T1 — the
predicates were stale). Audit exits 0 even with DRIFT rows (advisory).
**Gate counterfactual:** `make test` on the reconstructed pre-fix state: exit 0,
"All tests passed." (26 scripts green on the defective state.)
**Verdict input:** gate passes-where-it-should-fail → outcome-grade-admitted.
**Caveats:** agent-counterfactual residual (implementing agent might have caught it
without the reviewer — unmeasured); audit 4b DRIFT verdict is environment-coupled
(compares against live ~/.claude); post-fix worktree control run also recorded
(make test 0, DRIFT: none).
**Executed:** 2026-06-10, worktree /tmp/ph85-prefix at 5bf2640.

### r-ph82-a1-bit

**Claim:** Phase-82 direction gate surfaced a missing measurement axis (A1
don't-know → utilization area added), feeding Phase-83's prune evidence.
**Verification:** `awk '/^## Phase 82/,/^## Phase 83/' .dev-wiki/assumption-ledger.md
| grep -cE 'revisit-status: bit'` → 1; A5 row text records "REVISES A1: eight areas —
adding a deterministic usage/utilization audit". Ledger schema validates
(check-assumption-ledger.sh --schema exit 0; append-only).
**Verdict input:** deterministic ledger record — CORRECTED at review-gate: outside
the registered outcome-grade taxonomy (no gate counterfactual) → ambiguous-downgrade.
**Caveats:** bit-record verification, not a gate-counterfactual — no downstream
deterministic gate could surface a missing measurement axis; whether a gateless agent
would have found it is unmeasured.

### r-ph83-a2-bit

**Claim:** Phase-83 gate assumption "Phase-82 usage zeros measure absent demand"
PROVED WRONG (4 of 6 zeros were couldnt-fire artifacts) — the arming protocol the
gate forced converted would-be wrong cuts into keeps/hardens.
**Verification:** Phase-83 ledger block: `- A2 | cost: high | position: accept |
revisit-status: bit | "The Phase-82 usage…"` (grep verified); keep/harden verdicts
recorded in the Phase-83 decision article + eval/prune artifacts.
**Verdict input:** ambiguous-downgrade (CORRECTED at review-gate — bit-record basis is outside the registered outcome-grade taxonomy).
**Caveats:** as r-ph82-a1-bit.

### r-ph84-a1-bit

**Claim:** Phase-84 gate assumption "dormant-hook failure signal is recoverable"
PROVED WRONG by live event capture (no exit-code field; no event on failure) —
forced the upstream-filing branch mid-phase.
**Verification:** Phase-84 ledger block: `- A1 | … | revisit-status: bit | "A
success/failure …"` (grep verified).
**Verdict input:** ambiguous-downgrade (CORRECTED at review-gate — bit-record basis is outside the registered outcome-grade taxonomy).
**Caveats:** as r-ph82-a1-bit.

### r-ph85-a2-bit

**Claim:** Phase-85 gate made the duplicate-hook double-fire model conditional on
mandatory empirical verification; DRQ-1 probes revealed string-keyed dedupe (the
accepted model was partially wrong), reshaping the migration design.
**Verification:** Phase-85 ledger block: `- A2 | … | revisit-status: bit |
"Duplicate hook …"` (grep verified); eval/install-gap/drq1-verification.md exists.
**Verdict input:** ambiguous-downgrade (CORRECTED at review-gate — bit-record basis is outside the registered outcome-grade taxonomy).
**Caveats:** as r-ph82-a1-bit.

## Correction (review gate, 2026-06-10)

The four ledger-bit entries above were initially classified outcome-grade-admitted.
The Phase-86 review gate (6/10 revise, CRITICAL) correctly found this widened the
FROZEN pre-registration's outcome-grade definition at tabulation time — bit records
are deterministic and append-only but carry NO gate counterfactual against a pre-fix
state. The controlled blind classifier agrees (bit-shaped rows → ambiguous-downgrade).
All four reclassified per the pinned downgrade rule; the verification greps above
remain valid as AMBIGUOUS-row documentation. Consequence: the pre-registered A2
STOP condition (>50% of outcome-candidate rows downgraded) FIRES on the corrected
counts — re-presented to the maintainer at the corrected checkpoint.
