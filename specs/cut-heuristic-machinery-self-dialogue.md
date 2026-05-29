<!-- nana:approved 2026-05-29 -->
# Spec: Phase 64 — Cut heuristic scoring machinery + self-dialogue (batched renumber)

## Objective

Remove the never-fired Cognitive Enhancement scoring loop (matcher → judge → counter-update → lifecycle → dashboard) and the net-neutral self-dialogue planning step from the harness, while KEEPING the 17 `wiki/heuristics/*.md` articles (live test fixtures + the eval/reasoning injection corpus). A coherent subtraction — no orphaned references, tests, counters, or step-number gaps.

## Context

Phase 63's assessment classified the heuristic scoring loop DEADWEIGHT (18 counters at `helpful:0/harmful:0`, `git log -S 'helpful: 1'` empty across ~13 phases) and self-dialogue net-neutral-with-a-dangling-source (Phase 47; its `iron-rules-injection-v2.md` reference is unshipped). Both survived adversarial verification as a *coupled* removal: they share the dev-plan step-numbering surface, so they are batched here to avoid a double-renumber ([[phase-63-remediation-roadmap]] top item). This is a self-hosted edit — the harness is the artifact AND the tool the editing agent runs on — and `templates/` ships via `cp -r` to every project, so a deletion propagates everywhere. The articles the loop scored are KEPT: they are asserted by `test_templates.sh`/`test_companions.sh` and are the input corpus for the separate `eval/reasoning` experiment.

## Scope

