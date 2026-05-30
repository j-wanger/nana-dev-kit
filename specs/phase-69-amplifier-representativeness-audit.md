<!-- nana:approved 2026-05-29 -->
# Spec: Phase 69 — Amplifier Measurement: Representativeness Audit + Anchor-Validity Verdict

## Objective

Using the validated Phase-68 ruler (`eval/amplifier/emit-proxy-vector.sh`) against REAL consuming-project transcripts, deliver the honest answer the deferred live run cannot yet give: that the instrument's ground-truth detector is non-representative on real data and the same-day-close anchor is degenerate for measuring harness lift — and ship a committed, re-runnable **measurability gate** that specifies (and currently BLOCKS) the conditions a valid harness off/on measurement must satisfy before any expensive Phase-70 live run.

## Context

Phase 68 built and control-validated the ruler against PLANTED ground-truth fixtures (n=1), deliberately deferring everything representativeness-dependent (a live off/on run, n>1, the harness verdict) to Phase 69. Reconnaissance this session ran the ruler READ-ONLY across **the 8 top-level session transcripts spanning 3 `ab-test*` project directories** under `~/.claude/projects/` (`-Users-jwang-ab-test` = 2, `…-ab-test-stock-screener` = 3, `…-ab-test-condition-c-stock-screener` = 3; the transcript set is exactly the `*.jsonl` files at the top level of those 3 dirs — any `*/subagents/*.jsonl` are excluded). Findings: (1) `ground_truth.surfaced == false` on all 8, and AUQ-scoped same-day-close/look-ahead phrase hits == 0 across all 8, while the phrase appears 8–50× in raw assistant text/code — the v1 AskUserQuestion-only escalation predicate is a structural false-negative on real provenance (the exact "revisit in Phase 69" caveat at `eval/amplifier/SCHEMA-NOTES.md` line 50); (2) the look-ahead concept appears substantively even in the harness-OFF baseline transcripts — a textbook stock-screener concern the base model handles unprompted, so there is no harness gap to detect on it (mirrors the Phase-59 commodity-knowledge lesson: retrieval doesn't pay when parametric knowledge is already strong); (3) the existing transcripts are not a clean off/on experiment (evaluation vs build vs full-harness build), and the interaction-proxy deltas are confounded and direction-ambiguous. The user approved Approach A (turn the recon into the deliverable; NO live run; audit-only — do not patch the emitter) via AskUserQuestion on 2026-05-29. The project culture: deterministic validators over neural judges; measurement before optimization; burden-of-proof on the feature; never overclaim a verdict you are not entitled to.

## Scope

### In scope
- `eval/amplifier/survey-real-transcripts.sh` — read-only survey runner; **enumerates exactly the top-level `*.jsonl` of the 3 named `ab-test*` dirs (subagent files excluded) and shasums exactly that pinned set**; emits a per-transcript table.
- `eval/amplifier/real-transcript-survey.md` — the committed empirical record (the survey output frozen, with input shasums + sourced OFF/ON provenance labels).
- `eval/amplifier/measurability-gate.sh` — the re-runnable MEASURABLE/NOT-MEASURABLE/NO-DATA predicate with a `--selftest` mode.
- `eval/amplifier/VALID-MEASUREMENT.md` — the anchor-validity criteria (incl. the pinned distinct-transcript threshold the gate reads) + the minimal controlled Phase-70 experiment design.
- `eval/amplifier/SCHEMA-NOTES.md` — resolve the line-50 "revisit in Phase 69" note.
- `.dev-wiki/articles/decisions/amplifier-representativeness-audit.md` — the Phase-69 decision article (this exact filename).
- `.dev-wiki/articles/phase-63-remediation-roadmap.md` — formal apparatus disposition (eval/comparison, eval/reasoning).
- `.dev-wiki/articles/phases/**`, `.claude/rules/**`, `.dev-wiki/_CURRENT_STATE.md`, `.dev-wiki/tasks.md` — lifecycle artifacts.

### Out of scope
- Any live agent run / harness off-vs-on execution (Phase 70).
- Editing `eval/amplifier/emit-proxy-vector.sh` or its frozen 4-group schema / AUQ predicate (predicate repair is the deferred Approach-C work, gated by the measurability predicate).
- New ground-truth fixtures, a replacement detector, or rebuilding the `eval/comparison` apparatus (Phase-65 tombstone — do not rebuild).
- Any CODE edits under `eval/comparison/`, `eval/corpus/`, `eval/reasoning/` (disposition is docs/roadmap only).
- Hooks, `modules.json`, `settings.json`, `install.sh`, the memory server.

## Approach

Run the existing ruler read-only over the real transcripts and freeze the output as the committed record, with a **positive-control row** that proves the detector's true-positive branch actually fires on the planted `surfaced.jsonl` fixture — so 8/8-false on real data is attributable to the DATA, not a dead detector branch. Report, per transcript, the escalation_count, the in-AUQ-boundary match count, the raw-text phrase count, and parse_errors as SEPARATE columns, so "0 escalations" is distinguishable from "N escalations, 0 in-boundary matches." Before concluding genuine absence, spot-check the text of the AUQ events that DO exist (escalation_count reaches 7 in condition-c) for paraphrases of the decision concept, and state the exact match expression used, so match-brittleness is named as a competing explanation rather than silently assumed away.

Express the verdict as a runnable predicate, not prose: `measurability-gate.sh` encodes the conditions a VALID off/on measurement requires (a non-commodity, detector-visible, harness-attributable anchor present across enough DISTINCT real transcripts with an OFF-vs-ON differential), excludes the planted-fixture shasums, runs NOW and evaluates NOT-MEASURABLE (proving it is wired and currently blocking), and ships a `--selftest` that exercises both a would-falsely-GREEN scenario and a correctly-RED scenario. `VALID-MEASUREMENT.md` states the operational degeneracy criterion (an anchor is degenerate for lift if the base model already produces the correct behavior unprompted in the harness-OFF baseline — zero headroom) and the positive requirement a non-degenerate anchor must meet. Dispose of the legacy apparatuses by documented decision (not deletion) after naming each one's consumers.

### Domain Research Questions
1. Of the AUQ events that DO occur in the real transcripts (up to 7 in condition-c), what decisions do they actually surface — and does any paraphrase the look-ahead/point-in-time concept the literal detector misses? (Determines whether the finding is "decision never escalated" vs "detector phrase-list too narrow.")
2. What is the minimal anchor-headroom screen — i.e., how would a future phase cheaply pre-verify that a candidate anchor is a decision the base model FAILS unprompted in the OFF baseline (so the harness has something to add)?
3. Does `eval/reasoning` retain any genuine residual use (calibration) that the non-blind ruler does not supersede, or is it fully dispositioned?

## Constraints (CRITICAL)

- The audit must assert ONLY statements about the ANCHOR/INSTRUMENT, never a harness-value claim — Guard: the audit docs carry an explicit no-harness-value-claim disclaimer AND contain no machine-readable harness verdict token (`VERDICT: harness`, `harness_lift=`, `harness_score=`). The guard is a positive disclaimer-presence check plus a narrow token blacklist — deliberately NOT a prose blacklist on words like "harness helps/doesn't", which the audit legitimately needs to write its disclaimer.
- The "0× in-boundary, 8–50× in raw text" finding must be reproducible, not asserted — Guard: `survey-real-transcripts.sh` regenerates both counts per transcript and records the 8 input shasums; drift surfaces as a count/shasum mismatch.
- The measurability gate must not be satisfiable by a single planted/contrived transcript — Guard: the predicate requires a PINNED threshold of DISTINCT real transcripts with in-boundary ground-truth events (≥2 distinct ON AND ≥2 distinct OFF — the threshold stated in VALID-MEASUREMENT.md and read by the gate, not buried as a magic literal) AND an OFF-vs-ON differential, and honors a pinned planted-fixture shasum exclusion list; it must currently evaluate NOT-MEASURABLE (current in-boundary count is 0, well under threshold).
- The gate must be falsifiable in both directions (not vacuously RED forever, not trivially GREEN) — Guard: `--selftest` constructs both a scenario that the gate must classify MEASURABLE and one it must classify NOT-MEASURABLE, and asserts both; a pre-mortem of each failure direction is recorded in VALID-MEASUREMENT.md.
- 8/8-false must be attributable to data, not a broken detector — Guard: the survey includes a positive-control row (the planted `surfaced.jsonl` fixture) showing `surfaced==true`, proving the detector's positive branch fires.
- "Degenerate anchor" must rest on an operational criterion, not assertion — Guard: VALID-MEASUREMENT.md defines degeneracy as "base model produces correct behavior unprompted in the OFF baseline" and cites the specific OFF-baseline transcripts where the concept already appears.
- Apparatus disposition must not delete or orphan anything `make eval` or a drift test depends on — Guard: disposition is a documented keep/tombstone decision that names each apparatus's consumers (Makefile targets, tests, cross-refs); `make eval` (==52) and `test_registration`/`test_settings_template`/`test_templates` are green before AND after; no deletion changes the `make eval` count.
- No scope creep into the deferred measurement — Guard: the diff touches only the in-scope paths; no live agent run, no new fixtures, no detector reimplementation, no `eval/comparison|corpus|reasoning` CODE edits.
- Read-only wrt real transcripts and the emitter — Guard: the survey shasums every input transcript before/after and asserts equality; `eval/amplifier/emit-proxy-vector.sh` is unchanged (git diff empty for that file).
- Deterministic only — Guard: a no-LLM sweep (`! grep -iE 'anthropic|openai|claude -p|\bllm\b|embedding|cosine|fastembed'`) over the new executables passes.
- Transcript provenance must be sourced, not guessed — Guard: real-transcript-survey.md pins each transcript to path + shasum + OFF/ON classification + how the classification was determined (directory naming), so the cross-condition claim rests on labeled provenance.

## Success Vision

A reader six months out can run two committed commands and re-derive the entire verdict: the survey reproduces 8/8 `surfaced=false` with the in-boundary-vs-raw counts that prove the false-negative (and a positive-control row proving the detector still fires), and the measurability gate prints NOT-MEASURABLE with the two structural reasons. The audit reads as an honest instrument verdict — it says exactly what is and isn't measurable and refuses any claim about whether the harness helps. The measurability gate is the load-bearing Phase-70 trigger: a future phase that repairs the predicate or finds a non-commodity anchor re-runs it, and only a flip to MEASURABLE unblocks the expensive live run. The legacy apparatuses have a recorded fate with named consumers, and `make eval`/`make test` are untouched-green. The generalizable lesson — candidate anchors must pass an OFF-baseline headroom screen — is captured where future anchor selection will see it.

## Exit Criteria (machine-checkable)

- [ ] `bash eval/amplifier/survey-real-transcripts.sh --selfcheck` exits 0 (runs read-only; skips gracefully if transcripts absent, asserting input shasums unchanged)
- [ ] `eval/amplifier/real-transcript-survey.md` records, per transcript, separate `escalation_count`, in-boundary-match, raw-phrase, and `parse_errors` columns AND a positive-control row carrying a truthy surfaced value: `grep -qiE 'positive.?control.*\btrue\b|\btrue\b.*positive.?control' eval/amplifier/real-transcript-survey.md && grep -qE 'escalation_count|escalations' eval/amplifier/real-transcript-survey.md`
- [ ] `bash eval/amplifier/measurability-gate.sh` prints `NOT-MEASURABLE` on the current real transcripts: `bash eval/amplifier/measurability-gate.sh 2>/dev/null | grep -q NOT-MEASURABLE`
- [ ] `bash eval/amplifier/measurability-gate.sh --selftest` exits 0 (asserts both a MEASURABLE and a NOT-MEASURABLE constructed scenario)
- [ ] `! grep -iqE 'anthropic|openai|claude -p|\bllm\b|embedding|cosine|fastembed' eval/amplifier/survey-real-transcripts.sh eval/amplifier/measurability-gate.sh`
- [ ] The audit docs carry an explicit no-harness-value-claim disclaimer AND no machine-readable harness verdict token (the disclaimer guard replaces a fragile prose blacklist that would block the audit's own honest "we do not claim the harness helps or doesn't" sentences): `grep -qiE 'no (harness.?value|harness) (claim|verdict)|does not (claim|assert) (any )?harness' eval/amplifier/VALID-MEASUREMENT.md && ! grep -qiE 'VERDICT:[[:space:]]*harness|harness_lift[[:space:]]*=|harness_score[[:space:]]*=' eval/amplifier/VALID-MEASUREMENT.md eval/amplifier/real-transcript-survey.md`
- [ ] `eval/amplifier/VALID-MEASUREMENT.md` defines the operational degeneracy criterion and the Phase-70 experiment: `grep -qiE 'headroom|off.?baseline|degenerat' eval/amplifier/VALID-MEASUREMENT.md && grep -qiE 'phase.?70' eval/amplifier/VALID-MEASUREMENT.md`
- [ ] `git diff --quiet eval/amplifier/emit-proxy-vector.sh` (emitter unchanged) AND `test -z "$(git status --porcelain eval/comparison eval/corpus eval/reasoning)"` (no apparatus CODE edits)
- [ ] `make eval 2>&1 | grep -qE '52/52|52 / 52'`
- [ ] `make test` exits 0 at the unchanged script count (probes self-test; not added as make-test gates) AND `bash tests/test_registration.sh && bash tests/test_settings_template.sh && bash tests/test_templates.sh`
- [ ] `grep -qiE 'phase.?70' .dev-wiki/articles/decisions/amplifier-representativeness-audit.md` (Phase-70 deferred items named) AND `grep -qiE 'eval/comparison' .dev-wiki/articles/phase-63-remediation-roadmap.md && grep -qiE 'eval/reasoning' .dev-wiki/articles/phase-63-remediation-roadmap.md` (roadmap records each apparatus's disposition)

## Checkpoints
- After the survey + measurability gate run on real data: confirm the recon reproduces (8/8 `surfaced=false`, gate NOT-MEASURABLE). If the detector instead fires on real data, STOP and re-derive — the audit premise is wrong.
- Before concluding genuine concept-absence: spot-check the existing AUQ-event text for paraphrases. If a paraphrase IS present in an escalation, reframe the finding to "detector phrase-list too narrow" and note it (still no emitter patch this phase).
- If apparatus disposition surfaces genuine residual value in `eval/reasoning`: record it (keep-as-calibration) rather than forcing retirement.

## Assumptions
- The real transcripts remain readable at `~/.claude/projects/-Users-jwang-ab-test*`. If false: the survey skips-and-reports (graceful), and the committed `real-transcript-survey.md` remains the record of record.
- The Phase-68 emitter + control fixtures are unchanged. If false: STOP — the survey and gate depend on the frozen instrument; re-validate the emitter first.
- `make eval == 52`. If false: STOP — an apparatus count drift means the disposition touched a consumer it shouldn't have.
- The OFF/ON condition labels follow directory naming (`ab-test*` = baseline/eval, `condition-c*` = full harness). If the naming is ambiguous for any transcript: record it as `unknown` rather than guessing.
