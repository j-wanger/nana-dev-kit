<!-- nana:approved 2026-05-27 -->
# Spec: Heuristic Evolution — Counter Scoring, Deprecation Lifecycle, Dashboard

## Objective

Build the heuristic evolution feedback loop: judge verdicts from Step 6.5 flow back to update helpful/harmful counters on matched heuristic articles, trigger deprecation lifecycle transitions, and power an analysis dashboard. Final phase (7/7) of the cognitive enhancement roadmap.

## Context

Phase 51 built the trigger matcher (`heuristic-matcher.md`) and fire-and-forget judge (`heuristic-judge-prompt.md`). During dev-plan Step 6.5, the matcher selects up to 3 relevant heuristics, and the judge evaluates the approach against them, producing a single Score N/10 with Verdict (accept/revise/reject) and per-dimension scores. All 15 heuristic articles (10 HEU + 5 IRON) have `helpful: 0` and `harmful: 0` counters in YAML frontmatter — structural placeholders that have never been updated. The `status` enum is `active | deprecated | under-review | iron` (defined in SCHEMA.md, Phase 45). The cognitive enhancement roadmap Phase 7 specifies "heuristic evolution (helpful/harmful scoring, deprecation)."

Key prior results that constrain the design:
- Phase 47: Fire-and-forget is mandatory — judge output must not re-enter planning context
- Phase 48: Per-rule selection is not viable (stochastic interference) — counters must not influence matcher selection
- Phase 51: Judge produces a single global verdict, not per-heuristic attribution

## Scope

### In scope
- Counter update companion file for Step 6.5 post-judge orchestrator
- SKILL.md Step 6.5 integration pointer (~3 lines)
- Deprecation lifecycle companion with threshold-based status transitions
- Analysis dashboard script reading all heuristic articles
- Tests for counter update logic and lifecycle transitions
- Eval scenarios for counter update correctness
- Cognitive enhancement roadmap update (mark Phase 7 done)

### Out of scope
- Modifying the judge prompt to produce per-heuristic scores (future phase if attribution precision needed)
- Modifying the trigger matcher to use counter data for selection (counters are retrospective only)
- Automatic heuristic creation from runtime findings
- Implementation-time judging (judge only fires during planning, not task execution)
- Recovery from deprecated status (manual user action only; no auto-recovery)
- New heuristic article seeding (domain-gap coverage is a separate initiative)

## Approach

Three deliverable groups, built sequentially:

