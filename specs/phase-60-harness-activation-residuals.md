<!-- nana:approved 2026-05-29 -->
# Spec: Harness Activation Residuals (Phase 60)

## Objective

Close out the Phase 57+ harness-activation roadmap with the two remaining residual fixes, each delivered with a deterministic, test-backed success criterion rather than a "looks better" rewrite:

- **Fix 3 — AGENTS.md budget + salience trim:** reshape `templates/AGENTS.md` so the highest-leverage rules lead, every command sequence is stated exactly once (the lint/type/test triplet is currently duplicated at lines 9–11 and 77–79), and the always-loaded line budget is codified as a test assertion instead of an unenforced comment.
- **Fix 5 — kit-uninitialized nudge:** when the kit's session-start hook runs in a project with no `.dev-wiki/`, emit a single actionable "run `/nana-init`" nudge, verified by a firing test (the project's own "verify firing, not presence" discipline).

## Context

These are the last two items of the harness-activation roadmap: Fix 1 (hook consolidation) shipped Phase 57; Fix 2 (domain research in dev-plan) shipped Phase 58 and was CUT in Phase 59 after a pre-registered measurement showed it net-negative; Fix 4 (cognitive-readiness actionable) was closed by Phases 55/56. Fixes 3 and 5 are bundled here because both are small, both touch session-start/template surfaces, and bundling avoids two ceremony cycles.

**Why this is a deterministic phase, not a measured one (evidence-based scope decision).** Phases 58–59 used judge-scored A/B evals because they changed *reasoning behavior* and the effect size was the open question. Neither fix here changes reasoning: Fix 3 is a dedup + reorder + cap on a template file; Fix 5 is a conditional advisory line in a shell hook. Manufacturing a judge-eval for a deterministic change is the "process theatre" the soul tells me to avoid. The rigorous move for these is structural assertions (dedup count, line cap, section ordering) and hook firing tests — evidence a skeptic can re-run in one command, with no judge variance to launder. The deeper claim the AGENTS.md file itself asserts unverified ("~300 lines total before instruction-following degrades", line 84) IS a real research question, but testing it is a separate research phase, not a trim; it is flagged as a future candidate, not fake-tested here.

**Fix 5 false-positive, empirically resolved.** The user chose trigger = "any missing `.dev-wiki/`" after I flagged a false-positive risk. I verified the risk concretely: session-start IS globally wired on this machine (`~/.claude/settings.json` references it; `~/.claude/hooks/session-start.sh` exists), so the trigger fires in every non-nana directory. But it fires as one line inside the `[nana:cognitive]` Readiness block that session-start *already* emits unconditionally, and when uninitialized the per-component lines are all "inactive/none" filler. So the nudge can REPLACE that filler with a single actionable line — making the bare-dir output cleaner, not noisier. The user's call is validated by evidence and implemented as a net improvement.

## Scope

### In scope
- `templates/AGENTS.md`: dedup the doubled lint/type/test command sequence to a single canonical statement; reorder so Hard Rules / highest-leverage constraints lead; preserve every actual convention, the three `{{...}}` placeholders, and the `Pre-commit sequence` section name (both guarded by existing tests). Net line count must DROP below the current 86.
- `tests/test_templates.sh`: add (a) a no-duplication assertion (the runnable command triplet appears once), (b) a codified line-cap assertion for `templates/AGENTS.md`, (c) a salience-ordering assertion (Hard Rules precede the Project Structure block).
- `templates/.claude/hooks/session-start.d/cognitive-readiness.sh`: detect missing `.dev-wiki/` and emit a `/nana-init` nudge via the existing `needs_attention` / recommended-action path; short-circuit the moot per-component readiness detail when uninitialized.
- A firing test (new `tests/test_cognitive_readiness.sh` or an extension of an existing suite) that sources the hook and asserts the nudge fires when `.dev-wiki/` is absent and does NOT fire when it is present.
- Makefile/test-runner wiring for any new test script; `.dev-wiki/*` lifecycle artifacts.

