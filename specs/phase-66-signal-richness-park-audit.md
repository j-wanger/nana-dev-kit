<!-- nana:approved 2026-05-29 -->
# Spec: Phase 66 — Signal-Richness Falsification + Scorer Park + audit-log Disposition

## Objective
Verify deterministically whether the enforcement-firing log has accrued enough real signal to build a "did-a-component-fire-and-change-an-action" scorer; since it has not, ship a re-checkable probe that encodes the gate, park the scorer behind a design-gated trigger, and resolve the disposition of the registered-but-unconsumed `audit-log` hook. No scorer is built this phase.

## Context
Phase 65 instrumented 6 lifecycle hooks (enforce-spec/enforce-loop/enforce-memory/dev-wiki-scope-check/detect-loop/check-tests-were-run) to emit fail-open `{schema_version,ts,hook,action,reason,phase}` records to `.dev-wiki/enforcement.log`. Phase 66 was planned as "build the real-agentic scorer" (the with/without-feature delta on observed agent actions), explicitly **gated** on a falsification checkpoint: first confirm the log accrued signal-rich real data.

That gate was measured on 2026-05-29 and **failed decisively**. Of the entire log, only **11 records are new-format** (`schema_version=1`): all from a **single hook** (dev-wiki-scope-check), **zero `block`** (action-changing) firings, only 7 `advisory` + 4 `skipped`, all stamped `phase:"65"` — i.e. 100% intra-phase self-traffic from the maintainer editing the kit. The 253 enforce-loop + 23 block records that *look* like signal are all **pre-instrumentation legacy format** (no `schema_version`, no `phase`) and are not what a scorer consumes. The scorer is unbuildable for four stacked reasons, three of which time does not fix: (1) volume; (2) skew (0 blocks, 1 hook, 5/6 hooks silent); (3) **representativeness** — this log lives in the *kit's own* `.dev-wiki/` and samples the maintainer editing the kit, never the consuming-project agentic work enforcement governs; (4) **schema gap** — the record captures the hook's *decision*, not the agent's subsequent *action*, so "change-an-action" is not computable without a schema extension + counterfactual.

The user approved (dev-plan direction gate, 2026-05-29) reframing the phase from "build" to **falsify + park + redirect**, redirecting build effort to the long-open `audit-log` disposition. This is self-referential work: the harness is both the artifact under test and the tool doing the test.

## Scope
### In scope
- A read-only `scripts/signal-richness-probe.sh [logpath]` that classifies log records and emits a SCOREABLE / NOT-SCOREABLE / NO-DATA / CORRUPT verdict, plus a functional-smoke test wired into `make test`.
- Parking the scorer: a design-gated trigger + the 4-reason verdict recorded in `_CURRENT_STATE.md` Blockers, a decision article, and `active-knowledge.md`.
- `audit-log` disposition: investigate consumer/value, decide keep-or-cut with written rationale, execute the chosen path with a full reference sweep.
- Reconciling `templates/.claude/rules/file-lifecycle.md` audit-log claim with reality (either path).
- Surfacing (and, only if a clear one-line bug, fixing) the duplicate-tuple pattern in dev-wiki-scope-check records.

### Out of scope
- **Any scorer code** — no with/without-feature run, no quality/delta score, no new graded eval scenario. (Settled: a scored fixture-replay duplicates the corpus.)
- Extending the firing-record schema to capture agent response (that is a precondition for a *future* scorer, recorded in the park, not built here).
- Fixing the historical silence of the other 5 hooks (already proven live by `test_firing_log.sh`; silence = no cause to fire).
- Re-tracking or truncating `enforcement.log` (gitignored; left as-is).
- Promoting `.nana/audit.jsonl` into the firing-log family or the scorer's input set.
- Diagnosing the off-roster `dev-debrief` writer beyond classifying it in the probe output.

## Approach
Build a single deterministic reporter over the real log (prior art: `scripts/harness-audit.sh`, `scripts/eval-runner.sh`). It reads records, classifies each line into one of {new-format, legacy-enforce, debrief-completion, malformed/off-roster}, and computes the signal predicate **only over new-format records**: distinct hooks that fired, count of action-changing (`block`) firings, and a duplicate-tuple rate. It emits an explicit verdict so re-checking the gate is one command, not a re-derivation. The threshold that defines "scoreable" is documented in the script and pinned by the test; today's real log must return NOT-SCOREABLE, and that expected verdict is itself a regression assertion so a future loosening is caught.

Park the scorer as a committed, re-runnable predicate (the probe) — not a calendar note — and record that the trigger requires more than volume: real consuming-project provenance AND a schema that captures agent response. The `audit-log` disposition is decided on subtraction-test evidence gathered during execution (intended consumer is human forensic review of an installed project, judged on that basis — not on grepping for in-repo readers), then executed end-to-end including the eval-corpus and registration reconciliation that any change to a registered hook forces.

