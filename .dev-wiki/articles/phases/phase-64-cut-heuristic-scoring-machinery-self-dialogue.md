---
title: "Phase 64: Cut heuristic scoring machinery + self-dialogue"
aliases: ["phase-64-cut-heuristic-scoring-machinery-self-dialogue", "phase-64"]
category: phases
tags: [subtraction-test, deadweight, heuristics, self-dialogue, renumber, step-numbering, cognitive-enhancement]
parents: [phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: active
scope: ["templates/.claude/skills/dev-plan/**", "templates/.claude/skills/dev-debrief/**", "templates/.claude/skills/MANIFEST", "scripts/heuristic-dashboard.py", "tests/test_heuristic_evolution.sh", "tests/test_templates.sh", "Makefile", "eval/corpus/**", ".claude/rules/working-knowledge.md", ".dev-wiki/**", "wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 63 complete + committed; spec specs/cut-heuristic-machinery-self-dialogue.md nana:approved 2026-05-29; direction confirmed 2026-05-29 (top item of the Phase-63 remediation roadmap)"
exit_criteria: "All 8 target files absent; no dangling ref to any deleted basename across templates/Makefile/tests/scripts/modules.json; test_step_numbering.sh green (dev-plan + dev-debrief gap-free 1..N) with manual sub-letter spot-check; test_companions.sh + test_registration.sh green; make eval = 52/52 (dynamic count, no literal edit); make test green (suite = prior−1 from removing test_heuristic_evolution); retained articles reference no deleted machinery; hot cache curator-valid (curation test green AND curator dry-run is a byte-identical no-op, no [pinned] removed)"
---

# Phase 64: Cut heuristic scoring machinery + self-dialogue

## Objective

Remove the never-fired Cognitive Enhancement scoring loop (matcher → judge → counter-update → lifecycle → dashboard, Phases 44-52) and the net-neutral self-dialogue planning step from the harness, while KEEPING the 17 `wiki/heuristics/*.md` articles (live test fixtures + the eval/reasoning injection corpus). A coherent subtraction — no orphaned references, tests, counters, or step-number gaps.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/**` — delete 5 companions (`heuristic-matcher`, `heuristic-judge-prompt`, `heuristic-counter-update`, `heuristic-lifecycle`, `self-dialogue-prompt`); edit SKILL.md (remove Step 11 + Step 13 sub-items 6-7); renumber 12-18 → 11-17 incl sub-letters
- `templates/.claude/skills/dev-debrief/**` — delete `heuristic-capture.md`; edit SKILL.md (remove Step 7) + renumber 8-26 → 7-25 incl `debrief-finalization.md`
- `templates/.claude/skills/MANIFEST` — remove deleted-companion md5 + description lines
- `scripts/heuristic-dashboard.py`, `tests/test_heuristic_evolution.sh` — delete
- `tests/test_templates.sh` — remove self-dialogue + machinery assertions; KEEP eval/reasoning + 17-article assertions
- `Makefile` — drop `test_heuristic_evolution` from `test:`; remove `dashboard:` target + `.PHONY` entry
- `eval/corpus/**` — delete `skill-counter-update-companion` + `skill-evolution-lifecycle-companion` (dynamic count → 52/52)
- `.claude/rules/working-knowledge.md` — selectively prune machinery-as-operational entries via the curator
- `.dev-wiki/**`, `wiki/**`, `.claude/rules/active-phase.md` — sweep `Step N`/`Step Nx` cross-references

## Exit Criteria

- [ ] All 8 target files absent (`for f in ...; do test ! -e "$f"; done && echo OK`)
- [ ] No dangling reference to any deleted basename: `! grep -rIn -e heuristic-matcher -e heuristic-judge-prompt -e heuristic-counter-update -e heuristic-lifecycle -e self-dialogue-prompt -e heuristic-capture -e heuristic-dashboard -e test_heuristic_evolution templates/ Makefile tests/ scripts/ modules.json`
- [ ] `bash tests/test_step_numbering.sh` passes (dev-plan AND dev-debrief gap-free 1..N) + manual sub-letter spot-check (16x→15x resolves)
- [ ] No dangling top-level step citation: `! grep -rInE 'Step 18|Step 16[a-z]' templates/.claude/skills/dev-plan/ && ! grep -rInE 'Step 26' templates/.claude/skills/dev-debrief/`
- [ ] `bash tests/test_companions.sh` passes (no dangling Read paths; `referenced_at:` valid)
- [ ] `bash tests/test_registration.sh` passes
- [ ] `make eval` reports `Score: 52/52 (100%)` (total computed dynamically; no count-literal to edit)
- [ ] `make test` passes (suite = prior − 1 from removing test_heuristic_evolution)
- [ ] Retained articles clean: `! grep -rIl -e heuristic-matcher -e heuristic-judge -e heuristic-counter-update -e heuristic-lifecycle -e heuristic-dashboard wiki/heuristics/`
- [ ] Hot cache curator-valid: curation test passes AND a curator dry-run on the edited `working-knowledge.md` reports 0 changes (byte-identical no-op)

## Constraints

- Cut the machinery, keep the knowledge-fixtures — the 17 articles + SCHEMA.md are asserted by `test_templates.sh`/`test_companions.sh` and feed the eval/reasoning experiment; a whole-subsystem delete would destroy live fixtures. ([[cut-heuristic-scoring-keep-articles]])
- Walk UPSTREAM — remove the dev-debrief producer (heuristic-capture counter-write, Step 7) AND the dev-plan consumer (judge dispatch, Step 13 sub-items 6-7); removing only the consumer orphans the producer. ([[cut-heuristic-scoring-keep-articles]])
- `test_step_numbering.sh` validates HEADINGS only and IGNORES sub-lettered/postfixed refs — sweep `13x`/`15x`/`16x`(incl `16f-ter`)/`17x` and inline `Step N` prose MANUALLY; the deterministic test cannot catch them. ([[batch-self-dialogue-with-heuristic-renumber]])
- The eval total is DYNAMIC (eval-runner.sh counts `scenario.json`) — deleting the 2 dirs yields 52/52 with ZERO count-literal edits; do not hunt for or introduce a baseline constant. ([[eval-total-is-dynamic]])
- The hot cache is curator-owned (Phase 62) — hand-edits must satisfy the curator's invariants or it reverts them / trips the whole-file bail; verify with a dogfood no-op. No `[pinned]` entry removed.
- Renumber is purely mechanical — no step's semantics change, only its number. If a step's content must change: out of scope, flag and renumber only.

## Checkpoints

- BEFORE any deletion (T1): report (a) the full enumerated list of `Step N`/`Step Nx` cross-references to be swept (both skills + all companions + `.dev-wiki/`/`wiki/`/`active-phase.md`) and (b) the classification of the 2 eval scenarios (what each tests, confirmation it's removed-machinery). Proceed only if both are clean.
- After the renumber + sweep, BEFORE the hot-cache edit: run `test_step_numbering.sh` + `test_companions.sh`; if either fails, fix the renumber before touching the cache.
- If a deletion would orphan an install-time registration (modules.json / MANIFEST / settings.json) not in the planned cleanup, OR an eval scenario turns out to test a RETAINED component: STOP and report — do not delete.
- If the hot-cache curator dry-run is NOT a no-op after the prune: STOP — the edit violated a curator invariant; revert and re-prune through the curator.

## Assumptions

- At-entry renumber baselines (verified 2026-05-29): dev-plan max heading = 18 (Step 11 self-dialogue removed → max 17); dev-debrief max = 26 (1-22 + 26 in SKILL.md, 23-25 in `debrief-finalization.md`; Step 7 heuristic-capture removed → max 25); eval = 54 scenarios, dynamic count. If these differ at implementation time: re-derive the renumber arithmetic from the actual headings before sweeping.
- dev-debrief heuristic-capture (Step 7) is removable without cutting a retained capability — Memory Harvest (Step 6) is a SEPARATE retained step. If false (capture and harvest share counter-write code): remove only the heuristic-coupled portion, keep memory-harvest, adjust the renumber.
- The 2 eval scenarios test the removed machinery only. If false (either tests a retained component): keep that scenario (eval stays 53/53 or 54/54) and document the retained coverage.
- `make test`/`make eval` are green at phase entry (post-Phase-63 baseline 54/54). If not: capture pre-existing failures and exclude them from the regression gate.

## Notes

This is the top item of the Phase-63 remediation roadmap ([[phase-63-remediation-roadmap]]), batched because self-dialogue and the heuristic-judge sub-items share the dev-plan step-numbering surface (separate phases = wasteful double-renumber). Execution is SERIAL, not a workflow — the double-renumber is mechanical-but-error-prone and can't be safely parallelized; `test_step_numbering.sh` + `test_companions.sh` are the deterministic gates, with a manual sub-letter sweep on top. Self-hosted edit: `templates/` ships via `cp -r` to every project, so a deletion propagates everywhere (blast radius). Authoritative contract: `specs/cut-heuristic-machinery-self-dialogue.md` (nana:approved 2026-05-29, spec-reviewer-verified). Governed by [[cut-heuristic-scoring-keep-articles]], [[batch-self-dialogue-with-heuristic-renumber]], [[eval-total-is-dynamic]].
