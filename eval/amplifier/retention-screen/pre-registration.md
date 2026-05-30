# Cross-Boundary Retention Headroom Screen — Pre-Registration (Phase 71)

> **Committed BEFORE any OFF/ON verdict run.** This file fixes the apparatus, the frozen prompts
> (shasum-pinned), each item's deterministic check, the classification thresholds, and the verdict
> ladder — so no verdict can be retrofitted. The pre-registration commit MUST be a git ancestor of the
> first `verdicts/` commit (`git merge-base --is-ancestor`). `check.sh --verify-pins` recomputes every
> prompt shasum below and fails on drift.
>
> **No-harness-value claim.** This screen characterises a BOUNDARY and an INSTRUMENT, not the harness.
> `HAS-HEADROOM` means *lift is POSSIBLE* (the residual context lacks the decision, so a harness rule
> *could* supply it) — never that lift exists. This record makes **no claim** about whether the Nana
> harness helps in real work.

base-model: claude-opus-4-8 (bare subagent via the Agent tool — no rules/hooks/skills/memory/tools;
model pinned at dispatch). The strongest default model is the fairest baseline.

## What this screen tests

The multi-turn analog of the Phase-70 anchor screen. Across a context-loss (compaction) boundary, does
the harness cross-compaction state machinery RECOVER an earlier-established counter-default project
decision that a bare agent (residual context only) DROPS? OFF = residual only (a model-authored
compaction summary + task). ON = identical residual + an in-context `[HARNESS STATE]` block carrying the
decision (the only varied byte-range; `assert-off-on-isolation.sh` enforces ON = OFF + appended block).
NO LLM in the scoring path; a model is used ONLY to author the summary substrate, then frozen.

## Method (frozen)

- **n = 5 runs per condition, exactly.** Each run = one bare clean-room subagent given ONLY the frozen prompt.
- **Differential verdict (`check.sh --diff`), never an LLM judge.** Each item has a `.check` of named
  clauses (`require`/`forbid`, ERE). A run PASSES iff every `require` matches and no `forbid` matches.
  - **DEGENERATE** — OFF PASSES ≥4/5 (residual already honors the decision; harness adds nothing).
  - **HAS-HEADROOM** — OFF FAILS ≥4/5 (same consensus clause) AND ON PASSES ≥4/5.
  - **INERT** — OFF FAILS ≥4/5 AND ON FAILS ≥4/5 on the SAME clause (state present, not honored).
  - **UNSTABLE** — anything else, incl. ON failing on a DIFFERENT clause and the n=5 dead zone.
- **Leak-checked OFF prompts.** Every `*-off.txt` passes `leak-check.sh` (no HARNESS-recovery cue, and —
  where pinned via `checks/<item>.offleak` — no target-decision token) against the frozen `leak-vocab.txt`.

## SUBSTRATE NOTE — short→long escalation (recorded for transparency, NOT a retrofit)

The candidates' OFF residual is a MODEL-authored compaction summary of a frozen synthetic transcript
(the real compaction mechanism, not hand-truncation — the OFF-starvation guard). Two probe rounds were
run, pinned-then-summarised, and ACCEPTED as produced (no transcript was iterated to force a drop —
that is the forbidden retrofit):

1. **Round 1 (short, ~40-line transcripts).** Two separate short sessions (a monitoring-threshold
   decision; a sanctions-encoding decision). Both model-authored summaries RETAINED their decision.
2. **Round 2 (long, 1,213-word / ~12-decision session — the pinned `transcripts/session.txt`).**
   A single realistic long session. Its model-authored summary (`summaries/session.txt`, 356 words)
   AGAIN retained ALL THREE pre-registered candidate decisions (deterministically verified — every
   decision token below appears in the frozen summary).

The escalation was a SUBSTRATE-VALIDITY fix (short transcripts do not stress compaction), decided BEFORE
seeing whether a longer summary would drop anything; the result (retention) held at both scales. Because
the boundary is therefore NOT naturally lossy for project decisions, the candidate test reduces to:
*given the decision is RETAINED in the residual, does the model ACT on it (DEGENERATE) or ignore it?*
The headroom precondition (OFF lacks the decision) is met only by the POSITIVE CONTROL.

## Controls (run FIRST — instrument validation; any misbehavior ⇒ STOP, instrument-broken)

### control-negative — decision PRESENT in residual
expected: DEGENERATE (the OFF residual states the 14-day retention; the model honors what it is given)
check: checks/control-negative.check   (require honored-14 = `\b14\b`)

### control-positive — arbitrary rule ONLY in the [HARNESS STATE] block (THE load-bearing control)
expected: HAS-HEADROOM (the fixed sentinel `7731` appears in NO residual; the bare model cannot produce
it, so OFF FAILS 5/5; ON supplies it, so ON PASSES). If this screens INERT, the ON pathway is dead —
verify ON-prompt construction, then report the inert-machinery finding. `checks/control-positive.offleak`
asserts the OFF prompt does not contain `7731`.
check: checks/control-positive.check   (require honored-sentinel = `\b7731\b`)

### control-middle — borderline (HTTP 204 vs 200 for a successful DELETE)
expected: NOT HAS-HEADROOM, reproducibly. Run TWO independent n=5 batches; PASSES iff NEITHER batch
reads HAS-HEADROOM (`check.sh --stability` ⇒ `STABLE`). The property that matters is no false-positive.
check: checks/control-middle.check     (require honored-204 = `\b204\b`)

