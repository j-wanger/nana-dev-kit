<!-- nana:approved 2026-06-20 -->
# Spec: Phase 94 — Clean Consumer Memory Re-measure

## Objective
Produce ONE clean, admissible **retrospective** re-measure of consuming-project memory-LAYER demand — across a
machinery gradient of three live consumers running on the repaired (working) memory MCP — to serve as the
evidence basis for Phase 95's keep / shrink / cut decision. **Evidence only; Phase 94 makes no disposition.**

## Context
The kit ships an MCP-backed semantic memory layer: the agent calls `memory_search` / `memory_store`; the store
persists per-project to `<project>/.memory/memory.db`. Some consumers additionally install harness *rules*
(always-loaded `nana-soul.md` instructing a session-start `memory_search` + storing decisions/corrections) and
*hooks* (e.g. `enforce-memory` that can block/prompt to force memory use).

The Phase-89 measurement found ZERO consumer memory use, but it was later discovered (Phase 91) the layer was
**broken** at the time — the `memory_server` module failed to resolve in consumer cwds, so the server never
started. That zero is **couldn't-fire**, not no-demand, and is inadmissible ([[HEU-012]]). Phase 91 repaired it
with a `PYTHONPATH=~/.claude` env on the global MCP registration (the repair-boundary commit must be pinned —
see Assumptions). The Phase-92 [[strategic-inflection-review]] gated **re-measure-once-then-shrink**: ONE clean
re-measure on working memory must precede any memory-layer cut. This is that re-measure — a **lightweight
retrospective dogfood, explicitly NOT a new measurement-apparatus phase**.

Direction gate closed 2026-06-20 (assumption-ledger Phase-94 block; all_accept:false): A1 accept (memory fires
end-to-end in a consumer cwd), A4 accept (post-repair window admissible), A2 don't-know → resolved by
down-scope + substrate expansion, A3 → maintainer revised n=1 to **n=3** (add aml-substrate + aml-casework).

Pre-gathered **prior to TEST** (not a result to reproduce — the numbers below are an expectation the
deterministic tally must independently confirm or refute; treating them as a fixture would anchor the
measurement): three live consumers on the working global memory MCP, all measurement-blind, may form a
**machinery gradient** — `signal-watch` (no kit memory rules/hooks) as the spontaneous FLOOR; `aml-casework`
(rules, no hooks); `aml-substrate` (rules + hooks). The recon hint is that the spontaneous floor is low but the
coerced/announced demand persists — which would **reverse** the roadmap's "consumer demand is zero" lean (that
zero was the broken-layer couldn't-fire). The tally OUTPUTS the real numbers; Phase 94 documents them as
evidence; Phase 95 disposes.

## Scope
### In scope
- The **three maintainer-fixed consumers**: `~/signal-watch`, `~/aml-casework`, `~/aml-substrate`.
- **Verify-by-firing** that the memory layer works end-to-end in a consumer cwd (admissibility gate).
- **Retrospective** demand tally over each consumer's post-repair sessions (real recorded transcripts).
- **3-class** classification (spontaneous / rules-instructed / hook-prompted) + **cross-session read-back**
  (ritual-vs-value discriminator) + **attempted-vs-satisfied** (paired `tool_result`) sub-measures.
- One evidence file + checkers under `eval/memory-remeasure/`.

### Out of scope
- The keep / shrink / cut **decision** (Phase 95) — and any phrasing that pre-judges it.
- Triggering the **deferred Phase-93 live consumer re-sync** (left untouched in Blockers).
- **Fresh** / newly-run measurement sessions (retrospective only).
- **Any kit code change** — `eval/` + `.dev-wiki/` + `specs/` only; no `templates/`, `scripts/`,
  `modules.json`, `install.sh`, hooks.
- In-kit measurement (the kit's always-loaded `working-knowledge.md` leaks the answer — Ph80).
- Dormant / never-wired consumers (`edge-screener`, `edge-analyst`, `ai-game`, `fate`) except as enumerated
  N/A exclusions.

## Approach
Retrospective transcript analysis gated by a verify-by-firing admissibility check. Goals, not implementation:

- **Admissibility first.** Before any zero/low count is trusted, drive the memory MCP server **exactly as
  Claude Code launches it** (the global `~/.claude/settings.json` `mcpServers.memory` config — the configured
  venv python, `-m memory_server`, `PYTHONPATH=~/.claude`) with cwd set to a consumer, and assert a
  `store → search` round-trip persists a row to **the consumer's** `<consumer>/.memory/memory.db` and
  retrieves it. The CWD/DB-path hazard is the exact prior failure — the row must land in the *consumer's* DB,
  not `~/.claude/.memory/`. Do NOT import the module ad-hoc (sibling-import fragility makes that a false
  negative).
- **Count real calls, never string occurrences.** Parse transcript JSONL as `type=="assistant"` →
  `message.content[]` → `select(.type=="tool_use")` → `.name == "mcp__memory__memory_search|memory_store"`.
  A deferred-tool catalog / system-reminder / `tool_result` listing names the memory tools in many sessions
  and a naive grep over-counts by ~5× (empirically 103 string-hits vs 20 real-call sessions in one consumer).
- **Window by per-entry timestamp**, not file mtime — sessions span the repair boundary. **Window-method
  precedence (state it, apply it uniformly to all three consumers):** SHA-pin is PRIMARY — a session is
  admissible iff its FIRST entry post-dates the pinned repair commit's timestamp (turns before the boundary in
  a spanning session ran against the broken layer). Per-session firing-corroboration is the FALLBACK, used
  ONLY if the repair has no clean pinnable commit boundary, and then for ALL three (never mix methods across
  consumers). Record which method was used in the evidence file.
