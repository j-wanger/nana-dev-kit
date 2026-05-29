---
title: "audit-log disposition: KEEP (harden) — a human-facing forensic trail, not code-dead"
aliases: ["audit-log-disposition", "audit-log-keep", "phase-66-audit-log"]
category: decisions
tags: [subtraction-test, audit-log, observability, hooks, jq-arg, phase-66]
parents: [phase-63-remediation-roadmap, park-enforcement-scorer-signal-insufficient]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

`audit-log` (a PostToolUse Write|Edit|MultiEdit hook) appends `{ts,tool,file,model}` to `.nana/audit.jsonl` on every file edit. Phase 63's harness audit flagged it: "produces no `.nana/audit.jsonl` in the live repo," and the Phase-63 roadmap left it as an open **wire-or-cut** item. Phase 66 resolves it on subtraction-test evidence (the hook is the redirect target after the scorer was parked — see [[park-enforcement-scorer-signal-insufficient]]).

## Evidence

- **It FUNCTIONS** — eval-covered by `hook-audit-log-write` and `hook-audit-log-no-file` (both assert `exit_code: 0`; both pass). It produces nothing in the *kit's own* repo only because the kit doesn't run `--project-local` on itself, not because it's broken.
- **No code consumer** of `.nana/audit.jsonl` — `scripts/harness-audit.sh` only existence-checks it (`[ -f "$AUDIT_LOG" ]`, a liveness probe), and `self-test.md` instructs a human to `cat .nana/audit.jsonl`. The intended consumer is a **human doing forensic review** ("which model edited which file when"), not a program.
- **Latent JSON-injection** — `audit-log.sh` interpolates the raw `$FILE_PATH` into JSON via `printf '...{"file":"%s"...}'`. A path containing `"` or a newline corrupts the JSONL line — defeating the forensic purpose — and it is the exact raw-interpolation class Phase 65 hardened out of every other logger.
- **The eval coverage is thin** — both scenarios check only `exit_code: 0`, never the record's shape. So a `tests/` functional-smoke that asserts a jq-valid record adds coverage the corpus lacks, and hardening can't regress the (exit-code-only) scenarios.

## Decision

**KEEP — and harden.**

The "write-only ⇒ deadweight" test that condemned the Phase-64 heuristic counters does **not** apply here. Those counters fed a *dead automated scoring loop* — write-only because their reader never ran. A forensic log read by humans on demand rather than by code is **normal and correct**; "nothing greps it" is not evidence of deadness for an audit trail. Its consumer is the operator inspecting what an AI agent changed — a coherent, low-cost capability, and a natural fit for an audit/provenance-minded user.

Cost-of-error is asymmetric: wrongly CUTTING loses a cheap, **opt-in** (project-local, off-by-default) provenance feature and shrinks eval coverage; wrongly KEEPING carries ~23 lines + 2 scenarios + one doc line. The asymmetry, plus the human-consumer distinction, favors KEEP.

KEEP handles the raw-`$FILE_PATH` surface by **hardening** (`jq --arg`, mirroring the Phase-65 loggers) rather than accepting it — this fixes the real JSON-injection bug and removes the lone unhardened `printf`-interpolating logger in the tree. Plus: a `tests/test_audit_log.sh` functional-smoke (asserts the record shape + injection-safety + the no-file path) and a reconciliation of the over-broad `file-lifecycle.md` claim ("on every file write" → opt-in/project-local).

## Why not CUT

CUT would delete a functioning, eval-covered, human-facing forensic capability on the strength of "no code consumer in the kit's own repo" — the same flawed reasoning the spec's constraint warned against. It would also force a wider, riskier ref-sweep (modules.json + regenerated settings.json + install.sh + docs + 2 eval scenarios → `make eval` 50 + a `lifecycle-full-session-flow` rewire) to remove something cheap and off-by-default. Not justified.

## Source

Phase 66 T3, 2026-05-29. Subtraction-test disposition of the Phase-63 wire-or-cut item. The raw-`$FILE_PATH` injection was found during this investigation (a latent bug, same class as the ones Phase 65 fixed in the enforce loggers).
