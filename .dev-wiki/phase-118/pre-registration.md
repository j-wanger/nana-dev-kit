# Phase 118 — FROZEN pre-registration instrument

> **Anti-retrofit contract.** This file is the pre-registered measurement instrument. It is authored
> at T1, SHA-256 self-sealed (`prereg.sha256`), and **MUST NOT be amended by the agent during
> T2–T8**. The maintainer's **T9 PREREG-commit checkpoint** — reviewing the concrete queries +
> predicate *before any search* — is the ONLY sanctioned amendment point; after it the file is
> re-sealed, committed, and **pushed to the remote before the first fetch** (externally-witnessed
> ordering). Any gap discovered T2–T8 is a VOID/abort condition, never a silent edit to match code
> ([[decision:stage2-episode-execution-design]] three-tier authority; Ph86 lesson — a freeze is
> load-bearing only because `verify118`/`verdict118` read this text back against the output).
>
> **ToS.** This file is TRACKED — it carries params + aggregates + hashes ONLY. No verbatim
> transcript text, no `source_quote` value, no provenance fence. Verbatim lives only under gitignored
> `run118/`.
>
> Frame: a feasibility **GO/NO-GO** at **N=12** (a directional population peek, NOT a rate estimate).
> Quarantined id (MUST NOT enter the corpus): `04EL2_Llenc` (the Ph117 smoke video).

## Corpus selection function (FROZEN)
A fully deterministic function — **no human veto between running the search and committing the corpus
hash** (the only human input, the pinned tool list + templates, is fixed here and reviewed at the T9
checkpoint before the search). Low-discretion by construction (plan A3).

- **Pinned tool list** (recency-biased toward niche / post-cutoff AI-coding-agent tooling; order is
  load-bearing — selection walks it in order): `["Pi agent terminal", "OpenCode", "Goose (Block)",
  "Cline", "Windsurf", "Zed AI", "aider", "Claude Code", "Cursor", "MCP server"]`.
- **Query template** (applied to each tool, in list order): `"{tool} setup tutorial"`. This is the
  ONLY query form — no free-text queries (removes the "author a query to hit a known-good video"
  degree of freedom).
