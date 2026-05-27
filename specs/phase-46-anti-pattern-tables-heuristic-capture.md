<!-- nana:approved 2026-05-27 -->
# Spec: Anti-Pattern Tables & Heuristic Capture

## Objective

Enrich heuristic articles with structured anti-pattern tables (multiple failure modes per heuristic with detection signals), fix IRON-004's regression on scenario 018, add automatic heuristic capture to dev-debrief, and measure the combined reasoning quality delta.

## Context

Phase 44 built the heuristic store (10 seeds + SCHEMA.md). Phase 45 added 5 IRON RULES and broke the eval ceiling (19.4% below 5 with judge v2). IRON-004 ("simpler system wins") caused a -6 regression on scenario 018 (feature flag cleanup): the agent chose incremental cleanup over a dedicated sprint, misreading "less upfront effort" as "simpler system." The existing heuristic format has a single "Anti-pattern" section per article — this phase expands it to a structured table of multiple failure modes with concrete detection signals. The dev-debrief currently extracts corrections/preferences to memory (memory-harvest, Step 4.7) but does NOT extract transferable reasoning patterns to wiki/heuristics/. This phase adds that capture step to close the heuristic learning loop. Part of the cognitive enhancement roadmap (Phases 44-50).

## Scope

### In scope
- Anti-pattern table format definition in SCHEMA.md (structured table replacing single-paragraph Anti-pattern section)
- Anti-pattern tables for all 5 IRON RULES (IRON-001 through IRON-005)
- IRON-004 text fix: clarify "simplicity = total lifecycle complexity, not upfront effort"
- Heuristic capture companion for dev-debrief (~40-50 lines, companion file route since SKILL.md at 310/350)
- Delta measurement: eval with enriched IRON RULES vs Phase 45 baseline
- Test assertions for new artifacts

### Out of scope
- Anti-pattern tables for seed heuristics (HEU-001 through HEU-010) — defer to future phase, IRON RULES first since they have eval coverage
- Cross-model judging (separate concern from anti-pattern content)
- Heuristic evolution/scoring (Phase 50)
- Changes to judge v2 prompt (same judge for comparable measurements)
- Runtime injection of anti-pattern tables into session-start (future phase)

## Approach

**Part A — Anti-Pattern Table Format + IRON-004 Fix (do first):**

Define the anti-pattern table format in SCHEMA.md as an extension of the existing Anti-pattern section. Each table row: `| Failure Mode | Detection Signal | Why It Fails |`. Detection signals must be concrete observables (file pattern, metric threshold, phrase in rationale) — not vague warnings. Cap at 3-5 rows per heuristic; allow explicit "No observed anti-patterns beyond primary" marker for heuristics without multiple known failure modes.

Fix IRON-004: add a "Never" clause distinguishing "less effort now" from "simpler system." The fix must remain domain-agnostic (pass transferability test). Write anti-pattern tables for all 5 IRON RULES.

Run eval to verify: scenario 018 improves (delta >= +0.5) AND no other scenario regresses (delta >= -0.5).

**Part B — Heuristic Capture in Dev-Debrief:**