- **Prove the rig can count before trusting a low number** (symmetry of error — a silent-empty parse that
  found zero sessions exits as happily as a true zero, and wrongly feeds a cut). A positive ingest control
  asserts ≥1 admissible session was actually opened+parsed per in-scope consumer; mirror of the firing
  broken-config control.
- **Separate demand from coercion.** Classify each call: hook-prompted (an `enforce-memory` event precedes it
  in the same turn / the consumer has memory hooks), rules-instructed (session-start search per always-loaded
  rules), or spontaneous. Coerced calls are NOT organic demand — counting them as demand over-justifies keep.
- **Distinguish attempted vs satisfied** demand via the paired `tool_result` (an errored store / empty search
  still emits a `tool_use`) and **measure cross-session read-back** (do later searches retrieve earlier-stored
  entries — the layer doing its job vs store-and-never-read ritual).
- **Exclude subagent-file calls** (`<session>/subagents/*.jsonl`) from the demand tally (orchestrator-driven,
  not organic user-session demand); report them separately if present so they neither inflate nor double-count.
- **Pin the denominator before counting** (retrofit hazard): report RAW per-consumer counts (real calls,
  stores, persisted rows, read-backs) as primary, and a per-admissible-session rate as a stated secondary.

### Domain Research Questions
- Are persisted entries actually **read back** across later sessions (value), or stored-and-never-retrieved
  (ritual)? This, more than the raw count, is what should weigh on a keep/cut.
- Does demand track the machinery gradient **cleanly**, or is it confounded by project type / session length /
  task mix (the AML consumers vs the agent project)?
- In the no-machinery consumer (`signal-watch`), did cross-session continuity needs arise, and what served
  them — the file substrate (`.dev-wiki`, auto-memory `MEMORY.md`), or were none needed?

## Constraints (CRITICAL)
- **Evidence only, never disposition** — Phase 94 must not state or imply keep/shrink/cut. Guard: the evidence
  file carries an explicit `EVIDENCE ONLY` line and a `NO-SUFFICIENCY` assertion; no recommendation verbs.
- **Verify by firing, not presence** ([[HEU-012]], [[deterministic-vs-llm-boundary]]) — registered+present ≠
  working. Guard: T1 round-trip asserts a row in the consumer DB; a deliberately-broken-config control MUST
  classify `COULDNT-FIRE` (clean-on-seed = instrument-dead) or the firing detector is not trusted.
- **JSON `tool_use` parse, never grep** — Guard: the tally tool ships a `--selftest` whose fixture contains a
  deferred-tool-catalog/system-reminder mention (must NOT count) AND a real `tool_use` block (MUST count) AND
  a subagent-file call (must be reported SEPARATELY, not folded into the main count); selftest fails the build
  if any misclassifies.
- **The tally must prove it ingested real sessions** (positive control, symmetry of error) — Guard: a
  `--verify-ingest` mode asserts ≥1 admissible session was actually opened+parsed for each in-scope consumer
  (count of opened sessions > 0); a silent-empty parse (wrong glob / missing transcripts) FAILS rather than
  reporting a false zero.
- **Coercion ≠ demand** — Guard: every counted call is tagged spontaneous / rules-instructed / hook-prompted;
  the contrast table reports the classes separately; the floor (spontaneous) is never silently merged with the
  coerced classes.
- **Admissible window pinned to a commit, per-entry** — Guard: the repair boundary is a pinned commit SHA
  (a real 7–40 hex SHA, not the word "~06-14") + its timestamp recorded in the evidence file; sessions
  windowed by first-entry timestamp; the SHA-primary / firing-fallback precedence is stated and applied
  uniformly.
- **Run over consumers, never in-kit** — Guard: the consumer set is the enumerated 3; nana-dev-kit + apparatus
  scaffolds (`ab-test*`, `p87-arms*`, `tmp-*`) + upstream sources (`nanaclaw`, `dev-wiki`, `knowledge-wiki`)
  are explicitly excluded and listed.
- **Uninformative zeros are N/A, not no-demand** — Guard: a consumer not wired for memory at session time is
  classified `not-applicable`, not counted as a demand-zero; each consumer's session-time wiring state is
  recorded (current FS state ≠ session-time state).
