# Fable-5 vs Opus-4-8 — Distilled Contrast (Phase 90)

Source: contrastive read of paired session transcripts in `~/.claude/projects/*` —
signal-watch (fable Phases ~39-41 vs opus 15-19) and nana-dev-kit (fable Phases 83-89 vs
opus 80-82). Model attribution from the transcripts' `"model"` field. External reference:
github.com/sgup/ai `Fable5.md` (a portable operating profile reverse-engineered from
fable-5 behavior), which independently converges on the codifiable set below.

## The governing finding

Opus already **complies with the T0 protocol and assumption gate in form but not
substance** — it dutifully writes a "weakest assumption" section, but generically
("a banner-only assertion confirms the implementation") where fable mechanized it
("timestamp cross-reference vs session transcripts / memory.db writes"). So adding *more
prose of the same kind* is the kit's own measured failure mode (Ph46 context-dilution,
Ph47 IRON-rules overcorrection). The lever is not more instruction; it is **context
shaping** (the soul's own highest-leverage principle) + a few *checkable* forcing-functions.

## Split: codifiable vs model-intrinsic

### CODIFIABLE (recoverable as a checkable instruction) → shipped in Track A
1. **Name the one claim you'd most expect to be wrong** on irreversible/unverifiable work.
   (sgup item 12; this kit's Ph80/81 built it *structurally* and concluded ship-the-simplest.)
2. **Confirmed-vs-inferred legible from prose alone** (sgup item 1; sharper than "cite sources").
3. **Name what still speaks the old contract** before calling a change safe (sgup item 8).
4. **No-regressions needs a captured baseline to diff** (sgup item 4).
5. **Match effort to blast radius** — subtraction test applied to process ceremony (sgup item 7).

Absence diff vs the prior soul: #1 folded into the existing uncertainty line; #2,#4 net-new;
#3,#5 sharpened existing lines (adjacent-domains, cost-of-error). Net +2 lines, 3 sharpenings.

### MODEL-INTRINSIC (a .md cannot recover) — but partially addressable by SYSTEM DESIGN
- **I1 Reframe handling.** Fable *pauses-and-validates* a reframe ("He's applying the
  subtraction test… that's exactly 'deterministic validators at boundaries over neural
  judges'"); opus comply-executes ("Approved. Dispatching the artifact writer").
  → Design fix (Track B1, **shipped**): a forced reframe-absorption beat in dev-plan Step 10
    that gates forward progress on restate-in-project-vocabulary + name-what-it-invalidates
    + check-against-loaded-constraints.
- **I3 Alternative-framing DEPTH.** Fable does question-invalidation ("the ceremony's cost
  has never been baselined, so the lift question isn't even well-posed"); opus reframes
  *laterally* (root-cause substitution) because its T0 alternative-framing is self-generated
  while holding the frame.
  → Design fix (Track B2, **staged/pilot-gated**): generate the framing from a clean-context
    subagent that never sees the proposed approach, so it structurally can't validate-within-
    frame. Gated because Ph80 (in-kit leak) + Ph47 (self-dialogue negative) are prior
    negatives; pilots in a consuming project (see `pilot-protocol.md`).
- **I2 Mid-phase reveal-banking.** Fable banks load-bearing reveals while fresh.
  → **Deferred, not built.** Its destination (memory) is amplifier-null (`uses:1`) and is the
    target of the Phase-91 prune. Building machinery to feed a layer about to be cut fails the
    subtraction test. Re-open against the dev-wiki journal if it earns it later.
- **Terse-mechanical temperament.** Not recoverable by anything; not worth chasing. The one
  adjacent codifiable piece (delta-format reporting) is left as a deferred kit-rules nicety.

## Honest ceiling

We cannot make opus *be* fable — the biggest gaps are model-level reasoning depth/temperament.
The bet of this phase is bounded: the 5 checkable lines are genuinely absent and (being
checkable) executable rather than rubber-stampable; the two design fixes move the reasoning
into a context configuration where the behavior is produced, not performed. This ships on
judgment — interaction quality is unmeasurable in-kit (Ph59 reasoning-eval, Ph80
can't-measure-clean-context-in-kit). The B2 pilot is the one place we get a real measurement.
