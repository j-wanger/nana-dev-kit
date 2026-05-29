<!-- nana:approved 2026-05-29 -->
# Spec: Harden Hot-Cache Curation

## Objective
Make the always-loaded hot cache (`.claude/rules/working-knowledge.md`) enforce its own integrity invariants — size cap, no duplicate propositions, well-formedness, pinned-protection — deterministically and test-covered, replacing the unreliable LLM-executed prose that currently maintains it, and correct the dedup key (proposition content, not source slug).

## Context
Phase 61 established that the always-loaded markdown hot cache is the harness's effective retrieval layer (it made every planning baseline strong; all five runtime-retrieval alternatives measured net-zero-or-negative). Today four touchpoints maintain it via prose an AI executes by hand: dev-plan Step 16f-ter (seeding), dev-debrief `active-knowledge-transition.md` (carry-forward), the session-start hook `templates/.claude/hooks/session-start.d/wk-prune.sh` (age-based >30d `[uses:1]` prune, max 5/run, skips `[pinned]`, a sourced function `prune_working_knowledge(WK_FILE, STALE_QUEUE)` called from `session-start.sh`), and the policy doc `templates/.claude/skills/dev-wiki/working-knowledge-spec.md`. The 100-entry / 210-line cap is enforced only by LLM prose on a file already at 100/100. The spec doc codifies a WRONG dedup rule ("if same `source:` slug exists, increment `uses` instead") that, if followed, collapses distinct facts — the live file proves `phase-45` legitimately has 6 distinct entries under one source slug. This is the documented session-start.sh cap-erosion anti-pattern (Phase 55: a 70-line cap eroded to 137 over 30 phases with no test catching it) aimed at the harness's most reliable knowledge channel, which ships to every scaffolded project via the installer's `cp -r`.

## Scope
### In scope
- Extend the existing deterministic prune hook (`templates/.claude/hooks/session-start.d/wk-prune.sh`) into the single curator: add cap-enforce, exact-proposition dedup, well-formedness handling, and atomic write.
- Correct the dedup key (proposition content, not source slug) and consolidate the cap/eviction/dedup policy into ONE source of truth (`working-knowledge-spec.md`); the other three touchpoints reference it instead of restating the algorithm.
- New invariant test `tests/test_working_knowledge_curation.sh` wired into `make test`.
- Dogfood verification on the live repo cache.

### Out of scope
- Distillation-quality improvement / any LLM-judge evaluation (unmeasurable by the binary runner; Phase 61 showed the cache at quality-ceiling — no headroom).
- Changing the user-gated seeding prompt (dev-plan 16f-ter offer).
- A "regenerate hot cache from wiki articles" derived-view redesign (future option).
- Renumbering dev-plan steps (the 16f-ter sub-letter stays — protects `tests/test_step_numbering.sh`).
- Concurrency locking across producers (single-writer-at-session-start assumption documented; atomic rename bounds worst case to one lost append, never corruption).

## Approach
The curator is deterministic bash, a single enforcement point that runs at session-start. It is fail-safe: it builds the proposed new file content in a temp file, validates that content structurally, and only then atomically renames over the original — aborting (leaving the original byte-intact) on any validation failure. Eviction "least valuable" ranking is usage-count ascending, ties broken by oldest `activated:` date ascending, and `[pinned]` entries are excluded from the candidate set entirely. Duplicate detection is keyed on the normalized proposition text only — never the source slug. Exact-duplicate auto-removal keeps the surviving entry with the higher `uses` count; fuzzy near-duplicates are flagged to the stale queue (advisory), not auto-removed, to avoid false-positive data loss on a mandatory file. If any entry fails 2-line pairing, the curator no-ops the entire file and warns — it never attempts per-entry repair on a mandatory file. The three other touchpoints stop re-implementing the prune algorithm in prose and point to the single policy doc.

### Domain Research Questions
1. The usage counter is empirically inert (87/100 entries stuck at `uses:1` because it only increments on exact source re-cite) — is recency-among-floor-uses the honest eviction signal, or does a meaningful value signal exist that isn't just recency in disguise?
2. How should "exact duplicate proposition" be normalized (leading `- [uses: N] ` prefix, surrounding whitespace, trailing punctuation) so it catches genuine duplicates without false-positiving distinct same-topic facts (e.g. the 6 `phase-45` entries that all mention "heuristic")?
3. Should cap-enforcement run only at session-start, or also at each producer write — what is the cost/benefit of the file sitting over-cap between sessions?