### Domain Research Questions
1. What is the minimal honest "scoreable" predicate? (Candidate: ≥2 distinct hooks AND ≥1 `block` firing in new-format records after tuple-dedup — `advisory`/`skipped`/`allow` are non-action-changing by definition, and one prolific hook can never satisfy it.)
2. Is the duplicate-tuple pattern a double-emit bug in dev-wiki-scope-check (one-line fix) or two legitimate same-second out-of-scope edits (indistinguishable at second resolution)? Read the hook; fix only if the code clearly calls the logger twice.
3. For `audit-log`: who is the intended consumer of `.nana/audit.jsonl`, and does that consumer justify the registration + eval-corpus + doc surface — independent of whether any in-repo code reads it?

## Constraints (CRITICAL)
- **No silent scorer rebuild** — the probe must only COUNT/CLASSIFY existing records (read-only over real provenance). It must NOT run the harness ON-vs-OFF, author new fixtures, or emit a quality/delta score. Guard: no new `eval/corpus/*` scenario whose grader computes an action-delta; probe opens the log read-only and never writes/truncates `enforcement.log`.
- **Signal predicate must reject degenerate samples** — a vague "≥N records / ≥M hooks present" passes on today's 270-line file because 259 legacy records inflate it. Guard: compute the predicate over `schema_version`-bearing records ONLY, require ≥2 distinct hooks AND ≥1 `block`, and pin "current real log ⇒ NOT-SCOREABLE" as a test assertion.
- **`schema_version` is the new/old discriminator, not `phase`** — legacy records lack both; keying on `phase` would misclassify a future legacy-shaped write. Guard: test includes a legacy record (no `schema_version`) and asserts it is excluded from every signal numerator.
- **Three distinct negative verdicts** — absent log ≠ insufficient signal ≠ corrupt/unparseable. Guard: probe returns NO-DATA (absent/empty), NOT-SCOREABLE (parseable but below predicate), and CORRUPT as separate states. Pin the CORRUPT threshold: **>50% of non-empty lines fail JSON parse ⇒ CORRUPT**; at-or-below 50%, malformed lines are reported as a classification bucket but do NOT flip the verdict (the valid records still decide SCOREABLE/NOT-SCOREABLE). Test covers all three states plus the just-below/just-above-50% boundary.
- **Duplicate-tuple honesty** — every multi-event new-format timestamp currently appears exactly twice (byte-identical). Guard: probe dedups on the full `{hook,ts,action,reason}` tuple before counting AND reports the raw duplicate rate, so the verdict can't be inflated 2× and the anomaly is visible. Because the dedup key includes `reason`, two legitimate same-second edits with *different* reasons survive (not under-counted) — the test must pin this with a same-ts-distinct-reason case that is NOT collapsed. Do not silently collapse "buggy double-write" and "low volume" into one diagnosis.
- **Off-roster writers are a finding, not signal** — `dev-debrief` writes a different schema (`{event:"debrief",...}`) into the same log. Guard: probe classifies and reports such lines; they never count toward the signal predicate.
- **The park must be falsifiable and re-checkable** — guard: the trigger is the committed probe's PASS condition (green ⇒ revisit the scorer), recorded in the decision article + Blockers, not a prose "come back later." A deferral that can't be expressed as a runnable check is rejected.
- **audit-log disposition reconciles ALL coupled surfaces atomically** — it is registered in `modules.json` (source of truth), `templates/.claude/settings.json` (GENERATED — regenerate via `make template`/`register-settings.py`, never hand-edit), `install.sh --project-local` help, and `eval/corpus/{hook-audit-log-write,hook-audit-log-no-file}` + `lifecycle-full-session-flow`. Guard: a CUT must sweep all of these in one change; `test_registration.sh` (bidirectional invariant) and `test_settings_template.sh` (drift) must stay green; `make eval` must land on the count implied by the chosen path (52 if kept, 50 if the 2 scenarios are deleted — per the dynamic-count rule, assert the new number, don't hunt for a literal).
- **Don't delete a human-facing trail by code-utility** — `.nana/audit.jsonl` value is forensic (human "which model edited which file when"), not a code consumer. Guard: if KEEP, state the human consumer explicitly so a later phase doesn't re-flag it as dead code; if CUT, the rationale must address the forensic use, not just "nothing reads it."
- **Do not reintroduce a raw-path secret surface** — `audit-log.sh` interpolates the raw `$FILE_PATH` into JSON via `printf` (not the `jq --arg` controlled-vocab discipline the enforcement.log hardening enforced). Guard (positive, not a no-op): the disposition decision article must explicitly acknowledge this raw-path surface and state how each path handles it — KEEP accepts it as project-local opt-in observability (or hardens it) with the trade-off named; CUT removes it. Plus: keep `.nana/audit.jsonl` out of the scorer's input and out of the firing-log family; do not "upgrade" it into `enforcement.log` without the same controlled-vocab treatment.

## Success Vision
Re-checking "is the scorer buildable yet?" is a single command that returns an unambiguous, honest verdict and refuses to be fooled by 259 legacy lines or a 2× double-write. The reason the scorer isn't built is captured so precisely — four stacked causes, two structural — that a future maintainer doesn't re-derive the analysis or re-attempt the build prematurely; they run the probe, see NOT-SCOREABLE, read the two structural blockers, and know exactly what must change first. The `audit-log` question that has sat open since Phase 63 is closed with a decision that names its consumer and survives the next deadweight sweep. Nothing inert ships; nothing live is deleted; the test and eval gates reflect the new reality exactly.

## Exit Criteria (machine-checkable)
- [ ] `bash scripts/signal-richness-probe.sh .dev-wiki/enforcement.log | grep -q 'NOT-SCOREABLE'` (current real log returns the expected negative verdict)
- [ ] `bash scripts/signal-richness-probe.sh /nonexistent/log 2>&1 | grep -q 'NO-DATA'` (absent log distinguished from insufficient)
- [ ] `bash tests/test_signal_richness_probe.sh` exits 0 (functional-smoke: empty / all-legacy / mixed-scoreable / corrupt / duplicate-tuple cases asserted)
- [ ] `grep -q test_signal_richness_probe Makefile` (probe test wired into `make test`)
- [ ] `make test` exits 0 with 15 test scripts green (audit-log KEPT → both `test_signal_richness_probe.sh` and `test_audit_log.sh` added, 13→15)
- [ ] `make eval` exits 0 at the count implied by the audit-log disposition (52 kept / 50 cut)
- [ ] `bash tests/test_registration.sh && bash tests/test_settings_template.sh` exit 0 — registration↔filesystem and generated-settings invariants intact; these existing tests are what guard against a *half-done* disposition (file removed but still registered, or vice versa), so no separate keep/cut-consistency criterion is needed
- [ ] Park verdict + both structural blockers recorded (not just one stray token): `grep -q NOT-SCOREABLE .dev-wiki/_CURRENT_STATE.md && grep -qi 'representativ' .dev-wiki/_CURRENT_STATE.md && grep -qiE 'schema.gap|agent.response' .dev-wiki/_CURRENT_STATE.md`
- [ ] Decision article carries a real decision, not a stub: `D=$(ls .dev-wiki/articles/decisions/*audit* 2>/dev/null | head -1); test -n "$D" && grep -qiE 'keep|cut' "$D" && grep -qi 'forensic\|consumer' "$D" && grep -qiE 'FILE_PATH|raw.?path' "$D"` (verdict + named human consumer + raw-path surface all present in the body)
- [ ] No dangling references: `bash scripts/harness-audit.sh` reports no DRIFT introduced (or, if CUT, no `audit-log` ref survives outside the decision article + journal record)

## Checkpoints
- After the probe + test are green and the verdict reproduces NOT-SCOREABLE on the real log: report the classification breakdown (new / legacy / debrief / malformed counts) before moving to the disposition.
- After investigating the duplicate-tuple pattern: report whether it is a one-line double-call (fix under DISCOVERY, add regression assertion) or same-second-edits/ambiguous (note as caveat, no fix). Do NOT expand scope to a dev-wiki-scope-check refactor.
- Before executing the audit-log disposition: report the keep-vs-cut decision with its evidence and the full list of surfaces the chosen path will touch. If CUT, confirm the eval count delta and the lifecycle-scenario rewire plan before deleting anything.
- If any deletion would dangle a `source:`/`[[…]]` link in working/active-knowledge or a test depends on the target: STOP and reconcile (or choose KEEP).

## Assumptions
- The probe can deterministically separate new-format from legacy records via `schema_version`. If false (records exist that are scoreable but lack `schema_version`): STOP — the falsification isn't reproducible and the park is unfounded; re-examine the Phase-65 record format before parking.
- `test_firing_log.sh` already proves each of the 6 hooks emits a well-formed record when fired (liveness covered). If false (some hook's emit path is actually broken): that is a Phase-65 regression — log it as a Blocker and surface, don't silently absorb it into "no signal."
- `audit-log` is not hardcoded in py-init/ts-init (they copy generically from `modules.json`). If false: add those skill files to the disposition's reference sweep.
- `make eval` total is computed dynamically from the scenario count (per `eval-total-is-dynamic`). If false (a hardcoded total exists): update that literal as part of a CUT and note the deviation.
- The current 11 new-format records are entirely intra-phase self-traffic (`phase:"65"`). If a later run shows consuming-project provenance already accruing: note it in the park — the representativeness blocker may be closer to resolved than assumed.
