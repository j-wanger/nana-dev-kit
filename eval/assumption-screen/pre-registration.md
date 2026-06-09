# Pre-Registration — Assumption-Surfacer Silent-Class Screen (Phase 80)

Committed BEFORE any scoring run. The verdict RULE, the silence label, the bar-derivation, and the named
limits below are FROZEN; the `.prereg-commit` sha must be an ancestor of the verdict commit (T6 re-checks).
Anti-retrofit guard, per the amplifier-screen lineage (anchor-screen `be96783`, retention `896e096`).

## Question
On the project's REAL silent failures, does the scope-anchored + framing **surfacer** recover the buried
load-bearing assumption that the STRONG **naive baseline** (a one-line clean-context "list this plan's
load-bearing assumptions, cost-sorted" prompt — the spike's prompt, which already aced the TRACED class)
**misses**? I.e., does the machinery earn its complexity exactly where A2's blind-yes lives — on
assumptions that stay wrong, unnoticed, while everyone says yes?

## Silence label (R5, frozen)
A case qualifies as SILENT-load-bearing iff: (a) load-bearing (R1–R4 of `spike/circularity-predicate.md`)
AND (b) the gap between the phase where the assumption BECAME false and the phase where it was CAUGHT spans
≥2 phases, read from the record (outcome-determined, not author judgment). Pre-registered real cases:
- **MCP-CWD** — "MCP memory persists at the configured path." False from Ph4; entries irrecoverable
  Ph19–48; caught ~Ph38–49. Maps to scope (MCP/settings/path config).
- **LINE-CAP** — "session-start.sh is within its budget." 70 lines @Ph22 → 137 by Ph54, no test caught it.
  Maps to scope (session-start.sh / a size test).
- **CASCADE** — "the enforcement hook is actually installed and firing." Silently disabled; explicitly the
  THIRD instance of the class (pre-compact Ph15–23, MCP-CWD Ph4–38, nana-init Ph43–55). Maps to scope (hooks/install).

If <3 real cases survive reconstruction, synthetic fallbacks are added, each CALIBRATED to a real case's
burial pattern (never invented from scratch); any synthetic case is tagged `synthetic:` in the fixture.

## Conditions (n=5 each, per case)
- **NAIVE** — the strong one-line baseline prompt (frozen text in `surfacer.md`).
- **SURFACER** — scope-anchored (≥1 assumption per cost-sorted high-cost scope item; cost-sort an explicit
  logged judgment) + framing pass. Frozen in `surfacer.md`.
Both run clean-context on the SAME reconstructed plan-as-of-then per case. ON ≠ a strawman: NAIVE is the
prompt that already beat the traced class.

## Scoring (deterministic, NO LLM in the scoring path)
Per run, "recovered the buried assumption" = the run's output contains the buried assumption's pre-registered
DISTINCT ENTITIES (entity-presence, not phrasing) — a `require` clause in `checks/<case>.check`; a phantom
distractor is a `forbid` clause. `check.sh` (cloned from `../amplifier/anchor-screen/check.sh`) classifies
each run PASS/FAIL and aggregates per cell.

**Bar derivation (not inherited).** Per-run recovery is Bernoulli ("are the distinct entities present?").
n=5 with a ≥4/5 consensus gives a stable per-CELL (case×condition) recovery classification; a 3/5–2/5 split
marks that cell `UNSTABLE`. This 4/5 is re-derived from the Bernoulli per-run quantity here (it is NOT
imported as authoritative from the anchor-screen, whose per-run quantity differed). The comparison metric is
the per-case DELTA: SURFACER-recovers ∧ NAIVE-misses.

## Verdict vocabulary (frozen) — `^PROGRAM-VERDICT:` aggregates per-case classifications
Per case: `SURFACER>NAIVE` (surfacer ≥4/5 recovers ∧ naive ≤1/5) | `BOTH-CATCH` (both ≥4/5) | `BOTH-MISS`
(both ≤1/5) | `UNSTABLE`. Aggregate over the ≥3 cases:
- **HAS-HEADROOM** — ≥2 cases `SURFACER>NAIVE`, 0 contradicting → the machinery earns its keep where A2
  lives → Phase 81 BUILDS the scope-anchored+framing surfacer.
- **DEGENERATE** — ≥2 cases `BOTH-CATCH` → the naive prompt already reaches the silent class → ship the
  NAIVE surfacer, CUT the machinery (subtraction). The spike's preview extended to the silent class.
- **BLIND** — ≥2 cases `BOTH-MISS` → no surfacer-prompt reaches the silent class → Phase 81 ships the naive
  surfacer and leans on the A3 ledger (detect-after), NOT pre-validation; the elaborate machinery is not built.
- **INSTRUMENT-DEAD** — a control fails (see below) → screen invalid, no build/cut conclusion.
- **UNSTABLE** — no ≥2 consensus in any direction → inconclusive; never votes toward a build/cut decision.

## Controls (a violation ⇒ INSTRUMENT-DEAD)
1. **Negative / no-fabrication** — a fully-DETERMINED plan (no load-bearing assumption) must yield NO
   recovered assumption from either condition (`forbid` the phantom). If either fabricates, scoring is noise.
2. **Cost-sort adversarial** — one case plants the buried assumption on a deliberately UNDER-RATED-cost
   scope item. If SURFACER recovers it, completeness-by-construction survives the burial-relocates-to-the-cost-sort
   attack; if SURFACER buries it via the cost-sort, that is reported (the most valuable possible finding) and
   the scope track cannot claim completeness.
3. **Reconstruction-neutrality** — each plan-as-of-then is reconstructed from the real historical artifact,
   NOT freshly authored to telegraph or over-bury (the spike's framing-confound lesson). A `forbid` clause
   bans the buried assumption's distinct entities from appearing in the reconstructed PLAN text itself
   (else the plan leaks the answer). Violation ⇒ that case INSTRUMENT-DEAD.

## Named limits (frozen, necessary-not-sufficient)
- R5 captures only silent failures that were EVENTUALLY caught (left a fix commit). Assumptions still
  silently wrong today leave no label — unmeasurable by any method here; the A3 ledger is the only
  detect-after backstop for them.
- n=3–5 real cases is a screen, not a power study. `surfacer ≈ naive` on the silent class (DEGENERATE/BLIND)
  is a legitimate outcome and, combined with the spike, would mean the elaborate surfacer is NOT built —
  the 5th amplifier-null. This is stated up front so a null cannot be reframed as failure.
- Reconstruction is the dominant validity risk; control 3 bounds it but cannot eliminate author influence
  over what counts as "the plan as of then."
