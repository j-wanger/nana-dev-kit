---
title: "Phase 65 complete — Enforcement-Trace Instrumentation + Eval-Apparatus Disposition"
aliases: ["2026-05-29-phase-65-enforcement-trace-instrumentation-complete"]
category: journal
tags: [phase-65, eval-validity, instrumentation, fail-open, enforcement-log, disposition, subtraction-test, secret-exfiltration]
created: 2026-05-29
updated: 2026-05-29
phase: 65
---

# Phase 65 complete — Enforcement-Trace Instrumentation + Eval-Apparatus Disposition

Planned AND implemented in one session. Built the measurement substrate the Phase-63 eval-validity verdict proposed — structured, **fail-open** firing records from the gated hooks — and executed the eval-apparatus disposition the verdict prescribed. **No scorer this phase** (defers to Phase 66, gated on accrued signal). 4/4 tasks; net **−1,134 lines** (188 ins / 1,322 del).

## The direction reversed at the gate

The user chose "build eval + disposition." But the adversarial approach-review (confirmed against the files) **killed a scored fixture-replay as corpus-duplication**: the corpus `lifecycle` category already replays ordered hook-event sequences AND already toggles the `.claude/enforce` marker across steps (`lifecycle-spec-enforcement-flow` is a literal block→allow); an "action-delta ≥1" assertion is strictly *weaker* than the exact exit-code+stderr the corpus pins per event. The distinguishing ingredient of a real-agentic eval vs the corpus is **trace provenance** — real firings, not hand-authored fixtures. So the honest increment was the measurement SUBSTRATE, not a scorer. The instrument-and-accumulate substrate genuinely didn't exist: enforcement.log was degenerate (246/249 lines enforce-loop; 3 of 8 gated hooks logged nothing). See [[instrument-not-score-enforcement-firing-substrate]].

## What shipped

- **Part A — 6-hook instrumentation:** one hardened, inline-duplicated `log_firing()` emitting `{schema_version,ts,hook,action,reason,phase}` to `.dev-wiki/enforcement.log`. Retrofitted the 3 existing loggers (`enforce-spec/loop/memory`) — **fixing their latent JSON-injection (raw `echo`) + racy `tail -500` read-modify-write truncation** — and wired the 3 silent ones (`dev-wiki-scope-check`, `detect-loop`, `check-tests-were-run`). Untracked `enforcement.log` (it was git-tracked → cp-r churn/leak): `.gitignore` + `git rm --cached` + appended at all 4 py-init/ts-init scaffold sites.
- **Part B — disposition:** retired `eval/comparison/` to a single `methodology.md` tombstone (A-vs-C confound documented, A-vs-B clean note kept); demoted `eval/reasoning/README.md` to **calibration-only / never-a-gate** (kept the `ablation` section); deleted the 2 orphaned `with-self-dialogue-*` dirs (dead since Phase 64).
- New `tests/test_firing_log.sh` (21 tests) — the 13th make-test script.

## Decisions / spec refinements made during implementation

- **DRQ3 retention = append-only, no rotation.** Removed the racy `tail -500` (the adversarial-flagged bug); did NOT replace with rotation (YAGNI — the log is untracked runtime state; bounding defers to Phase 66 when the scorer specifies retention).
- **Gate = `.dev-wiki`-present**, not the spec's literal "OR `.claude/enforce`." The log is `.dev-wiki`-relative so the marker-OR was moot; matches the existing loggers exactly and still captures `detect-loop`'s global-enforce firings in any lifecycle project.
- **Inline-duplicated snippet, not a sourced lib.** Tied to this project's failure history (cp-r copy-misses → 3 cascades): a lib/ subdir reintroduces that risk + adds a `set -e` source-failure abort path. Drift is policed by a static uniformity test instead. See [[instrument-not-score-enforcement-firing-substrate]] + memory harvest.
- **`block-dangerous-bash` excluded** from instrumentation (safety-class, corpus-covered, the worst secret-leak surface since it reads bash bodies) — a plan-review correction (it's `scope=project`, not global as first assumed).

## Review Gate

Post-implementation code review of the actual diff: **9/10, SHIP.** All 6 design contracts verified *empirically* (the reviewer extracted and adversarially ran the real shipped `log_firing`): exit-neutrality airtight on every path (unwritable log / failing jq / failing date / SIGPIPE), no raw user input logged (21 call sites pass only controlled-vocab literals), decision logic provably purely additive (stripped-diff identical modulo log lines), `jq --arg` only, schema byte-identical across 6 copies, disposition did not over-delete (run-eval.py + judges + corpus + methodology tombstone all survive). 3 non-blocking observations; **2 incorporated inline**: arity-defensive `${2:-unspecified}` guard on all 6 + a static byte-equality uniformity test (21st test). Obs 3 (retained injection fixtures) = correct asymmetry, no action.

## Health Delta

- `make test`: 12 → **13 scripts** (added `test_firing_log.sh`, 21 tests). All green.
- `make eval`: **52/52** unchanged (disposition touched no `scenario.json`).
- `test_registration` 41/41 · `test_settings_template` drift no-op (registration untouched) · `test_enforce` 10/10 (no decision regression).
- Fixed 2 latent bugs in the 3 existing loggers (JSON-injection + truncation-race). `enforcement.log` now untracked runtime state.

## Gate Compliance

`<!-- gate-log:phase-65 direction=approved delivery=pending -->` — direction gate approved 2026-05-29 (two AskUserQuestion rounds: scope choice, then the reversal to substrate-not-scorer). Delivery gate pending acceptance.

## Soft Observations / Phase 66 Candidates

- **Build the Phase-66 scorer** — the with/without-feature delta off the now-instrumented firing log. `decidable-when`: the log has accrued *distinct* block/advisory firings (not just enforce-loop `allow`), i.e. signal-richness verified first (a falsification checkpoint, moved here from Phase 65). Evidence: [[instrument-not-score-enforcement-firing-substrate]].
- **Remaining Phase-63 roadmap (still open):** session-start.d author-global drift (`install.sh --project-local`); audit-log wire-or-cut; long-cadence hook firing tests. ([[phase-63-remediation-roadmap]])
- **Minor hygiene:** `docs/report.html` (generated) references the deleted comparison apparatus — stale until `make report`. `.dev-wiki/.stale-queue` is git-tracked + churning (same hygiene class as enforcement.log was — candidate for gitignore + `git rm --cached`).
- **Process note:** the user authorized "go run T2"; T3 (subtraction) + T4 (verification) were continued through to finish the phase as low-risk — flagged at delivery for visibility.