Create `heuristic-capture.md` companion (40-70 lines). Insert between Step 4.7 (memory-harvest) and Step 5 (extract decisions) in dev-debrief SKILL.md (2-3 line pointer to companion). The capture flow: scan phase decisions for reasoning patterns → apply transferability gate (same 3/5 criteria from SCHEMA.md) → dedup against existing heuristics (trigger-field keyword overlap: 3+ shared trigger keywords = merge into existing article's anti-pattern table rather than creating new) → propose new heuristic draft → user confirms before writing to wiki/heuristics/.

Skip conditions: quick debrief mode, zero decisions in phase, USER OVERRIDE escape-hatch decisions.

**Part C — Delta Measurement:**

Run full 20-scenario eval (3 runs) with enriched IRON RULES (anti-pattern tables + fixed IRON-004). Report per-scenario delta against Phase 45 `with-iron-rules/results.json`. Store as `eval/reasoning/with-anti-patterns/results.json`.

## Constraints (CRITICAL)

- **IRON-004 fix must not regress other scenarios.** Run full 20-scenario eval (3 runs). Per-scenario tracking: scenario 018 must improve >= 0.5, no other scenario regresses >= -0.5. If any regression, back out the fix and report.
- **Anti-pattern detection signals must be concrete observables.** Each must answer "Could I write a grep/lint/eval check for this?" If not, rewrite. No vague signals like "watch for complexity" — name the specific pattern.
- **IRON-004 must remain domain-agnostic after fix.** Re-run transferability test: does the revised rule still apply to a web app, data pipeline, and CLI tool? If the fix only makes sense for feature-flag scenarios, it is wrong.
- **Same judge v2 prompt for delta measurement.** No judge changes — same prompt, same exemplars, only heuristic content differs. Judge v2 does not reference IRON-004 directly (verified).
- **Heuristic capture must not auto-commit.** New heuristics are proposed to the user, not silently written. The user confirms before any wiki/heuristics/ write.
- **Anti-pattern table format must not break wiki-query.** The existing "## Anti-pattern" H2 header must be preserved (wiki-query parses by section headers). Tables go inside the section, not replacing the header.
- **Dev-debrief SKILL.md stays under 350 lines.** Heuristic capture goes in a companion file with a 2-3 line pointer in SKILL.md.

## Deliverables

1. `wiki/heuristics/SCHEMA.md` — updated with anti-pattern table format definition
2. `wiki/heuristics/IRON-001.md` through `IRON-005.md` — updated with anti-pattern tables (IRON-004 additionally gets revised Never clause)
3. `templates/.claude/skills/dev-debrief/heuristic-capture.md` — capture companion (40-70 lines)
4. `templates/.claude/skills/dev-debrief/SKILL.md` — 2-3 line pointer to heuristic-capture.md (insert between Step 4.7 and Step 5)
5. `eval/reasoning/with-anti-patterns/results.json` — delta measurement results
6. `eval/reasoning/README.md` — updated documentation

## Exit Criteria (machine-checkable)

- [ ] `grep -q 'Failure Mode.*Detection Signal' wiki/heuristics/SCHEMA.md` — anti-pattern table format documented
- [ ] `for f in wiki/heuristics/IRON-*.md; do grep -q '| Failure Mode' "$f" || echo "MISSING: $f"; done | grep -c MISSING | grep -q '^0$'` — all IRON RULES have anti-pattern tables
- [ ] `sed -n '/^## Never/,/^## /p' wiki/heuristics/IRON-004-simpler-system-wins.md | grep -q 'lifecycle complexity\|upfront effort'` — IRON-004 Never clause fix present
- [ ] `test -f templates/.claude/skills/dev-debrief/heuristic-capture.md` — capture companion exists
- [ ] `grep -q 'heuristic.capture' templates/.claude/skills/dev-debrief/SKILL.md` — SKILL.md references companion
- [ ] `[ $(wc -l < templates/.claude/skills/dev-debrief/SKILL.md) -le 350 ]` — SKILL.md under ceiling
- [ ] `test -f eval/reasoning/with-anti-patterns/results.json` — delta measurement exists
- [ ] `python3 -c "import json; old=json.load(open('eval/reasoning/with-iron-rules/results.json')); new=json.load(open('eval/reasoning/with-anti-patterns/results.json')); o18_old=next(s for s in old['runs'][0] if s['scenario_id']=='018-feature-flag-debt'); o18_new=next(s for s in new['runs'][0] if s['scenario_id']=='018-feature-flag-debt'); old_mean=sum(o18_old['scores'].values())/3; new_mean=sum(o18_new['scores'].values())/3; assert new_mean - old_mean >= 0.5, f'018 delta {new_mean-old_mean:.1f} < 0.5'"` — scenario 018 improved >= 0.5
- [ ] `make test` passes
- [ ] `make eval` 100%

## Checkpoints

- After IRON-004 text fix: review the revised Never clause and anti-pattern table before running eval
- After Part A eval run: check per-scenario deltas — if scenario 018 doesn't improve >= 0.5 or any other scenario regresses >= -0.5, STOP and report
- After heuristic-capture.md written: verify dev-debrief SKILL.md stays under 350 lines
- If IRON-004 fix causes unexpected regressions on 2+ scenarios: back out fix, report for manual redesign

## Assumptions

- Anti-pattern tables can be sourced from nana-dev-kit history (43 phases of recorded failures and near-misses). If insufficient: supplement with generic software engineering anti-patterns from domain knowledge.
- The IRON-004 regression is caused by the "Never: Justify complexity with 'we might need it later'" clause being misapplied to upfront-investment scenarios. If the actual cause is different (e.g., the "Always: Default to the simpler approach" clause): the fix target shifts.
- Subagent execution available for eval runs (same as Phases 44-45). If unavailable: document methodology, defer live runs.
- Dev-debrief companion pattern works (cp -r auto-distributes). Verified in Phases 12, 18, 19 — no risk here.