### Out of scope
- Any judge-scored / A/B quality eval of either fix (deterministic changes — see Context).
- Measuring whether always-loaded instruction budget actually affects instruction-following (separate research phase; flagged as a future candidate).
- The language-agnostic split of AGENTS.md (gap 4.1) — the user picked "budget + salience trim", not the split; the Python-specific template stays Python.
- vector-search-default-on and the language-agnostic core (deferred Phase-60 alternatives).
- The kit adopting its own per-project `.claude/settings.json` (deferred since Phase 57).

## Approach

1. **Fix 5 (RED→GREEN→REFACTOR):** add the firing test first (asserts no `nana-init` nudge today). Then in `cognitive-readiness.sh`, after the existing detection block, add an `init` state: if `.dev-wiki/` is absent in CWD, append `init` to `needs_attention` and, in the recommended-action emitter, handle `init` FIRST and suppress the now-moot enforce/wiki/memory recommendations (an uninitialized project's root action is `/nana-init`, not "touch .claude/enforce"). Keep the kit-inventory line (meaningful even in a bare dir). Verify firing both directions; `bash -n` clean.
2. **Fix 3 (RED→GREEN→REFACTOR):** add the dedup + line-cap + ordering assertions to `test_templates.sh` first (they fail on the current file). Then edit `templates/AGENTS.md`: keep the `Pre-commit sequence` section as the single canonical command block; trim `## Toolchain` to name the tools and reference the sequence rather than re-spelling the three commands; move Hard Rules above Project Structure. Pick the line cap just above the trimmed size (guards re-bloat). Re-run the existing AGENTS.md tests (placeholders + section name) to confirm no regression.
3. **Integration:** `make test` green, `make eval` 100%, new test scripts wired into the Makefile test target, no non-target regression.

## Domain Research Questions

These were answered by codebase investigation (no web research needed — the domain is the kit's own internals):
- *Where does the nudge belong without duplicating an existing emit path?* → `cognitive-readiness.sh`, which already owns the `needs_attention` recommended-action pattern. A new top-level emit in `session-start.sh` would duplicate it (code-quality lens #1).
- *What does `test_templates.sh` already guarantee about AGENTS.md?* → the three placeholders and the `Pre-commit sequence` section; the dedup must preserve both.
- *Is the "any missing .dev-wiki/" trigger actually noisy here?* → yes it fires globally, but as one line in an always-emitted block; short-circuiting the moot lines makes it a net improvement (see Context).
- *Does trimming AGENTS.md break the CLAUDE.md sync?* → no; `sync-rules.sh` `cat`s the whole file with no structural dependency.

## Constraints (CRITICAL)

- **Over-trim deletes a real rule.** Dedup must remove only redundancy, never a convention. Guard: every removed/changed line traces to dedup, reorder, or the explicit budget goal — surgical discipline; the set of distinct rules (toolchain, conventions, testing, branch/commit, hard rules, structure, where-to-look) is preserved, only their statement is de-duplicated and reordered.
- **Trim breaks the existing template tests.** Guard: the `{{PROJECT_NAME}}/{{PROJECT_DESCRIPTION}}/{{PACKAGE_NAME}}` placeholders and the literal `Pre-commit sequence` section name stay; run `test_templates.sh` RED (new asserts) → GREEN (with existing asserts still passing).
- **Fix 5 nudges when the project IS initialized (false positive).** Guard: firing test asserts the nudge is ABSENT when `.dev-wiki/` exists, PRESENT when it is missing — both directions, not just the happy path.
- **Fix 5 adds a parallel emit path / contradictory advice.** Guard: reuse the existing `needs_attention` mechanism; when uninitialized, suppress the enforce/wiki/memory recommendations so the user sees one root action (`/nana-init`), not five sub-failures.
- **Manufacturing an eval for a deterministic change (process theatre).** Guard: success is structural/firing assertions only; explicitly do NOT run a judge A/B; record the unverified instruction-budget claim as a future research candidate rather than fake-testing it.
- **Line cap set so loose it guards nothing.** Guard: the codified cap sits just above the trimmed size (re-bloat tripwire), and the trimmed file is strictly smaller than the pre-trim 86 lines — the cap is a real assertion, matching the "caps need assertions, not docs" lesson (session-start.sh erosion, Phase 55).
- **CLAUDE.md / agent-surface drift after the trim.** Guard: confirmed `sync-rules.sh` regenerates copies verbatim from AGENTS.md with no structural dependency; no manual copy edits.

## Success Vision

A new project scaffolded from the kit gets an `AGENTS.md` that leads with its hardest rules, states each command exactly once, and is protected by a line-cap assertion that fails CI if it re-bloats. A kit user who opens a directory that was never initialized sees one clear `run /nana-init` line instead of either silence (today) or a wall of "inactive/none" status — and a correctly-initialized project never sees that nudge. Both behaviors are pinned by tests that check firing and structure, re-runnable in a single command, with no judge variance involved. The phase reads as two small fixes that each earn their place against the subtraction test, and it closes the harness-activation roadmap.

## Exit Criteria (machine-checkable)

- [ ] `A=templates/AGENTS.md; [ $(wc -l < "$A") -lt 86 ]` — trimmed below the pre-trim line count
- [ ] `[ $(grep -cF 'uv run pytest' templates/AGENTS.md) -eq 1 ] && [ $(grep -cF 'uv run ruff check --fix' templates/AGENTS.md) -eq 1 ]` — the lint/type/test command sequence is stated once (dedup applied to the WHOLE triplet, not just pytest; both the lead `ruff` line and the `pytest` line appear exactly once — currently 2× each)
- [ ] `grep -q 'Pre-commit sequence' templates/AGENTS.md && grep -q '{{PROJECT_NAME}}' templates/AGENTS.md && grep -q '{{PACKAGE_NAME}}' templates/AGENTS.md` — tested section + placeholders preserved
- [ ] `awk '/^## Hard Rules/{h=NR} /^## Project Structure/{p=NR} END{exit !(h>0 && p>0 && h<p)}' templates/AGENTS.md` — Hard Rules precede Project Structure (salience ordering)
- [ ] `grep -qiE 'agents.*line|line.*cap|wc -l.*AGENTS|AGENTS.*wc -l' tests/test_templates.sh` — a line-cap assertion for AGENTS.md exists in the test suite
- [ ] `grep -qiE 'nana-init' templates/.claude/hooks/session-start.d/cognitive-readiness.sh` — nudge wired into cognitive-readiness
- [ ] firing test, uninitialized: sourcing `cognitive-readiness.sh` and calling `check_cognitive_readiness` in a temp dir WITHOUT `.dev-wiki/` emits output matching `nana-init`
- [ ] firing test, initialized: the same call in a temp dir WITH `.dev-wiki/` does NOT emit `nana-init`
- [ ] the firing test script is wired into the Makefile `test` target (`grep -q test_cognitive_readiness Makefile`, or equivalent if folded into an existing suite)
- [ ] `bash -n templates/.claude/hooks/session-start.d/cognitive-readiness.sh` — syntax clean
- [ ] `make test` exits 0 (regression gate)
- [ ] `make eval 2>&1 | grep -qE 'Score: [0-9]+/[0-9]+ \(100%\)'` — eval regression gate

## Checkpoints

- After the Fix 5 firing test is GREEN: confirm both directions (fires when uninitialized, silent when initialized) and that the bare-dir output is a net reduction in noise, not an addition.
- After the Fix 3 trim: confirm the diff removes only duplicated/reordered lines — no distinct rule lost — before marking the task done.
- Before debrief: full suite + eval green; report what changed and the before/after AGENTS.md line count. Delivery accepted at the delivery gate.

## Assumptions

- `cognitive-readiness.sh` is sourceable in isolation for a firing test (it defines `check_cognitive_readiness` as a function with no top-level side effects). If false: test via the full `session-start.sh` with a temp HOME instead; do not skip the firing test.
- The user's "any missing `.dev-wiki/`" trigger is the intended semantic. If a bare-dir nudge proves genuinely disruptive in practice (beyond the one-line cost measured here), surface it at the delivery gate — do not silently narrow the trigger the user explicitly chose.
- `make test` and `make eval` run clean in this environment modulo the known optional-`sqlite-vec` memory path (already guarded to skip, Phase 58 maintenance). If a new halt appears, treat it as a regression of this phase, not a pre-existing condition.