### In scope
- Delete 8 files: dev-plan companions `heuristic-matcher.md`, `heuristic-judge-prompt.md`, `heuristic-counter-update.md`, `heuristic-lifecycle.md`, `self-dialogue-prompt.md`; `dev-debrief/heuristic-capture.md`; `scripts/heuristic-dashboard.py`; `tests/test_heuristic_evolution.sh`.
- dev-plan `SKILL.md`: remove **Step 11** (Self-Dialogue) entirely; remove **Step 13** sub-items 6–7 (heuristic judge + counter update) keeping items 1–5 (the approach-reviewer); renumber Steps 12-18 → 11-17.
- dev-debrief `SKILL.md`: remove **Step 7 (Heuristic Capture)** — the *producer* that writes counters/proposes heuristics (walk upstream, #11). This FORCES a dev-debrief renumber: SKILL.md Steps 8-22 → 7-21, companion `debrief-finalization.md` Steps 23-25 → 22-24, and Step 26 → 25; plus companion `referenced_at:` frontmatter (Steps 14/16/18) and inline step citations in `memory-harvest.md` (cites Step 12/15), `executor-prompt.md` (Step 18), `quick-debrief-flow.md` (Step 16), and SKILL.md prose (Step 11/12/15). Memory Harvest (Step 6) is SEPARATE and RETAINED.
- Renumber **sweep** across the whole cross-reference graph. dev-plan top-level 12-18→11-17 carries SUB-LETTERS with the parent: 13x→12x, 15x→14x, **16a-16i→15a-15i (incl. `16f-ter`→`15f-ter`, `16g`/`16h`/`16i`)**, 17x→16x. `test_step_numbering.sh` IGNORES postfixed steps, so dangling `16x`/`13x` refs are NOT caught by it — sweep them explicitly. Surfaces: companion `referenced_at:` frontmatter; in-SKILL prose cross-refs to Steps 13/15; `task-schema`/`plan-review-companion`/`memory-bridge`/`compaction-anchors-spec`/`artifact-writer-prompt`/`implementation-guide`; and any `Step N`/`Step Nx` citation in `.dev-wiki/`, `wiki/`, `.claude/rules/active-phase.md`, decision articles/journals, `MEMORY.md`.
- `Makefile`: drop `test_heuristic_evolution.sh` from `test:`; remove the `dashboard:` target + `dashboard` from `.PHONY`.
- `eval/corpus`: delete `skill-counter-update-companion` + `skill-evolution-lifecycle-companion`; update the eval baseline 54→52 at **every** asserted site.
- `MANIFEST`: remove the md5 + description lines for every deleted companion.
- `test_templates.sh`: remove the self-dialogue assertions + any assertion referencing a deleted machinery file; KEEP the `eval/reasoning/self-dialogue-injection.md` assertion and all 17-article format assertions.
- `working-knowledge.md`: selectively remove only entries describing the removed machinery as operational, via the curator's invariants.

### Out of scope (defer / do not touch)
- The 17 `wiki/heuristics/*.md` articles and `wiki/heuristics/SCHEMA.md` (fixtures + eval/reasoning corpus) — their vestigial `helpful/harmful/status` frontmatter stays (changing it would break the article-format assertions).
- The `eval/reasoning` experiment and its fixtures.
- The other 9 Phase-63 roadmap items.

## Approach

Order of operations to keep the self-hosted edit coherent: (1) enumerate before editing — produce the full list of every `54` literal and every `Step N`/`Step Nx` cross-reference across the tree FIRST (#3, #8); (2) classify the 2 eval scenarios and confirm each tests the *removed* machinery, not a retained component (#4); (3) delete files + edit skills + renumber as one batch; (4) sweep all reference surfaces; (5) curate the hot cache through the curator; (6) full re-verification. The renumber is the principal risk: the gap-free test validates *headings only*, so reference-resolution must be checked separately. Walk *upstream* — the cut removes both the dev-plan consumer (judge dispatch) and the dev-debrief producer (counter-writing capture step).

### Domain Research Questions
1. The dev-debrief heuristic-capture is Step 7 (top-level → forces a dev-debrief renumber). What counter-write / lifecycle coupling sits in adjacent steps (Memory Harvest is Step 6, RETAINED) that must NOT be swept out with it?
2. Do the 2 deletable eval scenarios test the removed companions specifically, or do they incidentally exercise a retained skill path that would lose its only functional test?
3. Which `working-knowledge.md` entries describe the *removed machinery as operational* (remove) vs. the *retained articles / IRON content / eval methodology / negative-result findings* (keep)? The distinction is semantic, not keyword.

## Constraints (CRITICAL)

- **Renumber that mismaps a cross-reference.** — Guard: the gap-free `test_step_numbering.sh` checks headings only; ALSO assert no `Step N` citation anywhere references a number above its skill's max heading, and spot-check that sub-lettered refs (`Step 16f-ter`) resolve to the semantically-matching renamed step. Sweep `.dev-wiki/`, `wiki/`, `active-phase.md`, eval, specs — not just the two skill dirs.
- **Assuming a hard-coded eval baseline that doesn't exist.** — Guard: the eval total is DYNAMIC — `scripts/eval-runner.sh` counts `scenario.json` files via `find` and increments `TOTAL` per scenario; there is NO `==54` assertion anywhere. Deleting the 2 scenario dirs yields `52/52` automatically with ZERO literal edits. Do not hunt for a baseline constant. The only `54` literals are historical prose in `eval/**/results.md` (+ `active-phase.md`, articles) — leave them as historical record; do not introduce a NEW hard-coded count. (`tests/test_memory.sh` contains `0.54`, an unrelated overlap ratio — do not touch.)
- **Deleting a scenario removes the only test of a RETAINED component.** — Guard: classify what each of the 2 scenarios exercises; delete only if the thing-it-tests is itself removed. If it’s the sole functional test of a surviving component, keep a minimal replacement and note it.
- **Deleted-but-still-Read/sourced.** — Guard: after deletion, no retained `SKILL.md` step Reads a deleted companion and nothing `source`s a deleted helper; `test_companions.sh` (Read-path resolution + `referenced_at:` validity) passes.
- **Orphaned MANIFEST / registration.** — Guard: remove deleted companions’ MANIFEST lines; `test_templates.sh` manifest_freshness + `test_registration.sh` (bidirectional) pass.
- **Hot-cache hand-edit fights the curator.** — Guard: route the prune through the Phase-62 curator invariants — after removing entries, the curation test passes AND a curator run on the edited cache is a byte-identical no-op (Phase-62 dogfood); no `[pinned]` entry removed; the file stays well-formed (no whole-file bail).
- **Retained article references deleted machinery.** — Guard: `grep -l` the deleted basenames across the 17 articles + SCHEMA.md returns empty; each retained article parses standalone.

## Success Vision

An entire never-fired subsystem (Phases 44–52) and a net-neutral step are gone cleanly. dev-plan and dev-debrief read as gap-free step sequences with every cross-reference still resolving. `make eval` is an honest 52/52 — no scenarios testing removed machinery, no stale 54 anywhere. The 17 articles and the eval/reasoning experiment are untouched and still pass. The hot cache no longer describes machinery that doesn't exist, and the curator treats the edited cache as a fixed point. A maintainer diffing the result sees a coherent subtraction, not a half-removal with orphaned counters, dashboards, tests, or dangling step-references.

## Exit Criteria (machine-checkable)

- [ ] All 8 target files absent: `for f in templates/.claude/skills/dev-plan/heuristic-matcher.md templates/.claude/skills/dev-plan/heuristic-judge-prompt.md templates/.claude/skills/dev-plan/heuristic-counter-update.md templates/.claude/skills/dev-plan/heuristic-lifecycle.md templates/.claude/skills/dev-plan/self-dialogue-prompt.md templates/.claude/skills/dev-debrief/heuristic-capture.md scripts/heuristic-dashboard.py tests/test_heuristic_evolution.sh; do test ! -e "$f"; done && echo OK`
- [ ] No dangling reference to any deleted file: `! grep -rIn -e 'heuristic-matcher' -e 'heuristic-judge-prompt' -e 'heuristic-counter-update' -e 'heuristic-lifecycle' -e 'self-dialogue-prompt' -e 'heuristic-capture' -e 'heuristic-dashboard' -e 'test_heuristic_evolution' templates/ Makefile tests/ scripts/ modules.json` (the 17 articles + eval/reasoning self-dialogue-injection are NOT matched by these basenames)
- [ ] `bash tests/test_step_numbering.sh` passes (dev-plan AND dev-debrief gap-free 1..N)
- [ ] No dangling top-level step citation: `! grep -rInE 'Step 18|Step 16[a-z]' templates/.claude/skills/dev-plan/ && ! grep -rInE 'Step 26' templates/.claude/skills/dev-debrief/` (dev-plan max→17 so old `Step 18` is gone and `16x`→`15x`; dev-debrief max→25 so old `Step 26` is gone) — plus a manual spot-check that surviving sub-lettered refs map correctly
- [ ] `bash tests/test_companions.sh` passes (no dangling Read paths; `referenced_at:` valid)
- [ ] `bash tests/test_registration.sh` passes
- [ ] `make eval` reports `Score: 52/52 (100%)` (the total is computed dynamically from `scenario.json` count — no count-literal to edit)
- [ ] `make test` passes (suite count = prior − 1 from removing test_heuristic_evolution; the removed script is no longer invoked)
- [ ] Retained articles clean: `! grep -rIl -e 'heuristic-matcher' -e 'heuristic-judge' -e 'heuristic-counter-update' -e 'heuristic-lifecycle' -e 'heuristic-dashboard' wiki/heuristics/`
- [ ] Hot cache curator-valid: the working-knowledge curation test passes AND a curator dry-run on the edited `.claude/rules/working-knowledge.md` reports 0 changes (byte-identical no-op)

## Checkpoints

- BEFORE any deletion: report (a) the full enumerated list of `Step N`/`Step Nx` cross-references to be swept (both skills + all companions + `.dev-wiki/`/`wiki/`/`active-phase.md`), and (b) the classification of the 2 eval scenarios (what each tests, confirmation it’s removed-machinery). Proceed only if both are clean.
- After the renumber + sweep, BEFORE the hot-cache edit: run `test_step_numbering.sh` + `test_companions.sh`; if either fails, fix the renumber before touching the cache.
- If a deletion would orphan an install-time registration (modules.json/MANIFEST/settings.json) that isn’t in the planned cleanup, or an eval scenario turns out to test a retained component: STOP and report — do not delete.
- If the hot-cache curator dry-run is NOT a no-op after the prune: STOP — the edit violated a curator invariant; revert and re-prune through the curator.

## Assumptions

- At-entry renumber baselines (verified 2026-05-29): dev-plan max heading = **18** (Step 11 = Self-Dialogue removed → max 17); dev-debrief max = **26** (Steps 1-22 + 26 in SKILL.md, 23-25 in `debrief-finalization.md`; Step 7 = Heuristic Capture removed → max 25); eval = 54 scenarios, dynamic count. If these differ at implementation time: re-derive the renumber arithmetic from the actual headings before sweeping.
- The dev-debrief heuristic-capture (Step 7) is removable without cutting a retained debrief capability — Memory Harvest (Step 6) is a SEPARATE retained step. If false (capture and harvest share counter-write code): remove only the heuristic-coupled portion and keep memory-harvest, adjusting the renumber accordingly.
- The 2 eval scenarios test the removed machinery only. If false (either tests a retained component): keep that scenario (eval stays 53/53 or 54/54) and document the retained coverage.
- The renumber is purely mechanical (no step’s semantics change, only its number). If a step’s content must also change: that is out of scope — flag it, renumber only.
- `make test`/`make eval` are green at phase entry (post-Phase-63 baseline 54/54). If not: capture pre-existing failures first and exclude them from the regression gate.
