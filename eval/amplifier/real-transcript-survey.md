# Real-Transcript Survey — the Phase-68 ruler over real consuming-project provenance (Phase 69)

> Frozen empirical record. Reproduce: `bash eval/amplifier/survey-real-transcripts.sh`.
> READ-ONLY. This record characterises the INSTRUMENT and the ANCHOR; it makes **no claim about
> whether the harness helps** (that requires a measurement this audit proves is not yet possible —
> see VALID-MEASUREMENT.md). No harness verdict is asserted here.

**Same-day-close / look-ahead phrase family** (case-insensitive, the exact detector vocabulary):
`same-day close|same day close|look-ahead|lookahead|entry timing`

**Columns:** `escalation_count` = AskUserQuestion events (the ruler's pinned escalation boundary);
`in_bnd` = phrase-family hits INSIDE those AUQ events (the detector's scope); `raw` = phrase-family
hits ANYWHERE in the transcript; `parse_errors` = malformed jsonl lines skipped; `surfaced` =
`ground_truth.surfaced` (true iff a phrase hit lands inside an AUQ event).

**Provenance** (sourced from directory naming, not inferred): `ON` = condition-c full-harness build;
`OFF` = plain stock-screener build; `OFF-eval` = baseline evaluation/grader sessions.

| label | source | human | escalation_count | tools | in_bnd | raw | parse_errors | surfaced |
|---|---|---|---|---|---|---|---|---|
| positive-control | surfaced.jsonl | 2 | 1 | 2 | 3 | 1 | 0 | true |
| OFF-eval | 501ae00a-bc73-4e56-8f74-068ce957cab8.jsonl | 12 | 0 | 15 | 0 | 22 | 0 | false |
| OFF-eval | a6e687bb-70bc-4b07-9752-8afc59b5073d.jsonl | 11 | 0 | 23 | 0 | 23 | 0 | false |
| OFF | be5f2e53-5890-482a-8813-99b4c3bfe8f3.jsonl | 7 | 0 | 92 | 0 | 11 | 0 | false |
| OFF | d859e198-a547-4f1d-8d37-9734f95a1c5c.jsonl | 6 | 1 | 155 | 0 | 22 | 0 | false |
| OFF | f9790c3c-c8bf-4e5f-ac63-6b3f15955381.jsonl | 5 | 1 | 131 | 0 | 30 | 0 | false |
| ON | 33675039-f483-4a22-8eaa-4c0499a321e0.jsonl | 3 | 4 | 148 | 0 | 4 | 0 | false |
| ON | 587365b2-d68f-4375-b73c-a83b6ef347dc.jsonl | 3 | 1 | 111 | 0 | 8 | 0 | false |
| ON | a929fdcf-e880-449f-bf09-c06c8246a799.jsonl | 7 | 1 | 117 | 0 | 6 | 0 | false |

## Shasums (the pinned input set, for drift detection)

```
9619bd2931eaff898ba8afab0af3855f321ed05e3d75e511b0648c9eb9fc3599  /Users/jwang/nana-dev-kit/eval/amplifier/fixtures/surfaced.jsonl
9dfde8c736e0e84deb6abdcdefad02a0267b2d8886a798f5edb559479eccd9dd  /Users/jwang/.claude/projects/-Users-jwang-ab-test/501ae00a-bc73-4e56-8f74-068ce957cab8.jsonl
c7cbf5f0265e852b2005d7a2568042484c4a6755e7d03c4befe9741ef6c5aecb  /Users/jwang/.claude/projects/-Users-jwang-ab-test/a6e687bb-70bc-4b07-9752-8afc59b5073d.jsonl
96c82cf21d2952b6ab4c188645892215c60b3ec9610242458c3e4e6f94b48b5a  /Users/jwang/.claude/projects/-Users-jwang-ab-test-stock-screener/be5f2e53-5890-482a-8813-99b4c3bfe8f3.jsonl
c11b2a5de48619167e40795abae5af11b79254faac488b6f8879a578d151e461  /Users/jwang/.claude/projects/-Users-jwang-ab-test-stock-screener/d859e198-a547-4f1d-8d37-9734f95a1c5c.jsonl
9b5945a0d527e0324fa1ba632a54a978011f44f6ac866520230d66ed2f6ec2fa  /Users/jwang/.claude/projects/-Users-jwang-ab-test-stock-screener/f9790c3c-c8bf-4e5f-ac63-6b3f15955381.jsonl
6319156e5b5d5cccf78580af6d60acd350710e4a11f6b88f535f82045fbf42ec  /Users/jwang/.claude/projects/-Users-jwang-ab-test-condition-c-stock-screener/33675039-f483-4a22-8eaa-4c0499a321e0.jsonl
41d3a52c345e4ffd51f9e8e18deed12ef0c4716acc2817de142d6e81458de05b  /Users/jwang/.claude/projects/-Users-jwang-ab-test-condition-c-stock-screener/587365b2-d68f-4375-b73c-a83b6ef347dc.jsonl
56374ff857cb83524eb095219aa7f1dab023bd8873e32d6c86bb3fcb57b69b6e  /Users/jwang/.claude/projects/-Users-jwang-ab-test-condition-c-stock-screener/a929fdcf-e880-449f-bf09-c06c8246a799.jsonl
```

## Reading (instrument/anchor only — NOT a harness verdict)

- **Non-representative detector:** every real row shows `surfaced=false` with `in_bnd=0` while `raw>0` —
  the same-day-close decision appears in the transcript text but never inside an AskUserQuestion event.
  The v1 AUQ-only predicate is a *structural false-negative* on real provenance. The positive-control row
  shows the detector's positive branch DOES fire (`surfaced=true`) on the planted fixture, so the 0/8 is a
  property of the DATA, not a dead branch.
- **`escalation_count≥1` on several real rows with `in_bnd=0`** distinguishes "no escalation occurred" from
  "escalations occurred but none surfaced the anchor" — the latter is the actual mechanism.
- **Degenerate anchor:** the phrase appears in the `OFF`/`OFF-eval` baseline rows too — the base model treats
  look-ahead bias as first-class unprompted, so there is no OFF→ON headroom for the harness to add on this
  anchor (see VALID-MEASUREMENT.md for the operational degeneracy criterion).

## Paraphrase spot-check (competing-explanation guard)

> *Hand-authored appendix — everything ABOVE this heading is regenerated verbatim by
> `bash eval/amplifier/survey-real-transcripts.sh`; this section is not (a future drift-check should diff
> only the generated portion).*

Match-brittleness is a competing explanation for `in_bnd=0`: the decision could be present inside an
escalation under a paraphrase the literal vocabulary misses. Dumping ALL AskUserQuestion event text
across the 8 real transcripts, the escalations that occurred surface project scoping — phases, tech
stack, forecast **horizons** (daily/weekly/monthly), backtest **targets** (3pp alpha / Sharpe 1.0),
language/package — but **none paraphrase the look-ahead / same-day-close / entry-timing methodology
decision** (no "point-in-time", "future leak", "data leakage", "survivorship", "entry timing").
The finding is therefore the strong form — *the anchor decision was never escalated, even
paraphrased* — not an artifact of brittle matching.

> Note on the two count columns: `in_bnd` counts phrase hits across the expanded AUQ sub-fields
> (question/header/each option label+description), `raw` counts matching lines over the whole file —
> different denominators, not directly comparable. The load-bearing contrasts are *within* a column:
> real rows `in_bnd=0` vs `raw>0`, and the positive-control row `in_bnd>0 ⇒ surfaced=true`.