- **Zero kit code change** — Guard: exit criterion asserts `git diff --name-only` touches only `eval/`,
  `.dev-wiki/`, `specs/`.
- **Do NOT trigger the deferred Phase-93 live re-sync** — Guard: no `install.sh --update` invocation against
  any consumer; the Blockers entry stays open.

## Success Vision
An honest three-consumer contrast that a Phase-95 reader can act on without re-deriving anything: a machinery
gradient (none / rules / rules+hooks) with each consumer's real call counts, persisted rows, class breakdown,
attempted-vs-satisfied split, and cross-session read-back rate — every number traceable to a deterministic
command, the admissibility (firing + pinned window) proven up front, the denominator pinned before counting,
and the ritual-vs-value question answered as far as the transcripts allow. The spontaneous floor (whatever the tally measures — the recon prior
is "low," not a target to hit) and the coerced demand (the actual cut target) are both on the record, with an explicit statement that the floor alone
cannot license cutting a coerced layer. No keep/cut verdict — just clean, leak-free, firing-verified evidence.

## Exit Criteria (machine-checkable)
- [ ] `bash eval/memory-remeasure/verify-firing.sh` prints `VERDICT: FIRES` and exits 0 (a consumer-cwd
      store→search round-trip persisted + retrieved a row in the consumer DB).
- [ ] `bash eval/memory-remeasure/verify-firing.sh --broken-control` prints `VERDICT: COULDNT-FIRE` and the
      script distinguishes the two (controls-first; clean-on-seed = instrument-dead).
- [ ] `python3 eval/memory-remeasure/tally-demand.py --selftest` exits 0 (fixture: deferred-tool/system-reminder
      mention NOT counted; real `tool_use` block counted; a subagent-file call reported SEPARATELY, not folded
      into the main count).
- [ ] `python3 eval/memory-remeasure/tally-demand.py --verify-ingest` exits 0 — positive control: ≥1
      admissible session was actually opened+parsed for each in-scope consumer (a silent-empty parse FAILS;
      mirrors `--broken-control`, so a low count is only trusted once the rig proves it can count).
- [ ] `python3 eval/memory-remeasure/tally-demand.py` emits a per-consumer table for the 3 consumers with
      real-call counts, class tags, and read-back — exits 0.
- [ ] `test -f eval/memory-remeasure/memory-demand-remeasure.md && grep -q 'EVIDENCE ONLY' eval/memory-remeasure/memory-demand-remeasure.md && grep -q 'NO-SUFFICIENCY' eval/memory-remeasure/memory-demand-remeasure.md`
- [ ] `grep -Eq 'repair-commit[^0-9a-f]*[0-9a-f]{7,40}' eval/memory-remeasure/memory-demand-remeasure.md` (a
      REAL pinned repair SHA, not the literal word).
- [ ] `for c in signal-watch aml-casework aml-substrate; do grep -Eq "$c.*[0-9]" eval/memory-remeasure/memory-demand-remeasure.md || exit 1; done` (each consumer appears with at least one number — no stub).
- [ ] `git diff --name-only HEAD | grep -vE '^(eval/|\.dev-wiki/|specs/)' | grep -q . ; [ $? -ne 0 ]` (no
      changes outside eval/ + .dev-wiki/ + specs/).
- [ ] `make test` exits 0 (no regression to the existing suite).

## Checkpoints
- **After T1 (firing verdict) — HARD checkpoint.** If `FIRES`: proceed; the retrospective zeros are admissible.
  If `COULDNT-FIRE`: STOP, file the firing defect, report — Phase 94 cannot produce admissible demand evidence
  and Phase 95 stays blocked (do not fabricate a tally on a broken layer).
- **If a consumer's session-time wiring cannot be established:** classify it `not-applicable` and note it; do
  not infer no-demand.
- Low-risk otherwise (read-only retrospective analysis, zero kit code): single close-out report at T3.

## Assumptions
- **The Phase-91 PYTHONPATH repair is real and pinnable to a specific commit/timestamp.** If false (date
  approximate / fix incomplete): pin the actual fix commit from `git log` before windowing; if no clean commit
  boundary exists, fall back to per-session firing corroboration instead of a date cutoff.
- **The memory layer fires end-to-end in a consumer cwd** (A1). If false: T1 returns `COULDNT-FIRE` → STOP per
  the hard checkpoint; the phase becomes a firing-defect report, not a re-measure.
- **The three consumers' post-repair sessions ran on the working layer** (A4). If false: window by per-entry
  firing corroboration rather than trusting the date.
- **signal-watch / aml-casework / aml-substrate are valid consumer substrates** (A3, maintainer-fixed n=3). If
  one turns out unwired or kit-adjacent: classify it N/A and record n<3 with the reason.
- **A spontaneous floor alone is NOT assumed sufficient for the Phase-95 cut** (A2 don't-know). The evidence
  file states this; the sufficiency judgment is routed to Phase 95 (Blockers, revisit-status: open).
