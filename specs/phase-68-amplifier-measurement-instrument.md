<!-- nana:approved 2026-05-29 -->
# Spec: Amplifier Measurement Instrument (real-transcript proxy emitter, control-validated)

## Objective
Build the deterministic measurement layer ("the ruler") for the amplifier vision: a read-only script that ingests a real Claude Code session transcript (jsonl) plus the session's final git and test/lint state, and emits a single proxy-vector JSON capturing mechanical outcomes AND human-attention-economy observables. Prove the ruler reads correctly with a positive/negative control pair anchored on the stock-screener "same-day-close / look-ahead" decision. This phase validates the INSTRUMENT only — no harness verdict, no live run, no LLM judge in the scoring path.

## Context
The next era of nana-dev-kit reframes the harness from agent-discipline-enforcement to a user-capability amplifier: route domain/directional decisions to the human, let the model run execution autonomously, and measure whether human judgment landed where it mattered without being wasted. That vision is unfalsifiable without a measurement instrument — which is why this is Frontier 0 (the prerequisite), not a downstream validation step.

This project has abandoned two prior evals in exactly this space, and this spec must clear both bars:
- **Phase 65 (killed before any code):** a hand-authored hook-event fixture-replay asserting an action-delta merely duplicated the trusted binary corpus (`eval/corpus`, `make eval`) — "a coarser function of the same observations." The distinguishing ingredient of a real eval is **trace provenance**: events from real session firings, not fixtures.
- **Phase 66 (built a probe, then parked the scorer):** the enforcement-firing scorer was parked on two structural blockers — (a) **representativeness** (the kit's own `.dev-wiki/enforcement.log` samples the maintainer editing the kit, never a consuming-project agent) and (b) a **schema-gap** (`enforcement.log` records the hook's *decision*, not the agent's subsequent *action* — no firing→response link).

This instrument clears both: it reads the **session transcript**, which carries the hook firing, the agent's action, and the human's response in one ordered stream (closing the Phase-66 schema-gap), and it measures an observable class — attention-economy events — that the corpus cannot express in exit codes (clearing the Phase-65 duplication bar). Representativeness (Phase-66 blocker (a)) is deliberately deferred: Phase 68 validates the ruler against constructed controls + at least one real transcript; the live consuming-project off/on run and the harness verdict are Phase 69.

Enablers confirmed to exist: session transcripts as jsonl under `~/.claude/projects/<project-slug>/*.jsonl`; the Phase-65 `enforcement.log` schema `{schema_version, ts, hook, action, reason, phase}`; the HOME-override sandbox-isolation pattern in `tests/test_install.sh`. `eval/comparison/` is a Phase-65 tombstone ("do not rebuild the apparatus") — the new instrument lives in a fresh directory.

## Scope
### In scope
- A new `eval/amplifier/` subdirectory for the instrument (NOT `eval/comparison/`), with the emitter at `eval/amplifier/emit-proxy-vector.*` (`.py` or `.sh` — implementer's choice).
- A read-only emitter script: input = one session transcript jsonl (+ paths/refs to the session's final git state, test/lint result, and an optional `enforcement.log`); output = one proxy-vector JSON to stdout.
- The proxy-vector schema (exactly the four field-groups in **Success Vision** — no more).
- A keyword-anchored, event-boundary-scoped ground-truth detector for the "same-day-close / look-ahead / entry-timing" phrase family (canonical phrase list pinned in **Constraints**).
- A positive/negative control fixture pair (minimally different — ideally identical except the one escalation turn) anchored on that decision.
- A functional-smoke test asserting the control-pair flip + a clean read of ≥1 real transcript, wired into `make test`.
- Reuse of the Phase-65 `enforcement.log` schema and the `test_install.sh` HOME-override pattern.

### Out of scope (deferred to Phase 69+)
- Any live before/after (off vs on) session run, and the actual harness verdict.
- n>1 / repeated paired runs and statistical aggregation.
- Automated condition isolation / harness install-uninstall / headless execution.
- Executing the `eval/comparison` + `eval/reasoning` apparatus disposition (separate roadmap item, unblocked once this lands).
- Frontier 1 itself (the escalation/classification layer). This phase builds the ruler that will later measure it.
- A configurable multi-domain detector — the phrase family is fixed and known.

## Approach
Build a single read-only reader that derives the proxy vector from observables that already exist after a real coding session, keeping the entire scoring path deterministic (literal/regex/normalized-string matching only — no LLM, embedding, or similarity call anywhere). The transcript jsonl is an **unversioned internal CLI format**: tolerate unknown/extra event types and missing optional fields rather than binding tightly to a schema that will drift. The ground-truth detector must scope its phrase match to escalation/question *event* boundaries (e.g. an `AskUserQuestion` tool-use turn), not to raw transcript text — the same phrase appearing in agent reasoning, a code comment, or tool output is "buried," not "surfaced." Each field-group must emit an explicit sentinel when its source is absent, never coerce a missing source into a `0` that reads as a real measurement. Validate by differential assertion: the control pair must *flip* the detector and at least one interaction proxy between surfaced and buried — proving the reader discriminates, not that it returns a hardcoded constant (the exact Phase-65 degenerate-reader trap).

### Domain Research Questions
- How does the Claude Code transcript jsonl actually represent the events we need — human turns vs tool-results, `AskUserQuestion`/escalation turns, assistant tool-use? Are these distinct `type`s, tool-call names, role markers, or some combination? (Inspect real transcripts before committing to a parse.) Which sub-fields of an `AskUserQuestion` event (question text, options, answer) are in scope for the detector?
- What is the cheapest *deterministic* signal that approximates "a human turn redirected the agent" without an LLM — e.g. an unsolicited human turn (not a direct answer to an `AskUserQuestion`) followed by a change in the agent's next tool/action sequence? Is this clean enough to ship, or should it be marked experimental/deferred rather than gold-plated?
- Which proxy fields, if any, does the existing `tests/` + `eval/` already compute deterministically? (If a field is already pinned by the corpus, it is duplication — drop it or justify the new provenance.)

## Constraints (CRITICAL)
- **No LLM/neural/embedding/similarity/"fuzzy" call anywhere in the read or validation path** — Guard: scoring is literal/regex/normalized-string only; reviewer + code inspection confirm no model call in the emitter or its test. Prevents reintroducing the blind instrument the whole phase exists to avoid.
- **Read-only instrument** — Guard: the emitter must not mutate the transcript, git repo, `enforcement.log`, or any project state; the test checksums each input before/after and asserts equality, and asserts no write into the kit's own `.dev-wiki/`/`.nana/`. Prevents corrupting the measured session and the recurring kit-self-pollution isolation hazard.
- **Detector anchors on escalation-event boundaries, not raw text** — Guard: a buried-control fixture that contains the trading phrase *outside* any question/escalation turn (in reasoning/code/tool-output) must read as buried (false). Prevents the Phase-66-analog failure of matching the topic anywhere instead of topic-raised-as-a-question.
- **Missing source ⇒ explicit sentinel, never silent 0** — Guard: absent `enforcement.log` ⇒ that field is `null`/absent-flagged, not `0`; absent git repo / no commits likewise. The test asserts the sentinel for an absent enforcement log. Prevents a missing source corrupting a later harness comparison as "fired zero blocks."
- **Keyword match is normalized but bounded to the declared phrase family** — Guard: case/whitespace/diacritic-normalized matching of the explicit phrase set ("same-day close", "same day close", "look-ahead", "lookahead", "entry timing"); no stemming that would match the bare word "timing". Prevents both formatting false-negatives and over-broad false-positives.
- **Malformed/partial jsonl is skip-and-count, not silent-drop and not whole-file abort** — Guard: a fixture with one corrupt line plus a trailing partial line yields a valid vector AND a non-zero `parse_errors` count; an unreadable file is distinguishable from a zero-turn session. Prevents both brittle crashes and silent measurement loss.
- **The proxy-vector schema is frozen at exactly the four field-groups** — Guard: reviewer rejects any added "while we're here" git/interaction metric; new proxies belong to a later phase. Prevents scope creep into a metrics-zoo.
- **No verdict output** — Guard: the emitter emits raw observations only; no threshold, grade, or good/bad-harness field. Prevents drifting from "prove the ruler reads" into "judge the harness" (the over-reaching-eval pattern).
- **Do not modify `enforcement.log` schema or the binary corpus; do not resurrect `eval/comparison/`** — Guard: `make eval` count stays unchanged; `git status` shows no edits under `eval/comparison/`, `eval/corpus/`, or the enforcement-log writer.

## Success Vision
A small, auditable, read-only ruler that anyone can point at a real session transcript and get back a faithful, deterministic proxy vector — and a control-pair proof that the one observable unique to the amplifier hypothesis (was the critical domain decision *surfaced to the human as a question* vs *buried*) is read correctly. Excellent looks like: the emitter degrades gracefully on messy real transcripts (unknown events, partial lines) without lying about what it couldn't read; the controls differ by exactly one escalation turn so a passing flip is unambiguous proof the detector is what flipped; and the whole thing is obviously LLM-free on inspection. The proxy vector contains exactly these groups:
- **mechanical** (from final git + test/lint state): tests-pass (bool), lint/type finding count, commits-to-first-green (count of commits from the session's first work commit up to and including the first commit at which the test command exits 0; `0` if the first commit is already green, sentinel if no commit is ever green or there are no commits), reverts/fixups count (commits identified by `git` structure — `git revert` provenance or `--fixup`/`squash!`/`fixup!` message prefixes — NOT by the word "fix"/"revert" appearing anywhere in a message).
- **interaction** (from transcript jsonl): human-turn count, escalation/`AskUserQuestion`-event count, tool-use count, and a redirect proxy. **Decision rule for the redirect proxy:** if it can be computed purely from event *structure* (e.g. an unsolicited human turn — one not answering an `AskUserQuestion` — followed by a change in the agent's next tool/action sequence), ship it as a real field; if a correct definition would require reading message *semantics*, emit it as an explicit `null` labelled `deferred` rather than guessing. Do not gold-plate.
- **enforcement** (on-condition only, from `enforcement.log`): block-action count — or an explicit absent-sentinel.
- **ground_truth**: surfaced (bool) for the same-day-close/look-ahead decision, scoped to escalation events.

The honest framing is preserved throughout: this measures the ruler, not the harness; the harness verdict needs real-provenance off/on runs, which is Phase 69.

## Exit Criteria (machine-checkable)
- [ ] `ls eval/amplifier/emit-proxy-vector.* >/dev/null 2>&1` — the named emitter exists under the new `eval/amplifier/` dir (not `eval/comparison/`).
- [ ] `bash tests/test_amplifier_emitter.sh` — exits 0: asserts (1) the ground_truth detector flips true→false between the surfaced and buried control fixtures, (2) at least one interaction proxy differs between them, (3) the buried-but-phrase-present-outside-an-escalation fixture reads false, (4) absent `enforcement.log` yields the sentinel not 0, (5) a one-corrupt-line fixture yields a valid vector with non-zero `parse_errors`.
- [ ] The emitter emits valid 4-group JSON from ≥1 **real** transcript: `eval/amplifier/emit-proxy-vector.* <a real ~/.claude/projects/.../*.jsonl> | jq -e 'has("mechanical") and has("interaction") and (.ground_truth|has("surfaced")) and has("enforcement")'` returns 0.
- [ ] Read-only proven: the test captures `shasum` of every input fixture before and after a run and asserts equality (no mutation), and asserts no file created under the repo's `.dev-wiki/`/`.nana/` during the run.
- [ ] No LLM in the scoring path: `! grep -rqiE 'anthropic|openai|claude -p|\bllm\b|embedding|cosine|sentence-transformers|fastembed' eval/amplifier/` (or every match is in a comment explaining its absence).
- [ ] `make test` exits 0 at the new script count (test wired into the Makefile).
- [ ] `make eval 2>&1 | grep -qE '52/52|52 / 52'` — corpus count unchanged (no scenarios added).
- [ ] `git status --porcelain eval/comparison eval/corpus | grep -q . && exit 1 || true` — no edits to the tombstone apparatus or the corpus.
- [ ] Phase-69 handoff recorded: the decision article (or roadmap) names the deferred items (live off/on run, n>1, representativeness, apparatus disposition) as Phase-69 preconditions.

## Checkpoints
- **T1 (FIRST / hard checkpoint) — transcript-schema feasibility:** before building the emitter, inspect ≥2 real transcripts and confirm they carry distinguishable human turns, tool-use events including `AskUserQuestion`, and assistant actions. Report what fields back each proxy. **If the needed fields are absent → STOP and report:** the capture mechanism must pivot to a custom logging hook (a larger redesign) rather than transcript-parsing. Do not build the emitter until this passes.
- **After the emitter + control pair:** report the control-flip result and the real-transcript read before wiring into `make test`.
- **If the redirect proxy cannot be made cleanly deterministic:** apply the Success-Vision decision rule — computable from event structure → ship; requires message semantics → emit `null` labelled `deferred`. Do not gold-plate; report the decision.

## Assumptions
- The transcript jsonl contains human turns, `AskUserQuestion`/escalation turns, and assistant tool-use as machine-distinguishable events. If false: T1 stops the phase; pivot to a logging-hook capture mechanism (re-scope).
- The same-day-close/look-ahead decision is expressible as a fixed keyword phrase family sufficient for a deterministic detector. If false (the decision can only be recognized semantically): STOP and PARK — encode the unblock as a committed runnable check; do NOT add an LLM judge to make the control pass.
- At least one real session transcript is available locally to validate against. If false: validate schema assumptions against any available real jsonl and flag the real-transcript exit criterion as unmet (do not substitute a synthetic transcript and call it real).
- `enforcement.log` exists only when a dev-harness session ran. If absent: the enforcement field emits its sentinel (expected for off-condition / non-harness sessions), not an error.
- The Phase-65 `enforcement.log` schema is stable. If its shape differs from `{schema_version, ts, hook, action, reason, phase}`: read defensively and count `action=="block"` records; if unparseable, emit the sentinel + a parse-error flag rather than crashing.
