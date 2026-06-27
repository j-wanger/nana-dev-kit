---
title: "Host-gate out-of-workspace hardening (bash + alt-named write coverage)"
aliases: [host-gate-out-of-workspace-hardening, host-gate-coverage, bash-write-gating, out-of-workspace-deny]
category: decisions
tags: [security, gate, host-gate, workspace-boundary, bash, engine-adapter, phase-111]
parents: [phase-111-typed-artifact-fidelity]
created: 2026-06-27
updated: 2026-06-27
source: debrief
confidence: high
---

## Context

Capturing the Phase-111 regression baseline exposed a REAL host-gate coverage gap. `createHostGate` enforced the workspace boundary ONLY for the write/edit tool carrying an `args.path` key (`app/src/gate/host-gate.ts`). Two classes BYPASSED it — deterministically confirmed at the gate boundary, no model in the loop:
- **bash file-writes** — `echo > /outside`, `tee /outside`, `cp x /outside`, `mv x /outside`, `dd of=/outside`;
- **alternately-named write tools** — `write_file` / `apply_patch` with an out-of-workspace `args.path`.

Ph108's "empirically un-bypassable" claim was **happy-path-only**: the local model usually emits `write`+`path`, which the gate DOES deny (2/2 live), so the gap never surfaced in the demo. The flaky `provider-roundtrip` e2e was intermittently catching it; the as-planned T4 ("soften the assertion") would have **MASKED** a real hole. The maintainer directed (AskUserQuestion) "fold a gate fix into Phase 111" — a SECURITY escape-hatch scope amendment (ledger A5).

## Decision

Extend the base-policy **COVERAGE** (NOT the verdict-loop core) along three axes:
- **(a) default branch** applies `isOutsideWorkspace` to `PATH_ARG_KEYS` args — robust, covers alt-named write tools by argument shape rather than tool name;
- **(b) bash branch** denies out-of-workspace write targets via `extractBashWriteTargets` (redirect `>` / `>>` / `&>` / `>|` / `N>`, `tee`, `cp`/`mv` dest, `dd of=`);
- **(c) DEV_SINK exemption** (`/dev/null|zero|stdout|stderr|tty|fd/N`) so common idioms like `2>/dev/null` aren't over-blocked.

Out-of-workspace writes are **confirmable** (not hard-denied) — consistent with the existing write/edit out-of-workspace policy: a human can approve a legitimate out-of-workspace write. The gate VERDICT-LOOP core (`confirmingGate` / `ConfirmationBroker` / key-store hard-deny — [[gate-confirm-approve-loop]]) is UNCHANGED.

### Alternatives considered
- **Hard-deny vs confirmable** — chose confirmable (symmetric with the existing write/edit policy; a human can approve a legit out-of-workspace write).
- **Separate SECURITY hotfix phase vs fold-in** — maintainer chose fold-in (the baseline surfaced the gap mid-phase; T4 reshaped from "pin the flaky e2e" → "close the gap", reordered FIRST as security-bearing + deterministic + model-free).

## Consequences

- Closed the demonstrated + common vectors deterministically — `tests/gate/host-gate-coverage.test.ts`, 24 cases (20 baseline-vector + 4 adversarial-review regressions).
- **Corrected the Ph108 "empirically un-bypassable" over-claim** (memory + journal) — it was happy-path-only.
- An adversarial finder×refuter review (8 raised → 2 confirmed + 1 self-verified → fixed) caught a `/dev/null` over-block (alert-fatigue regression) AND a `>|` force-clobber write-evasion that the 24 passing gate tests missed — both fixed before commit.
- **HONEST RESIDUAL (the weakest part):** string-gating arbitrary bash is INCOMPLETE BY NATURE — `python -c` / `node -e` / base64-decoded paths / env indirection still evade. The COMPLETE fix is OS-sandboxing bash's filesystem to the workspace, routed to a follow-on phase (Phase-112 candidate). This does NOT claim bash is bulletproof; the residual is documented inline + filed to Blockers.
- Gate-design principle banked: hardening a confirmation gate must measure the FALSE-POSITIVE rate on common idioms — an over-broad deny is a security regression via desensitization (alert fatigue), not just a UX nit.

## Source

Phase 111 debrief (2026-06-27). SECURITY escape-hatch fold-in (ledger A5, revisit-status: open — residual acceptable confirmed at the delivery gate). Builds on [[engine-adapter-in-process-gate]] (the in-process gate site), [[gate-confirm-approve-loop]] (verdict-loop core, unchanged), [[typed-artifact-fidelity]] (the diff thread T4 rode alongside).
