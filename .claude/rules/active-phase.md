# Active Phase Context

Phase: 78 — Skill-Crystallization Headroom Screen
Status: ACTIVE — planned 2026-06-04, implementation pending. 4 tasks (M/S/L/S). Direction approved.

Objective: Measure whether crystallizing a phase's TOOLING into a reusable skill adds value over
bare re-derivation — i.e. whether a candidate tooling artifact embeds NON-RECOVERABLE correctness a
bare model fails to reproduce even given the RECOVERABLE CORPUS a non-crystallized consuming project
would have (interface + call sites + task), but not the implementation or its tests. Successor to the
decision-retention line (Ph70/71/77, all null); tests the capability/correctness boundary instead.
Cheap go/no-go SCREEN before building any capability→skill module (Phase 79+). Honest prior: SPLIT
(general tooling DEGENERATE, domain tooling HAS-HEADROOM — the split is the finding).

Scope (repo-only, frozen on completion; NOT wired into install.sh/Makefile/make test/make eval):
- `eval/amplifier/skill-screen/**` (sibling to anchor-screen/retention-screen/xsession-screen/)
- `specs/phase-78-skill-crystallization-headroom-screen.md` (nana:approved)
- `.dev-wiki/articles/{decisions,phases,journal}/**`
- READ-ONLY subjects: `scripts/check-install-drift.sh` (+tests) and a real edge-screener domain
  artifact (PIT survivorship membership +tests), copied as frozen fixtures; byte-identical pre/post.

Key constraints (design hardened by adversarial review 2026-06-04 — C1–C4/M1–M5):
- NO LLM in the scoring path; `check.sh` runs pinned tests, n=5/threshold=4 cloned from anchor-screen.
- OFF gets the RECOVERABLE CORPUS R_A (interface+docstring+callsites+task), NEVER the impl or tests (C2).
- `.offleak` leak guard: R_A must contain none of the spec-implied tests' answer-tokens/fixtures (C4/M5).
- spec-implied = ENTAILED-by-R_A with a QUOTED entailing sentence per test; un-citable → unstated-by-rule (C3).
- candidate correctness must be LOCATED+QUOTED from T_A, not asserted in prose (C1: the drift script has NO
  /var canonical-path fix — that was Ph76 session-start.sh; its real correctness is the exclusion allow-list).
- 4 controls gate it: negative(pass)/positive-unknowable(fail)/recoverable-fully-specified(pass)/.offleak;
  any violation ⇒ INSTRUMENT-DEAD (M3).
- pre-registration committed BEFORE runs, ancestor-guarded; apparatus repo-only.

Verdict: `^PROGRAM-VERDICT: (TERMINATE|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)`.
all real candidates DEGENERATE → TERMINATE (don't build); ≥1 HAS-HEADROOM → build (scoped, + router reframe:
skill vs regression-test/lint vessel); control violated → INSTRUMENT-DEAD; <2 measurable → INCONCLUSIVE.

Decision: [[skill-crystallization-headroom-screen]] (high). Spec: nana:approved 2026-06-04.
Abort rule: if blocked >3 attempts, mark [blocked] + ask user skip/abort.

Gates:
- [x] Direction confirmed by user (approach approved 2026-06-04 — "plan Phase 78 as that screen")
- [ ] Delivery accepted (post-implementation report)