- **Fixed search params (as the adapter actually pins them):** `yt-dlp ytsearch` with
  `--dateafter 20250901` (recency bias toward post-cutoff content) + result depth `25 per query`;
  sort = `ytsearch` default (relevance). English is enforced DOWNSTREAM by the predicate's language
  bound, not at search time. **Region is the manual-drive machine's residential-IP geolocation**
  (Ph117 = CA), NOT a pinned `US` — a named validity limit: the returned order (hence which N freeze)
  is a function of the operator's geo. This is an environmental constant, not a per-video cherry-pick
  lever, so C1 determinism (selection is a pure function of the adapter's output) still holds.
- **Dedupe:** by video id; then **max 2 videos per channel** (so one creator cannot dominate).
- **Predicate (bounds only content shape, NEVER caption status):** `duration ∈ [3, 40] min` AND
  `primary audio language ∈ {en, en-*, auto}`. It does **NOT** filter on caption availability — a
  no-caption / blocked video that satisfies duration+language **stays in the frozen set** (it is the
  A2 dead-letter numerator; dropping it would corruptibly shrink the denominator — plan C2).
- **Selection:** walk the query list in order; for each, take results in the platform's returned
  order; apply dedupe + predicate; accumulate until **N=12** ids are frozen. The frozen set is the
  A2 denominator. If the queries exhaust before N=12, the corpus is whatever was found (a recorded
  finding, not a re-query).
- **Named validity limits:** (1) the search-query frame is a weaker proxy for the eventual RSS feed;
  (2) the irreducible **no-peek** integrity assumption — no pre-registration can fully mechanize that
  the tool list/templates were fixed before peeking at results; minimized by the low-discretion form,
  the can't-drop-failures predicate, the externally-timestamped push, and the T9 checkpoint.

## Cost stops (FROZEN)
Model `claude-sonnet-4-6` at **$3 / 1M input, $15 / 1M output**.
- **$2 / video** mid-loop kill-switch (from captured `usage`) → `budget-abort` (a recorded finding,
  never a silent exclusion).
- **$10 / batch** cumulative cap across the corpus → `BatchBudgetExceeded`, halts the batch.
- **60-call per-video pre-flight chunk ceiling** → `ceiling-abort` (free, before any paid call).
- **`--confirm` is BANNED** in the measured run (the call ceiling cannot be waived).

## A1 — audio-grounded misread rubric (FROZEN)
Ground truth is the **AUDIO, not the caption text** (Ph117: grounding verifies presence-in-caption,
not that the caption heard the word — "pie"=Pi). Per grounded concept:
1. **Screen:** does the CLAIM turn on a term the ASR could mis-hear (tool/proper name, path, flag,
   command)? If not → not an A1 candidate.
2. **Adjudicate:** listen to the audio at the concept timestamp; compare the caption term to the
   audio. Record an **ASR-error tally** (`caption-term → audio-term`).
- A misread that **inverts the claim's meaning** is a candidate VOID; a VOID requires the **external
  clean-context inversion cross-check to CONCUR** (two-key — plan M4). A single borderline call does
  not flip the run.
- **Every** A1 judgment (quote + claim + audio note + verdict) is logged to gitignored `run118/`
  (full audit trail — plan M4), not only VOID-triggers.
- The inversion cross-check is run **OUTSIDE nana-dev-kit** (clean context; the kit's always-loaded
  working-knowledge leaks — Ph80).
- A1 is a **judgment layer reported alongside the verdict**, NOT part of the mechanical PASS/FAIL.

## A2 — dead-letter directional classification (FROZEN)
Per frozen id, `outcome_class` is one of the tokens the acquisition path actually emits (bound to the
code by a test): `success`, `no-captions`, `dl-empty200`, `dl-subfloor`, `dl-other`, `endpoint-error`,
`age-restricted`, `unavailable`, `unclassified`, `ceiling-abort`, `budget-abort`, `probe-abort`,
`error`, `not-run`, `write-<status>`. **Dead-letter** = no usable caption track, whisper.cpp would fix
= `no-captions` ∪ `dl-empty200`. `dl-subfloor` (a thin BUT captioned track) and `dl-other` are NOT
dead-letter — whisper over the same audio would not help a video that simply says little.
- **Rate** = dead-letter / (N frozen − `not-run`), reported **with its binomial 95% CI**.
- **Directional flag only:** a dead-letter rate ≳ **30%** *directionally* flags that whisper.cpp is
  worth pulling forward in a later rung. At N=12 this is **NOT a mechanical PASS/FAIL trip** (the CI
  is far too wide — plan C4); it is a reported signal.
- **Soft-block re-probe (named upward bias):** `TranscriptsDisabled`/`NoTranscriptFound` is *also*
  raised for a residential-IP soft-block, systematically inflating the numerator. Each `no-captions`
  id is **re-probed once after cooldown** before being counted; the residual ambiguity is a named bias.

## Novelty — bare-model recovery control (FROZEN)
The controlled form (plan C5; the Ph104 "blind baseline before search → measure the delta" method).
Per grounded concept, **outside nana-dev-kit** (Ph80):
- **Pinned judge:** model `claude-opus-4-8` (stated training cutoff **2026-01**); prompt PINNED
  verbatim in `recovery118.py` (`RECOVERY_PROMPT`, judge id + cutoff recorded with every judgment —
  plan M5; "post-cutoff" is relative to a specific model+date).
- **Protocol:** present the judge with the concept's **claim topic ONLY** (not the video, not the
  grounded phrasing) and ask whether it can state the specific claim unaided. Classify: `recovered`
  (commodity — bare model already holds it), `not-recovered` (post-cutoff / proprietary candidate),
  `partial`. A confident bare-model answer that **contradicts** the grounded claim is a
  `not-recovered` signal, not a defect (Ph104: parametric implausibility is a signal).