## Constraints (CRITICAL)
- Curator MUST write atomically (temp file + structural validation + atomic rename); on any validation failure it MUST abort leaving the original file byte-intact — prevents shipping a truncated mandatory file to every project.
- Curator MUST NOT evict or alter any `[pinned]` entry; assert `(evicted ∩ pinned) = ∅` before writing — prevents overriding explicit human keeps. If pinned entries alone exceed the cap, pins win: the cap is exceeded and a warning is emitted (never evict a pin to meet the cap).
- Dedup MUST key on normalized proposition text, never on the `source:` slug — prevents collapsing distinct facts that legitimately share a source phase (proven live: `phase-45` ×6). Exact-dup merge keeps the higher `uses` count.
- Any 2-line pairing failure (a proposition line not followed by an indented `source:`/`activated:` line, or vice-versa) MUST trigger a whole-file no-op plus a warning, leaving the file byte-intact — no per-entry deletion, quarantine, or repair is attempted on a mandatory file. This dominates "drop the bad entry" on the never-lose-knowledge axis and keeps the bash simple.
- Cap is NON-STRICT: at exactly 100 entries and ≤210 lines the curator MUST be a no-op (no eviction at the boundary). Cap precedence: the entry-count bound (≤100) is primary; eviction proceeds until entries ≤100, which — given strict 2-line entries plus a ≤3-line header — also satisfies ≤210 lines. If lines >210 while entries ≤100, that signals wrapped/malformed entries and routes to the well-formedness no-op path, not eviction.
- Curator MUST preserve the exact `[uses: N]` and `activated: YYYY-MM-DD` token format on surviving entries (other machinery — wiki-query increment, the heuristic matcher — parses them). A merged survivor re-emits its `uses` count in the same `[uses: N]` format.
- Curator MUST be idempotent: a second run immediately after the first produces no change.
- Empty or absent file MUST be a clean no-op (new projects ship no cache — verified: `templates/` contains no `working-knowledge.md`).
- All edits land in `templates/` (the `cp -r` install source), not only the global installed copy.
- Do NOT renumber dev-plan steps.

## Success Vision
The hot cache polices itself: a session-start curator deterministically keeps it within cap, free of exact-duplicate propositions, and structurally well-formed, while never touching pinned entries and never losing knowledge silently (age-pruned and near-duplicate entries are logged to the stale queue; a malformed file is left intact with a warning). The policy lives in exactly one place; the planning, debrief, and spec prose point to it instead of each re-deriving a prune algorithm an AI then executes by hand. A regression test asserts the invariants — including the now-fixed rule that distinct facts sharing a source survive — so the next 30 phases cannot silently erode the cap the way session-start.sh eroded 70→137 lines unnoticed. Running the curator on the real repo cache changes nothing (it is already valid), proving the curator is safe before it ever evicts in production.

## Exit Criteria (machine-checkable)
- [ ] `bash tests/test_working_knowledge_curation.sh` passes: over-cap→cull to ≤100 oldest-first; `[pinned]` never evicted (incl. all-pinned-over-cap → pins win, cap exceeded + warning); exact-dup→removed keeping max `uses`; distinct-facts-same-slug→NOT collapsed; malformed→whole-file no-op + warning; exactly-100→no-op; idempotent second run; existing >30d prune still works
- [ ] `grep -rEn "increment .?uses.? instead" templates/` returns nothing (the wrong directive removed from all touchpoints, including the hook)
- [ ] `grep -q "proposition text" templates/.claude/skills/dev-wiki/working-knowledge-spec.md` (the corrected content-based dedup rule is documented — positive assertion)
- [ ] `make test` exits 0 and its output includes `test_working_knowledge_curation.sh`; the suite runs ≥13 scripts (was 12 + 1 new — do not hard-code if the run reports more)
- [ ] `make eval` unchanged at its current baseline (54 scenarios per Phase 61 — confirm with the run; do not hard-code if the run reports a different count)
- [ ] `bash tests/test_step_numbering.sh` still passes (no step-renumber side effects)
- [ ] Dogfood: running the curator on the real `.claude/rules/working-knowledge.md` evicts 0 entries, removes 0 duplicates, and leaves all distinct `phase-45` entries intact (a diff shows no knowledge lost)

## Checkpoints
- After the curator + test pass on synthetic fixtures, BEFORE running on the live repo cache: confirm the dogfood run is a no-op (file at exactly 100 = fixed point). If it would evict or remove anything on the live file, STOP — the logic is wrong.
- If well-formedness parsing reveals the live file violates the 2-line invariant: STOP and report (do not auto-fix a mandatory file).

## Assumptions
- Entries are exactly 2 lines (proposition + indented `source:`/`activated:` line). If false: curator bails (no-op) and reports.
- `[pinned]` is the protection token (wk-prune already uses it). If a different convention exists: stop and reconcile before shipping eviction.
- The kit ships no populated `working-knowledge.md` (verified). If a populated template is later added: it must pass the curator's validator.
- `make eval` baseline is 54 scenarios (Phase 61). If the run reports a different count: use the actual current count as the unchanged baseline, do not force 54.