## Candidates (screened only if the controls pass)

All three decision tokens are RETAINED in the frozen `summaries/session.txt` (verified by grep), so each
candidate's OFF residual CONTAINS its decision. Expected verdict: DEGENERATE (the model honors the
retained decision). Classification is by DESIGN (the rationale-probe litmus is moot for a retained
decision — it cannot be a recovered "unknown"); recorded for completeness.

### cand-threshold — internal monitoring alert threshold EUR 8,000 (MOTIVATED by the backtest premises)
classification: motivated (decision follows from the cash-intensive-SME backtest premises in the session)
retained-in-summary: YES (`EUR 8,000`)
check: checks/cand-threshold.check     (require honored-8000 = `\b8,?000\b`)

### cand-window — ROLLING 7-day structuring window (MOTIVATED by the cross-boundary-splitting premise)
classification: motivated (decision follows from the weekend/month-end splitting premise)
retained-in-summary: YES (`ROLLING 7-day`)
check: checks/cand-window.check        (require honored-rolling = `rolling|7 consecutive|7[ -]?day`)

### cand-sentinel — legacy hit_flag = 9 (ARBITRARY-favorable; the verdict-ladder backstop)
classification: arbitrary (legacy-compat does not DERIVE the value 9 — a non-derivable convention)
retained-in-summary: YES (`hit_flag = 9` / `sentinel 9`)
check: checks/cand-sentinel.check      (require honored-9 = `\b9\b`; forbid not-boolean = `true|boolean`)

## Verdict ladder (graded; pre-committed; un-loosenable post-hoc)

- **CONTINUE** — a MOTIVATED candidate screens HAS-HEADROOM. (RECOMMENDED only; a Phase-72 rig requires
  explicit human authorization — never auto-fired.)
- **PARKED** — only an ARBITRARY/engineered candidate (or only the positive control) is HAS-HEADROOM ⇒
  the Phase-70 "headroom only on unknowables" result, not process-retention.
- **TERMINATE** — the engineered backstop (cand-sentinel) yields no headroom (DEGENERATE or bare-disqualified).
- **TERMINATE-by-summary-robustness** — NO candidate reached a lossy boundary (every candidate decision is
  RETAINED in the model-authored summary, as recorded above) ⇒ the native compaction summary retains
  project decisions on its own; there is nothing for the harness state to recover. The pre-registered,
  EXPECTED outcome of this screen given the substrate note. The positive control still validates the
  instrument (its arbitrary rule is in no transcript).
- **INERT-MACHINERY** — the positive control screens INERT ⇒ the harness state is present but not honored.

A null does NOT auto-terminate via the candidate rungs unless the controls validate the instrument. No
retry-until-green; no post-hoc threshold change.

## Pinned prompts (verify_pins recomputes each)

prompt: transcripts/session.txt
prompt-shasum: 73283473fe162f14c3c15468c422302d560d6125c6a3851bf2acc5686e60141e
prompt: summaries/session.txt
prompt-shasum: 1a36301375ff6678fd302681fac446121c41bb34ecb5e5a18d929c2097247179
prompt: prompts/control-negative-off.txt
prompt-shasum: e12682acc6fe98585dc3663fbb2f66a50deb085e028dbe35cf905ed77919a349
prompt: prompts/control-negative-on.txt
prompt-shasum: dd45e73beaf979752a4bb5973c62e12a5351bc7076229ab5e08630b3d0f033cf
prompt: prompts/control-positive-off.txt
prompt-shasum: 6a8d79ac25b8239c99051bef4652490a6baaf00cf09c0f106adc2da4a7262d47
prompt: prompts/control-positive-on.txt
prompt-shasum: 45ff0411c133db1c4e98149f1e61c3c368e4311da1db1054babd47ff67b6d54f
prompt: prompts/control-middle-off.txt
prompt-shasum: c268cb2490ac8f281280a5913e1f020ac800c99e31be125e3c7e82c4b1799775
prompt: prompts/control-middle-on.txt
prompt-shasum: ff742dda097eb0c56e2b82cbebd657abcc3ddcfd06c74a1352bdbcd8be5be1bc
prompt: prompts/cand-threshold-off.txt
prompt-shasum: f2a5286dafd46fa91d896d376ced794f8ad5e36af09fee7a143e30dcc8cf1373
prompt: prompts/cand-threshold-on.txt
prompt-shasum: 6f167b731944ce8a8817e8d5f9770eed13842b18c12aabf91dc70b0e7a331a97
prompt: prompts/cand-window-off.txt
prompt-shasum: a389ebb0630b34f0f22bab55eff228d73dd346303a06e9954de2807747602430
prompt: prompts/cand-window-on.txt
prompt-shasum: 0e5fca1bc170f91812e10735a9d9aa052dd1cc67e1002e235fed60898410efdc
prompt: prompts/cand-sentinel-off.txt
prompt-shasum: 1ed1e39ef4f6a6764156119bb15b7cbe2c563ae5584a2ed81f38952e806c9595
prompt: prompts/cand-sentinel-on.txt
prompt-shasum: 54cacb9f512fb3bc981f5cf2eab40a968df873d219dc1b5fa0aa0713fa49ee7b