- **Admissibility:** the recovery distribution is admissible ONLY scoped-to-post-cutoff content and is
  **explicitly NOT part of the feasibility PASS/FAIL** — it cannot retrofit the verdict, and it is not
  the full value screen (does grounded retrieval improve a real decision — that is Phase 119). It
  answers only: is the corpus even the KIND (post-cutoff) that could have downstream value.

## Feasibility PASS/FAIL truth table (FROZEN)
**Mechanical inputs ONLY:** `{instrument-controls, cost, A2-count, grounding}`. A1 + novelty are
separate judgment layers, reported but never in the mechanical verdict (plan M6). Kept deliberately
simple/legible (Ph97 rigor-legibility lesson — an over-hardened rule over-shoots into illegible
INCONCLUSIVE).

- **Instrument gate (HARD):** the T5 controls all pass on this run's data — the splice control drops,
  the classifier control separates no-captions from soft-block, and the rail calibration probe passes
  on every chunk. Any instrument-control failure → **VOID** (clean-on-seed = instrument-dead).
- **Anchor gate (HARD):** `verify118` passes — PREREG⟶CORPUS-FREEZE⟶RESULTS ancestry, frozen-id-set
  == telemetry-id-set (every id accounted), rail + prereg seals match, and the keystone `ground()`
  re-derivation reproduces the committed drop-set. Any mismatch → **VOID**.
- **ToS gate (HARD):** the containment gate passes (no `source_quote` in any tracked file;
  `run118/` gitignored). A post-run leak → **VOID**.
- **A1 gate (HARD):** an inverting A1 misread with a **concurring** external cross-check → **VOID**.
- **Cost:** no `budget-abort` that right-censors the corpus below the success floor. A cost-censored
  corpus → **INCONCLUSIVE**.
- **Success floor:** see below.
- **The 4-way verdict** (legible by design — Ph97 rigor-legibility lesson):
  - **VOID** — any HARD gate fails (instrument-control / anchor / ToS / inverting-A1-with-concur). The
    measurement is untrustworthy; nothing else is read.
  - **INCONCLUSIVE** — no VOID, but underpowered: `above-floor successes < 4`, OR cost right-censored
    (a `budget-abort` cut the corpus below the floor). Too little real video to judge feasibility.
  - **FAIL** — no VOID, adequately powered (`above-floor successes ≥ 4`) BUT grounding collapsed
    (`pooled grounded concepts < 20`): the apparatus ran on enough real video yet did not produce
    usable grounded output — feasibility DISPROVEN.
  - **PASS** — no VOID, `above-floor successes ≥ 4` AND `pooled grounded concepts ≥ 20` AND no cost
    right-censoring: feasibility confirmed.

## Minimum-success floor (FROZEN)
A **success** = `outcome_class == success` with `grounded_quote_count ≥ 1` above the rail word-floor.
Consistent with the 4-way truth table above: **`above-floor successes < 4` → INCONCLUSIVE** (never
PASS — underpowered); **powered (`≥ 4`) but `pooled grounded concepts < 20` → FAIL** (grounding
collapsed). The concept floor is nearly free (Ph117: 21 from one video); the binding gate is the
success **count**.

## Rail byte-freeze seal
The four rail files (`ground.py`, `normalize.py`, `consolidate.py`, `schema.py`) are byte-frozen,
asserted by **`rail.sha256`** (NOT `git diff --quiet` — vacuous on this gitignored tree). Re-verified
by `verify118` at T3/T8 and again at the T9 verdict; a mismatch → **VOID**. This file is itself sealed
by `prereg.sha256` (self-seal; amendment-evident).
