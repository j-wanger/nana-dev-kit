# Phase 117 — First-contact results (aggregates only)

> **ToS containment:** this file carries AGGREGATES + hashes ONLY. Verbatim transcript quotes live
> exclusively under gitignored `companion/research/youtube/run117/` (concept files + `telemetry.jsonl`).
> No `~~~json` provenance fence appears here (enforced by the T4 containment test).

Status: **T1–T6 done. Companion pytest 78/78. T5 smoke drive RAN 2026-06-30** — on this machine
(residential Rogers IP, transcript fetch works), with **Claude-as-extractor** (no `ANTHROPIC_API_KEY`
in-env, so the session model performed extraction-by-selection instead of the API; the frozen
`ground → consolidate → diagnose` pipeline ran unchanged). The grounding rail is byte-unchanged.

## T5 live result — video `04EL2_Llenc` (Christian Lempa, "Pi: Open-Source AI Agent Terminal Set-Up", 19m, QUARANTINED)

| metric | value | reading |
|---|---|---|
| outcome_class / track | success / **generated** (auto-caption) | captioned, above the 200-word floor → not a dead-letter (A2 ok, n=1) |
| word_count / chunks | 3580 / 5 | est ~5.4k input tokens; **~$0.02–0.05/video** at $3/$15 (this run $0 — Claude was the extractor) |
| extracted / grounded / dropped | 22 / 21 / 1 | **grounding rate 95%** on real auto-caption content |
| drop_diagnosis | 1 × `present-spanning-sentence-boundary`; **0** × `present-modulo-punctuation`; **0** × `absent-even-stripped` | the one drop was a deliberate cross-sentence merge, correctly flagged as splice-suspect; **no fabrication, no punctuation over-drop** |
| A1 caption ASR errors (in grounded quotes) | "pie"(=Pi)×1, "agent.d"(=agents.md)×1, "{slash}"(=/)×3 | grounded quotes are verbatim-to-caption but the **caption itself misheard the words** |

## The headline finding — the dominant-risk hypothesis was largely WRONG

The plan's dominant risk was that auto-caption tracks are **unpunctuated**, so the strict
punctuation-preserving normalization would over-drop a real model's verbatim quotes. **Modern YouTube
auto-captions are punctuated and capitalized** (this track has periods, commas, capitals, quotes), so a
compliant model's verbatim quotes ground fine (95%). The `present-modulo-punctuation` bucket was **empty**.
The mock-vs-real gap this phase existed to derisk **did not materialize on this video.**

The REAL A1 surface that emerged is different: **ASR word-errors that ground faithfully** — the caption
says "pie" (for Pi), "agent.d" (for agents.md), "{slash}" (for /). Grounding verifies a quote is *present in
the caption*, NOT that the caption *heard the word correctly*, so a grounded concept can carry a mis-heard
term. This is exactly why the Phase-118 A1 rubric uses **audio as ground truth, not caption text** — the
smoke test confirms that instinct was right, and re-points the A1 concern from punctuation to ASR errors.

## GO / NO-GO verdict (Claude-as-evaluator, per maintainer instruction) — **GO, with a re-orientation**

- **GO to the Phase-118 frozen measurement.** Feasibility is confirmed on n=1: real captioned video → 95%
  grounding → provenance-carrying concepts, cheaply. No fabrication; the diagnosis buckets work.
- **Re-orient the A1 concern** from "punctuation over-drop" (a non-issue on modern captions) to **"ASR
  word-errors in grounded quotes"**. Phase 118's audio-grounded A1 rubric already addresses this; add an
  explicit ASR-error tally + a normalization note for slash-commands ("{slash} model" → `/model`) at the
  wiki hand-off.