1. **Counter update companion** (`heuristic-counter-update.md`, ~30-40 lines): After the judge subagent returns in Step 6.5, the orchestrator reads each matched heuristic article and updates its YAML frontmatter counters. Attribution rule: the single global verdict applies uniformly to all matched heuristics (known limitation — per-heuristic attribution would require judge prompt changes).
   - `helpful += 1` per matched heuristic when heuristic judge global score (N/10 scale) ≥ 6
   - `harmful += 1` per matched heuristic when heuristic judge global score (N/10) ≤ 4 AND approach reviewer global score (N/10) ≥ 6 (the heuristic flagged an approach the reviewer accepted — the heuristic's guidance conflicted with a good approach)
   - No update when heuristic judge global score = 5, or when both judge and reviewer reject (both global scores < 6)
   
   Counter updates are Claude-executed Edit operations following the companion .md protocol — the orchestrator reads the heuristic article, parses YAML frontmatter, increments the counter field via Edit tool, and writes back. No external script execution.

2. **Deprecation lifecycle companion** (`heuristic-lifecycle.md`, ~25-30 lines): After counter update, evaluate each updated heuristic for status transition. Transition `active → under-review` when: `harmful / (helpful + harmful) > 0.3` AND `helpful + harmful >= 5`. IRON rules (status: iron) accumulate counters for observability but never transition — status is immutable. `deprecated` is a terminal state (manual user recovery only via editing YAML). Dashboard flags `under-review` heuristics.

3. **Dashboard script** (`scripts/heuristic-dashboard.py`, ~60-80 lines): Reads all heuristic articles from `wiki/heuristics/`, parses YAML frontmatter, computes per-heuristic stats (helpful, harmful, total, harm ratio, status). Output: sorted table with health indicators. Handles zero-counter state (all articles currently at 0/0 — displays "unscored" not "healthy"). Surfaces "never-matched" heuristics (0 total invocations) as a separate staleness category. Keys on `id:` field, not file paths. `make dashboard` target.

## Constraints (CRITICAL)

- Counters are retrospective analytics, NOT selection signals. The trigger matcher (heuristic-matcher.md) must NOT read or use helpful/harmful counters for heuristic selection. If counters ever influence selection, it requires a dedicated design change with its own eval. Prevents: feedback loop where judge verdicts shape future heuristic selection, violating fire-and-forget isolation (Phase 47).
- IRON rules (status: iron) are immune to deprecation lifecycle transitions. Counters accumulate for observability only. The `iron` status is a terminal state — no harm ratio triggers status change. Dashboard flags IRON rules with harm ratio > 0.3 for manual review (same threshold, different response: flag instead of transition). Prevents: high-variance judge eroding unconditional rules.
- Global verdict attribution: the single judge verdict applies uniformly to all matched heuristics (up to 3). This is a known approximation — a future phase could add per-heuristic scoring to the judge prompt. Prevents: scope creep into judge prompt modification.
- Minimum sample size: deprecation threshold evaluation requires `helpful + harmful >= 5`. Heuristics below this threshold are "unscored," not "healthy" or "at risk." Prevents: premature deprecation from small sample noise (1 harmful / 1 total = 50% harm ratio).
- Counter writes happen in the orchestrator only (after subagent returns), never in the subagent. Single-writer serialization — no race condition on YAML frontmatter. Prevents: concurrent read-modify-write data loss.
- SKILL.md budget: current 316/350 lines. Counter update integration must use companion file with ≤3-line pointer. If pointer pushes past 350: extract Step 6.1 (contradiction check) to companion first.

## Deliverables

1. `templates/.claude/skills/dev-plan/heuristic-counter-update.md` — counter update protocol (~30-40 lines)
2. `templates/.claude/skills/dev-plan/heuristic-lifecycle.md` — deprecation lifecycle protocol (~25-30 lines)
3. Modified `templates/.claude/skills/dev-plan/SKILL.md` — Step 6.5 counter update + lifecycle pointer (~3 lines)
4. `scripts/heuristic-dashboard.py` — per-heuristic evolution analysis (~60-80 lines)
5. Updated `Makefile` — `dashboard` target
6. `tests/test_heuristic_evolution.sh` — counter update, lifecycle, and dashboard tests (~8-10 assertions)
7. Updated eval scenarios in `eval/corpus/` — counter update correctness
8. Updated `wiki/heuristics/SCHEMA.md` — document counter semantics and lifecycle transitions
9. Updated `.dev-wiki/articles/roadmap-cognitive-enhancement.md` — mark Phase 7 done

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-counter-update.md`
- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-lifecycle.md`
- [ ] `grep -q 'heuristic-counter-update\|counter.update' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `test -f scripts/heuristic-dashboard.py && python3 scripts/heuristic-dashboard.py --help 2>&1 | grep -qi 'heuristic\|dashboard'`
- [ ] `grep -q '^dashboard' Makefile`
- [ ] `bash tests/test_heuristic_evolution.sh` (must test: helpful increment on score≥6, harmful increment on score≤4+reviewer≥6, no-update on score=5, iron status immune to lifecycle transition, under-review threshold at 2/5 ratio, no transition at 1/4 ratio, dashboard zero-counter handling, dashboard output keyed by id)
- [ ] `grep -qi 'lifecycle\|deprecat' wiki/heuristics/SCHEMA.md`
- [ ] `grep -q '\*\*DONE\*\*' .dev-wiki/articles/roadmap-cognitive-enhancement.md && grep -q 'Phase 52' .dev-wiki/articles/roadmap-cognitive-enhancement.md`
- [ ] `make test && make eval`

## Checkpoints

- After counter companion written: create a temporary heuristic file with known counters, run counter update logic with a mock verdict, verify YAML round-trips correctly (counters increment, other fields preserved). If YAML parsing breaks frontmatter structure, switch to sidecar JSON approach.
- After lifecycle companion: test threshold logic with synthetic counter values — verify active→under-review transition fires at 2/5 harmful ratio, does NOT fire at 1/4, does NOT fire for iron status.
- After dashboard: verify output covers all 15 heuristics, handles zero-counter state without divide-by-zero, and keys on `id:` not file path.

## Assumptions

- YAML frontmatter can be reliably read-modify-written by the orchestrator (Claude Code Read + Edit tools). The orchestrator parses the `---` delimited frontmatter, modifies the counter field, and writes back. If false: use a sidecar JSON file (`wiki/heuristics/.counters.json`) indexed by heuristic ID instead.
- The single-verdict judge output is sufficient for counter attribution (all matched heuristics get the same update). If false: judge prompt modification needed in a follow-up phase — this phase documents the attribution limitation and proceeds with uniform attribution.
- SKILL.md has room for ~3 lines at Step 6.5. Current: 316/350. If false: extract Step 6.1 (contradiction check, ~15 lines) to a companion file first, freeing space.
- Dashboard runs locally against wiki/ — it does not need network access or external dependencies beyond Python 3 stdlib. YAML frontmatter parsing uses regex extraction of `---` delimited block + key: value line parsing (not PyYAML). If regex parsing fails on multiline values or special characters in any heuristic article: add PyYAML as optional dependency with `try: import yaml` fallback to regex.
