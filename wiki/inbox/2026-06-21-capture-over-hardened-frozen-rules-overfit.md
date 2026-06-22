---
source_type: session
source_path: conversation
ingested: 2026-06-21T18:40:00
---

# Raw: Over-Hardened Frozen Decision Rules Over-Fit Into Illegibility AND Over-Conservatism

## Context

nana-dev-kit Phase 97 pre-registered a FROZEN decision rule to read a strategic verdict
(DIFFERENTIATED / COMMODITIZED / DIVERGENT / INCONCLUSIVE) mechanically, before gathering
evidence — the anti-retrofit discipline. A multi-agent adversarial pass hardened the rule against
every edge case it could construct (the synthesized draft had a real bug: a residual-default back
door). The fix plugged the holes but accreted machinery: dual counts (K_low/K_high), three named
global guards, a single-vendor cap, an escape valve, an asymmetric adoption rule, a signature table,
and a five-step procedure with FORCED-INCONCLUSIVE-UNDER-OBSERVED states. The maintainer was offered
a simplified 4-threshold version and chose the rigorous one for maximal airtightness against gaming.

## Insight

Adversarial hardening of a frozen/pre-registered decision instrument has TWO failure modes beyond
"unplugged holes," and both bit here:
1. **Illegibility defeats the purpose.** A frozen rule's whole value is that a human can later verify
   the verdict was read straight. A rule too baroque to hold in your head can't be audited by eye —
   so the anti-retrofit guarantee silently evaporates. The rule's own residual-concerns section even
   admitted the judgment latitude didn't disappear, it just relocated into "is this value-capturing?"
   and "is this headline divergent?" — false precision.
2. **Over-fitting toward conservatism.** A zero-tolerance clause ("ANY contest bars the positive
   verdict") fired on a single NON-CORE contested data point and forced INCONCLUSIVE, where the
   substance was decisively positive on every other axis and the simpler rule would have returned the
   clean positive verdict.

Pattern: treat **"a human can verify this read by eye"** as a HARD design constraint for any frozen
instrument — prefer the simplest rule that survives the *real* failure modes over the most
edge-case-complete one. When the maintainer chooses complexity over legibility, RECORD it, because the
cost can realize as a less-honest verdict label. Subtraction test applies to decision rules, not just
systems ([[IRON-004]] simpler-system; the burden-of-proof-on-the-feature posture).

**Counter-context (do NOT over-correct into loosening rigor):** a frozen rule biting AGAINST the
author's evident preference is the anti-retrofit discipline *working* — an ungamed rule returning a
more conservative label than the evidence's center of mass is a feature. The lesson is about
legibility and over-fit, not about softening the freeze.

## Evidence

Worked example (nana-dev-kit Phase 97, 2026-06-21): convergence map K_low=0 (zero commoditized
primitives), core uncommoditized, 12/14 sources THIN, 3 affirmative declarations, OSS corroborating —
all pointing to the positive verdict. A single non-core primitive (B5) was CONTESTED (one lab shipped
a value-capturing version, others hadn't), and the rule's "no contests" clause forced INCONCLUSIVE.
Both resolutions of that lone contest would themselves land the positive verdict. An independent cold
re-derivation confirmed the mechanical read was correct (the rule genuinely barred the positive label)
AND confirmed the verdict.md honored it without retrofitting — so the INCONCLUSIVE is real, but it is
a rigor artifact of one non-core technicality, not a genuine ambiguity. The simplified 4-threshold
rule proposed pre-freeze (kept B1-B5 + value-capture + ship-not-prose + burden-against-bet, dropped
the K_low/K_high/guards/signature-table machinery) would have returned the clean positive verdict on
the identical map. Related: [[IRON-001]] (measure before optimizing — here, legibility before
hardening), the subtraction test, anti-retrofit / pre-registration discipline.
