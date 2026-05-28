---
title: "Phase 53 complete (open questions — IRON-004 scoping, HEU-011, MCP memory)"
aliases: [2026-05-27-phase-53-open-questions-complete]
category: journal
tags: [iron-rules, heuristics, mcp-memory, investigation, heu-011]
parents: [phase-53-open-questions]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 53 complete (open questions — IRON-004 scoping, HEU-011, MCP memory)

## What Happened
- Resolved 3 open questions from the cognitive enhancement roadmap as sequential investigations
- MCP memory diagnosis: root cause is CWD mismatch (Claude Code ignores settings.json cwd) + 2 health probe bugs in memory-nudge.sh (wrong DB path, wrong column name). Phase 19-48 entries irrecoverable, 11 current entries stable
- IRON-004/015 investigation: closed without eval runs. Ground-truth maps 015 to IRON-005 only; selective injection (Phase 51) resolves the concern. IRON-004 would give correct answer anyway (reasoning framing issue, not decision quality)
- HEU-011 capacity-multiplier heuristic drafted (16th article in heuristic set), 1/25 trigger match (scenario 020 only), no cross-IRON conflicts
- HEU-011 eval: clean baseline already solves scenario 020 correctly (5/5/5) — contradicts Phase 50 working-knowledge claim. The "8/9 wrong" was from IRON-RULES-injected conditions, not baseline
- Key insight: HEU-011's real value is as IRON-005 counterweight, not standalone improvement. Full verification needs IRON-RULES-condition comparison (deferred)

## Decisions Made
- [[verification-first-iron004|Verification-First Approach for IRON-004 Investigation]] -- confirmed during implementation (planned, confidence: medium)

## Problems Solved
- MCP memory data loss mystery -- root cause identified: CWD mismatch + health probe bugs since Phase 17
- IRON-004/015 concern -- closed: selective injection resolves, no content change needed
- Scenario 020 baseline characterization -- clean baseline gets it right; prior "model gap" finding was IRON-RULES interference

## Open Questions
- Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs (carried forward)
- session-start.d/memory-nudge.sh has 2 bugs: wrong DB path + wrong column name. Fix in future phase

## Artifacts Changed
- `.dev-wiki/articles/decisions/mcp-memory-diagnosis.md` (new investigation finding)
- `.dev-wiki/articles/decisions/phase-53-investigation-findings.md` (new, covers all 3 investigations)
- `.dev-wiki/articles/decisions/verification-first-iron004.md` (new decision)
- `wiki/heuristics/HEU-011-capacity-multiplier.md` (new, 16th heuristic article)
- `eval/reasoning/selective/ground-truth.json` (updated with HEU-011 mapping)
- `tests/test_heuristic_evolution.sh` (8 -> 11 assertions, +3 for HEU-011 format)

## Related
- [[phase-53-open-questions|Phase 53: Open Questions — IRON-004 Scoping, Meta-Decision Expansion, MCP Memory]] -- parent phase

### Activation Quality
Active-knowledge entries: 4. All 4 entries referenced during investigation work (IRON-004 history, heuristic format/eval methodology, MCP server architecture, verification-first approach). Hit rate: 4/4 (100%).

### Health Delta
- Tests: test_heuristic_evolution.sh 8 -> 11 assertions (+3 HEU-011 format compliance)
- Eval: 52/52 (100%) — unchanged count, HEU-011 compatible

## Soft Observations / Phase N+1 Candidates
- Clean baseline solves scenario 020 correctly — contradicts Phase 50 working-knowledge. Update entry to distinguish baseline vs IRON-RULES performance | Correct working-knowledge entry | Baseline agent run chose B (test reliability) with 5/5/5
- HEU-011's real value is as IRON-RULES counterweight, not standalone improvement | Run baseline+IRON-RULES vs baseline+IRON-RULES+HEU-011 comparison | Both conditions scored 5/5/5 on scenario 020
- MCP memory health probe bugs have existed since Phase 17 (never caught) | Fix memory-nudge.sh path + column name in hooks maintenance phase | session-start.d/memory-nudge.sh checks nonexistent path
