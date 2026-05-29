---
title: "Phase 63 complete — Harness Assessment & Eval-Validity (instrument MIXED; 2 latent bugs fixed; deadweight quarantined)"
aliases: ["2026-05-29-phase-63-harness-assessment-eval-validity-complete"]
category: journal
tags: [phase-63, harness-assessment, eval-validity, instrument-sensitivity, deadweight, multi-agent-workflow, complete]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: debrief
---

Stepped back from feature-level micro-optimization to assess the whole harness from four angles (utilization / coherence / eval-validity-spine / agentic-help) via a **multi-agent workflow** (18 agents: one assessor per angle → adversarial verification of every cut proposal → synthesis), then executed the evidence-confirmed slam-dunks in-phase and left a `decidable-when:`-disciplined roadmap.

**The eval verdict (the question that motivated the phase): `instrument: MIXED`** — and the maintainer's distrust was correct, now proven not asserted. The deterministic 54-scenario binary corpus is SENSITIVE (live probe: disabling the `rm -rf` guard flipped a scenario 54→53; byte-identical revert restored 54/54). The two LLM-judge evals (A/B/C comparison + 25-scenario reasoning) are BLIND-by-construction at the n they were run: the Phase 58/59/61 net-zero deltas (0.00, −0.40, −0.67) all sit strictly inside their own measured spread (0.79–2.0); a true +0.5 and a worthless feature produce the same observable. **Crucial nuance forced by adversarial verification:** those CUTs were still correct *decisions* — they rode a signal the instrument CAN resolve (P59's poor-topic −1.0 > spread + a pre-registered VETO + burden-of-proof), NOT the blind rich-topic zeros. So distrust of (a)/(b) as feature-gates is right; the binary corpus earns trust as a contract-gate. Proposed (propose-not-build) replacement: a dogfood real-workflow eval keyed on *did-a-component-fire-and-change-an-action* off `enforcement.log`/git-cadence/`detect-loop` — no LLM judge in the scoring path.

**Two latent bugs in recently-shipped work, found by the audit:**
1. **session-start.d cp-gap** — py-init/ts-init copied hooks non-recursively (`cp hooks/*.sh`), omitting the `session-start.d/` subdir, so a scaffolded `session-start.sh` aborted at its `source` line under `set -euo pipefail` (verified exit=1). Net: the Phase-62 deterministic curator **had never actually fired on a fresh scaffold.** Fixed `cp -r ...session-start.d` in 4 files + a `test_templates.sh` regression guard (+4 assertions).
2. **wiki-query flip-flop** — wiki-query hand-sorted/evicted `working-knowledge.md` (SKILL.md:160,197-198), contradicting Phase-62's insertion-order curator; order flip-flopped every session (Phase-62's grep exit-criterion missed it — different prose). Now increments+appends only, defers ordering/cap/dedup to the curator.

**Other actions:** `/dev-context` phantom fixed across all actionable/router/description surfaces (it shipped "Run /dev-context" — a nonexistent command — into every project); `wiki-consolidate` quarantined (consumes a `wiki/episodic/` tier nothing produces, router-orphaned) — dir moved out of the install path + modules.json + MANIFEST + nana/SKILL.md + README cleaned. New `scripts/harness-audit.sh` re-runnable classifier: `USED=47 LATENT=31 UNCERTAIN=5 DEADWEIGHT=4`, `INVENTORY=87 CLASSIFIED=87 MATCH=ok`, DRIFT=none (would now catch the session-start.d class deterministically).

**The adversarial layer earned its keep:** every initial cut was demoted from naive-delete to coordinated FIX-WIRING/QUARANTINE because verification found test-fixture coupling, build-breakage, or unique content — including the headline lead (17 HEU+IRON heuristics at helpful:0/harmful:0, never fired across 13 phases): the SCORING machinery is genuine ceremony, but the articles are live test fixtures + feed the eval/reasoning experiment, so the cut is coupled → roadmap, not a quick delete.

**Deferred (10-item `decidable-when:` roadmap, [[phase-63-remediation-roadmap]]):** heuristic-machinery cut + self-dialogue removal BATCHED (shared dev-plan Steps 11/13 renumber surface — avoids a wasteful double-renumber); build the real-agentic eval; retire the confounded comparison arm; session-start.d global-drift fix (author's stale ~/.claude hook); audit-log wire-or-cut; long-cadence firing tests; others.

**Verification:** `make test` fully green (incl. the new guard) · `make eval` 54/54 · `test_registration` 41/41 · referential integrity clean · reviewer: ships safely, no HIGH/MEDIUM (2 LOW loose-ends fixed inline). 4/4 tasks ✓. Governed by [[harness-self-assessment-multi-angle]], [[eval-validity-instrument-sensitivity-probe]], [[eval-validity-verdict]], [[deadweight-requires-affirmative-evidence]], [[cuts-are-frozen-batched-migrations]], [[roadmap-decidable-when]]. **Delivered + accepted.**
