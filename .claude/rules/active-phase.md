# Active Phase Context

Phase: 58 - Active Domain Research in dev-plan (Fix 2)
Status: COMPLETED (5/5 gates; delivery accepted, committed). Next: /dev-plan for Phase 59.
Objective: Add a bounded, gap-gated research step (Step 2.7) to dev-plan that answers the spec's Domain Research Questions from web + local wiki, injects distilled findings into the proposed approach, and persists durable facts to the knowledge wiki. Then measure the RESIDUAL delta vs the Phase-55 baseline (not the headline +1.75).
Result: companion shipped + wired (SKILL.md 326/350); residual delta +0.5 composite n=1 (reasoning 3→4), non-theatrical, kept at Checkpoint 2; 9/9 non-memory suites green, eval 54/54.

Scope: templates/.claude/skills/dev-plan/{domain-research-spec.md, SKILL.md}, eval/research-measurement/, tests/

Key constraints:
- Per-question wiki-query gate (NOT Step 2.5's concept score); covered topics cost zero external calls.
- Bounded + fail-open mandatory: numeric caps degrade to partial; no web/questions/writable-wiki/timeout → skip + marker, never relabel a guess as researched.
- Injection-safe (question = data); ~1200-char cap. Persist via wiki capture path with provenance + contradiction check (no 4th crawler). SKILL.md ≤350.

Exit criteria: companion wired (Lite-skip); SKILL.md ≤350; caps+fail-open+provenance+injection present; measurement records both branches + numeric residual delta; make test + make eval 100%. ALL MET.

Abort: if research never changes the approach (residual delta ~0/negative), STOP at Checkpoint 2, present honestly, let the user decide keep/trim/cut — do not silently ship.
