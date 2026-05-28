---
title: Phase 53 Investigation Findings
created: 2026-05-27
status: active
confidence: high
source: investigation
---

# Phase 53 Investigation Findings

## Investigation 1: MCP Memory Data Loss

**Finding: CWD mismatch + health probe bugs (documented)**

Root cause is three compounding issues: (1) Claude Code ignores `cwd` in settings.json and uses the project directory instead, so project DB is at `<project_root>/.memory/memory.db`, (2) session-start health probe checks wrong path (`~/.claude/memory_server/memory.db`), (3) health probe uses wrong column name (`is_active` vs `active`).

Phase 19-48 entries are irrecoverable. Current 11 entries (Phases 49-53) are stable. See `mcp-memory-diagnosis.md` for full evidence.

**Status: CLOSED — root cause identified, no fix in this phase scope (hook bugs flagged for future phase)**

## Investigation 2: IRON-004 / Scenario 015

**Finding: concern is resolved — no IRON-004 edit needed**

Analysis:
1. IRON-004 trigger ("choosing between two approaches where one is simpler") superficially matches scenario 015 (incremental refactor vs full rewrite). The LLM matcher in production Step 6.5 would select it.
2. However, IRON-004's guidance pushes toward the incremental refactor, which IS the expert answer. The heuristic gives the correct conclusion.
3. The "right answer for wrong reasons" concern: IRON-004 frames the choice as "simpler system wins" rather than the expert's framing (deadline risk, production validation, undocumented edge cases). This is a reasoning quality concern, not a decision quality concern.
4. Ground-truth mapping (Phase 51) correctly maps 015 to `["IRON-005"]` only. IRON-005 ("make failure visible") provides the appropriate framing: incremental approach gives production validation at each step, making failure visible vs. the rewrite's invisible-until-cutover pattern.
5. In `--selective` eval mode, IRON-004 is NOT injected on 015. The system works correctly.

Resolution: The concern was valid pre-Phase 51 (blanket injection era). Selective injection with ground-truth mapping resolves it — the right heuristic (IRON-005) is matched to 015, and IRON-004 is excluded. In production (LLM matcher), IRON-004 would be selected but its guidance aligns with the correct answer, so the impact is limited to reasoning framing, not decision correctness.

No IRON-004 content change needed. No eval runs required — the analysis is sufficient.

**Status: CLOSED — resolved by selective injection (Phase 51), no content change**

## Investigation 3: HEU-011 Capacity-Multiplier Heuristic

HEU-011 drafted with narrow trigger ("prioritizing between multiple competing initiatives where one enables or reduces the cost of the others"). Ground-truth mapping: 1/25 scenarios (020 only) — well within ≤5 cap. Cross-IRON conflict check: no overlap with IRON-001 (different decision domains — performance optimization vs initiative prioritization).

## HEU-011 Eval Results

**Setup:** 1 baseline run (no heuristic) + 1 treatment run (HEU-011 injected) on scenario 020. Sonnet agent, Sonnet judge (v2 exemplar-based). Two-phase methodology (agent blind, separate judge).

**Results:**

| Condition | Decision | Reasoning | Anti-pattern | Correct? |
|-----------|----------|-----------|-------------|----------|
| Baseline (no heuristic) | 5 | 5 | 5 | Yes (B) |
| Treatment (HEU-011) | 5 | 5 | 5 | Yes (B) |

**Analysis:**

Both conditions hit the ceiling (5/5/5). No measurable delta because the clean baseline already solves scenario 020 correctly.

This contradicts the Phase 50 working-knowledge entry ("8/9 choose dependency upgrade"). The discrepancy is explained by condition differences:
- The prior 8/9 wrong finding was from **IRON-RULES-injected conditions** (self-dialogue inline/subagent, Phase 47). The README documents: "020 regressed -3.0 (IRON-005: CVEs over force-multiplier)" and "020 still wrong (-2.56, IRON RULES bias)."
- IRON-005 ("make failure visible") emphasizes CVE risk, biasing the model toward option C (dependency upgrade) over option B (capacity multiplier).
- The **clean baseline** (no IRON RULES) gets 020 right — the model can do capacity-multiplier reasoning without interference.

**Implication:** HEU-011's primary value is as a counterweight to IRON-005 bias in the IRON-RULES-injected condition, not as a standalone improvement over the clean baseline. The full test (baseline+IRON-RULES vs baseline+IRON-RULES+HEU-011) was not run in this phase. HEU-011 remains a valid addition to the heuristic set for scenario 020 coverage, but its eval verification against the IRON-RULES condition is deferred.

**Regression check:** Not applicable — only 1 scenario matches HEU-011 in ground-truth (020). No adjacent scenarios to regress.

**Status: PARTIAL — HEU-011 drafted and mapped, clean-baseline eval at ceiling, IRON-RULES-condition eval deferred**
