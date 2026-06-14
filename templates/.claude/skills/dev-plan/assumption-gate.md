---
parent: dev-plan
referenced_at: "Step 13"
---

# Assumption-Approval Gate (dev-plan Step 13)

The direction gate. Taking positions on the plan's load-bearing assumptions **REPLACES** "approve the
approach?" — the maintainer shifts from rubber-stamping a conclusion they can't evaluate to taking an
explicit position on each assumption the plan rests on. Earned from Phase 80
([[assumption-surfacer-completeness-screen]]): a naive cost-sorted surfacer recovers load-bearing
assumptions by reasoning, so the value is the forced human verdict, not machinery. No unresolved
reject/don't-know = direction confirmed.

## Surfacing (run BEFORE presenting the gate)

Surface the plan's load-bearing assumptions — an assumption is load-bearing if the plan's outcome would
change were it false. From the approach (Step 10) + the spec, produce **3–6** assumptions, one short
sentence each, ranked by **cost-of-error** (worst-if-wrong first). Reason ONLY from the plan; do not invent.

**Assumption, not direction (filter EVERY candidate before it reaches the gate):** A load-bearing
assumption is a belief about something you do NOT control — a domain fact, the maintainer's intent, an
external or infrastructure reality the plan takes on faith and that could be FALSE. It is NOT a restatement
of the approach you chose. **Checkable test:** write "If this is FALSE, then [specific breakage]." If the
negation is incoherent, or the only consequence is *"then I'd have picked a different approach,"* it is a
DIRECTION CHOICE, not an assumption — DROP it. The maintainer's verdict adds value by adjudicating a fact
you LACK (what a `don't-know` marks), not by blessing a decision you MADE — surfacing your own choices as
"assumptions" regresses the gate into the "approve the approach? → blind yes" it exists to replace.

- ✗ Direction (drop): "We should add a `--update` mode." → negation is just "I'd have chosen differently."
- ✓ Assumption (keep): "`--project-local` is the only install path consuming projects use." → if false, the
  fix misses a path the maintainer may know of.

- Step-10 T0's "weakest assumption" MUST appear as one member of this set. If it is absent, the set is
  incomplete — regenerate. (T0 is the same surfacing reflex; this is the SINGLE surfacer, not a second list.)
- Each assumption names what BREAKS if it is false (its cost-of-error). Include the *is-it-actually-so*
  infrastructure assumptions the plan silently relies on — a hook fires, a store persists at the assumed
  path, a file is within budget, a dependency is wired. Those are the silent-class ones nobody asks about.
- **Top-N cap:** surface no more than 6; the maintainer positions the top 5 by cost-of-error. A longer list
  fatigues the verdict into accept-spam. If genuinely fewer than 1 load-bearing assumption exists, see
  *Empty set* below.

## Positions (the gate — AskUserQuestion)

Present the surfaced assumptions and take an explicit position on each via AskUserQuestion:
`accept` / `reject` / `don't-know`. This IS the approval — there is no separate "approve the approach?"
step. The maintainer confirms direction by positioning, not by clicking yes.

**Empty set:** if no load-bearing assumption was surfaced, do NOT silently auto-pass — present "no
load-bearing assumptions surfaced" as an explicit item the maintainer must confirm (a buried assumption is
most dangerous exactly when the agent claims there are none).

## Resolution (before the gate closes)

- **reject** → the maintainer does not believe the assumption holds. Revise the approach so it does not
  depend on the assumption (or establishes it first), update the draft decision article, and RE-SURFACE.
  Max 3 revision rounds; after 3, proceed with the best version and note the unresolved reject in the phase
  article.
- **don't-know** → the maintainer cannot evaluate it — the highest-value position, marking where the human
  needs the agent. The agent must EITHER defend it with evidence (code, docs, a prior decision) and
  re-present, OR down-scope the plan to drop the dependency. If it still cannot be resolved, record a
  *deferred don't-know*: route it to the phase article's `## Blockers and Open Questions` and set its ledger
  `revisit-status: open` (flagged must-revisit at debrief). A don't-know NEVER closes the gate as a silent
  pass.
- **accept** on every assumption → see *All-accept* below.
- No unresolved reject/don't-know remain → **direction confirmed.** Proceed to Step 14.

## All-accept (warn + track + restate — NOT a hard block)

If every position is `accept` (no reject, no don't-know): allowed, but never silent (Jake's Q2 choice;
[[HEU-012]] — the bite is a named effect that always fires, not a wall).

1. **Warn** — state plainly that this is an all-accept, the smell the gate exists to surface.
2. **Track** — the ledger entry records `all_accept: true` (a pattern queryable across phases; routine
   all-accept means the gate has degenerated back to blind-yes).
3. **Restate** — before confirming, restate how EACH accepted assumption shapes the phase approach: what
   the plan now commits to because the maintainer blessed it. This makes the consequence legible.

## Ledger (append the row — the gate's firing evidence)

When positions are taken, APPEND a block for this phase to `.dev-wiki/assumption-ledger.md`. The format and
validator are `scripts/check-assumption-ledger.sh` — its `## Ledger schema` block is the SINGLE source of
truth; do NOT inline a divergent copy here. Append only; never rewrite a prior phase's block. Leave each
`revisit-status:` blank (dev-debrief fills it at close). The row — not this prose — is what the
deterministic check asserts on, so the gate cannot be narrated without actually being taken.

See `assumption-gate-example.md` for a worked mixed-positions case and an all-accept case.

## Enforcement (Phase 91)

This gate is hook-bound, not prose-only: `enforce-assumption-gate.sh` (PreToolUse `Write|Edit|MultiEdit`, mirrors `enforce-spec`) blocks implementation writes whenever the active phase's ledger block is absent or malformed — it runs `check-assumption-ledger.sh --gate <phase>` (the active phase has positions recorded). Whole-file `--schema` is deliberately NOT required — a malformed prior-phase block (format drift in older/consumer ledgers) must not false-block a properly-gated current phase. The Phase-90 fix was prose-only and was skipped a 3rd time; the hook makes the durable ledger block a precondition for implementation. It enforces that the gate FIRED — not reasoning quality (all-accept stays allowed-but-warned).