- **A rail-normalization change is NOT indicated** (the byte-freeze held for the right reason — punctuation
  stripping would have re-opened the splice hole AND wasn't needed).

## Caveats (honest)

- **n=1, one creator, one auto-track** — directional, not a rate. Phase 118's corpus measures the distribution.
- **Extractor = the session model** (a real frontier model, representative) but with the grounding rail in
  mind, so 95% is plausibly an upper-ish estimate vs a naive extractor. The API path (with a key) would
  measure a compliant-but-rail-blind model; worth one such run in Phase 118.
- The `{slash}` artifact is `youtube-transcript-api`'s rendering of "/" on this track — a hand-off normalization item.

---

## T5 runbook — the one command (manual-drive)

Run on a **residential IP** (not VPN/cloud — YouTube blocks cloud IPs; the timed-text endpoint is
unofficial) with `ANTHROPIC_API_KEY` set:

```sh
cd companion/research/youtube
export ANTHROPIC_API_KEY=...          # your key
.venv/bin/python harness117.py "<youtube-url-or-id>" --channel smoke
#   --budget-usd 2.0     per-video hard kill-switch (default)
#   --ceiling-calls 60   pre-flight chunk-count ceiling (no --confirm; a >60-chunk video aborts free)
```

**Video selection (A4 search-query frame, quarantined):** pick via a topical search for an AI-coding-agent
setup/config walkthrough (Pi / Claude Code / Cursor / aider / MCP), biased toward a **smaller creator
likely on the auto-generated (unpunctuated) caption track** — that stresses both the A2 uncaptioned
question and the punctuation-vs-real-model gap in one video. The id is **quarantined**: do NOT reuse it
in any Phase-118 frozen corpus (seeing its output would break the anti-retrofit freeze).

**STOP after the first video**, read `run117/telemetry.jsonl`, and fill the table below before running a
second. A reformatting-dominated drop split is itself the go/no-go signal.

Optional (A6): for any grounded concept whose claim looks like it could invert its quote's meaning, run a
**clean-context LLM inversion cross-check OUTSIDE nana-dev-kit** (so the always-loaded working-knowledge
can't leak, per Ph80).

---

## Live results (fill from run117/telemetry.jsonl)

| metric | video 1 | video 2 (optional) | reading |
|---|---|---|---|
| `outcome_class` | _pending_ | | success / dl-empty200 / no-captions / endpoint-error / ceiling-abort / budget-abort / probe-abort |
| `track` | _pending_ | | manual vs generated (generated = the unpunctuated stress case) |
| `chunks_n` / cost `$` | _pending_ | | real per-video cost at $3/$15 (Sonnet-4.6) |
| `grounded_quote_count` / `dropped` | _pending_ | | did genuine concepts ground at all? |
| `drops_by_reason` | _pending_ | | quote-not-in-chunk vs quote-too-short vs chunk-not-found |
| `drop_diagnosis` | _pending_ | | **present-modulo-punctuation** (strict normalization is the culprit → fixable) vs **absent-even-stripped** (rail catching fabrication) |
| `max_tokens_truncations` | _pending_ | | truncated chunks = max price / zero yield |

## Go / no-go on the Phase-118 frozen measurement (decide from the above)

- **GO (build the full frozen rig):** genuine concepts grounded at acceptable cost, and the drop split is
  dominated by `absent-even-stripped` (rail working) OR a small, understood `present-modulo-punctuation`
  share. The apparatus is sound enough on real data to measure.
- **HARDEN-FIRST (rail-normalization task into Phase 118, then measure):** drops dominated by
  `present-modulo-punctuation` on a generated track — the strict punctuation normalization is over-dropping
  genuine quotes. This is the mock-vs-real gap realized; fix it (a diagnosis-informed normalization change,
  with its OWN freeze — NOT slipped into this phase) before any frozen measurement.
- **PULL-WHISPER-FORWARD:** `no-captions` / `dl-empty200` — the uncaptioned long-tail is real; whisper.cpp
  becomes the next rung's scoped work (the no-caption id is its first test case).
- **RE-COST:** a `budget-abort` or a high `max_tokens_truncations` count — the cost model / `max_tokens`
  is mis-sized; revisit before scaling (levers: Haiku 4.5 $1/$5, the Batch API 50% off, larger chunks,
  wiring the dead `--ceiling-tokens`).

---

## Recommended Phase-118 pre-registration parameters (freeze at the 118 freeze, not now)

- **Corpus frame:** search-query (A4) — commit 3–4 query strings + date + sort + locale; the frame is a
  weaker proxy for the eventual RSS feed (a named validity limit).
- **A2 whisper-pull-forward threshold:** 30% (~≥3 of 8) uncaptioned-class of the captioned-eligible denominator.
- **A1 rigor (A6):** solo maintainer + a **mandatory** clean-context LLM inversion cross-check run OUTSIDE
  the kit; audio-grounded two-step rubric + a planted-misread instrument control (M4); borderline counts against.
- **Cost stops:** $2/video kill-switch + $10/batch cap + a 60-call pre-flight ceiling (`--confirm` banned in run 1).
- **Anti-retrofit anchor:** **git ancestry + a SHA-256 of the fetched ids** (NOT forgeable timestamps); the
  PREREG commit must be an ancestor of the telemetry commit, and the committed hash must equal the hash of the
  ids actually in `telemetry.jsonl`.
- **Overall verdict truth table** (committed before any fetch): instrument gates (control + classifier +
  seeded-fabrication drop) + A2 + cost must hard-pass for a feasibility PASS; A1 is a separate quality gate
  whose fail quarantines wiki-feed; any inverting A1 misread or any post-run zero-leak failure = whole-run VOID.
- **Minimum-success floor:** < 4 above-floor successes OR < 20 pooled grounded concepts → INCONCLUSIVE, not PASS.

## Controls / invariants held this phase

- Grounding rail **byte-frozen** — `git diff --quiet` on `ground.py`/`normalize.py`/`consolidate.py`/`schema.py`.
- ToS containment — `run117/` gitignored; no `~~~json` quote-fence committed under `.dev-wiki/phase-117/`.
- Companion pytest **71/71** green (53 Ph116 baseline + 18 Ph117); the mocked/injected test path never touches the network.
