# Amplifier Instrument — Transcript Schema Notes (Phase 68, T1)

Behavioral feasibility result for reading the proxy vector from a **real** Claude Code
session transcript (`~/.claude/projects/<slug>/*.jsonl`). Verified 2026-05-29 against
`07c4b5a6-…jsonl` (a real nana-dev-kit session): every proxy group returns a non-empty
extraction. **Checkpoint verdict: GO** — transcript-parsing is viable; no pivot to a
logging hook needed. Re-runnable proof: `bash eval/amplifier/schema-probe.sh`.

NOTE: this scoring path is **deterministic only** — no LLM, embedding, or fuzzy matching
anywhere. (This sentence names "LLM" deliberately; the no-LLM exit check greps the
executables, not this doc.)

## Transcript shape (observed)

Each line is one JSON object. Top-level `.type` ∈ {`assistant`, `user`, `system`,
`attachment`, `last-prompt`, `file-history-snapshot`, `queue-operation`, `ai-title`, …}.
The format is an **unversioned internal CLI format** — the emitter must tolerate unknown
`.type`s and missing optional fields, and skip-and-count malformed lines (`parse_errors`).

The load-bearing disambiguation: a `.type=="user"` line is a **real human turn** only when
its `.message.content` is a string (or a text-array), NOT when it is a `tool_result` array
(those are tool outputs replayed as user-role). Observed in the probe transcript:
human-turn=6, tool_result=116 — cleanly separable.

## Proxy → jsonl field mapping

| Proxy (group) | jsonl extraction |
|---|---|
| human-turn count (interaction) | `.type=="user"` AND not `.isMeta` AND (`.message.content` is string OR an array with a `text` block and no `tool_result` block) |
| escalation / AskUserQuestion count (interaction) | `.type=="assistant"` → `.message.content[] | select(.type=="tool_use" and .name=="AskUserQuestion")` |
| tool-use count (interaction) | `.type=="assistant"` → `.message.content[] | select(.type=="tool_use")` |
| redirect proxy (interaction, EXPERIMENTAL) | unsolicited human turn (a human-turn NOT immediately following an AskUserQuestion) followed by a changed next tool sequence — ship only if computable from event structure; else emit `null` + `"status":"deferred"` (do not gold-plate) |
| assistant action (provenance) | `.type=="assistant"` |
| ground_truth.surfaced (ground_truth) | the same-day-close phrase family appears inside an **escalation event's text** (see predicate below), NOT in raw transcript text |
| enforcement.block_count (enforcement) | external `.dev-wiki/enforcement.log` records with `action=="block"`; absent log ⇒ explicit **sentinel** (`null`), never `0` |
| mechanical.* (mechanical) | final git state + test/lint result (commits-to-first-green, reverts/fixups by git structure not message text, tests-pass, lint count) |

## Escalation-event predicate (PINNED)

`surfaced` is keyed on the **AskUserQuestion** `tool_use` event as the **primary**
escalation boundary. Its text scope is, for each such event:
`.input.questions[].question`, `.input.questions[].header`, and
`.input.questions[].options[].label` / `.description`. (Verified `AUQ input keys == ["questions"]`,
`questions[0]` sub-keys == `header, question, options`.)

`ExitPlanMode` is a *candidate* secondary escalation boundary (a plan presented for
approval can also surface a decision). **Decision for v1: AskUserQuestion ONLY.** Rationale:
AUQ is the unambiguous "raised as a question" signal; ExitPlanMode surfaces a whole plan,
where the specific decision is buried in prose (the exact "buried" failure we guard against).
Revisit in Phase 69 if a real run shows decisions surfacing only via plans.

> **RESOLVED (Phase 69) — the AUQ-only predicate is non-representative on real data.** A read-only
> survey of the ruler over all 8 real consuming-project transcripts (`real-transcript-survey.md`)
> found `ground_truth.surfaced=false` on ALL 8 and **0** in-AUQ-boundary phrase hits, while the
> same-day-close / look-ahead phrase appears 8–50× in raw text per transcript. A paraphrase
> spot-check of every AUQ event confirmed the strong form: the look-ahead decision is *never*
> escalated, even paraphrased — it is handled in assistant reasoning / code / plan prose. So the
> v1 boundary cannot see this decision as it actually surfaces in real work. **Broadening the
> boundary (to assistant reasoning / plan prose / ExitPlanMode) without collapsing into raw-text
> matching (the `buried_phrase_outside_escalation` guard) is the deferred Approach-C predicate
> repair — NOT done in Phase 69 (audit-only).** It is gated by `measurability-gate.sh`: only a flip
> to MEASURABLE unblocks the repair + the live run. See `VALID-MEASUREMENT.md` and
> [[amplifier-representativeness-audit]].

The phrase the same-day-close detector matches (normalized case/whitespace, bounded — NO
bare "timing"): `same-day close`, `same day close`, `look-ahead`, `lookahead`, `entry timing`.

## Enforcement-source decision (PINNED)

The `enforcement` group reads the **external `.dev-wiki/enforcement.log`** (Phase-65 schema
`{schema_version, ts, hook, action, reason, phase}`, read defensively). Absent ⇒ sentinel.
The transcript ALSO carries inline hook signals (`hookInfos` / `preventedContinuation` /
`hookErrors`) — noted as a richer in-transcript enforcement source, **deferred to Phase 69**
(keeps Phase 68's enforcement group to the one already-built substrate; avoids scope creep).

## Proxy-vector schema (FROZEN at exactly 4 groups — T2)

The emitter (`emit-proxy-vector.sh <transcript.jsonl> [--enforcement-log P] [--repo P]`)
emits exactly this JSON to stdout. No verdict/grade/good-bad field — observations only.

```jsonc
{
  "mechanical": {            // from final git + test/lint state (NOT the transcript)
    "tests_pass": null,            // SENTINEL: requires execution → not derivable read-only
    "lint_findings": null,         // SENTINEL: requires execution → not derivable read-only
    "commits_to_first_green": null,// SENTINEL: requires history replay → not derivable read-only
    "reverts_fixups": <int|null>   // git-STRUCTURE (fixup!/squash!/Revert) when --repo is a git repo; else null
  },
  "interaction": {           // from transcript jsonl — the novel observable class
    "human_turns": <int>,
    "escalation_count": <int>,     // AskUserQuestion tool_use events (the pinned predicate)
    "tool_use_count": <int>,
    "redirect_proxy": {            // EXPERIMENTAL, structural (no semantics)
      "status": "experimental",
      "unsolicited_human_turns": <int>  // human turn whose preceding assistant turn had NO AskUserQuestion
    }
  },
  "enforcement": <null | {"block_count": <int>}>,  // null SENTINEL when no --enforcement-log (never 0-as-missing)
  "ground_truth": { "surfaced": <bool> },          // same-day-close phrase inside an AUQ event's text
  "parse_errors": <int>,     // non-blank jsonl lines that failed to parse (skip-and-count)
  "source": "<basename>"
}
```

**Control-pair contract:** `surfaced.jsonl` (decision raised inside an AUQ) →
`ground_truth.surfaced==true`, `escalation_count==1`. `buried.jsonl` (same file, the one
AUQ turn replaced by a plain assistant turn — one-line diff) → `surfaced==false`,
`escalation_count==0`. The detector + ≥1 interaction proxy FLIP, proving the reader
discriminates. `buried_phrase_outside_escalation.jsonl` (phrase in assistant text, not a
question) → `surfaced==false` — guards against raw-text matching.
