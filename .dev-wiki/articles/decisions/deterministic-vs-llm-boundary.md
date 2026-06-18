---
title: "Deterministic vs LLM Boundary in an Agentic Harness"
aliases: [deterministic-vs-llm-boundary, det-vs-llm, harness-boundary-principles]
category: decisions
tags: [architecture, deterministic, llm, principles, harness-design, subtraction]
parents: [phase-92-strategic-inflection-review]
created: 2026-06-18
updated: 2026-06-18
source: plan
confidence: high
---

## Context

The Phase-92 inflection review asked, explicitly: in an agentic pipeline/harness, what should be built
deterministically vs rely on an LLM? The kit already states the posture ("deterministic validators at
boundaries over neural judges at the end"; "measurement before optimization"; the subtraction test). This
article tests how well the kit lives up to it and fixes the boundary as a durable, transferable rule, derived
from measured evidence and corrected by the review's adversarial pass. See [[strategic-inflection-review]].

## Decision

### Principles (transferable to any agentic harness)

1. **LLM only for irreducible semantic synthesis over open content.** Everything mechanical —
   string-compare, set-diff, count, regex, glob, JSON edit, file I/O — belongs in a script. *Caveat the
   review forced:* this gates NEW work and breaks ties; it is NOT a mandate to rewrite working prose-skills.
   A rewrite must clear the subtraction test — what breaks if we leave it? — and a hypothesized-but-unobserved
   failure mode does not clear it.
2. **The final integrity gate is deterministic and asserts the observable artifact, never the LLM's
   narration of having done the work.** Verify by firing a real event and asserting the exit code / log row,
   not by presence. Registered+present+valid ≠ working — 4 silent breakages lasted 8–33 phases proving it.
   (Measured win: the binary eval corpus + the firing-coverage gate. NOT the Ph87 "beat the reviewers" claim,
   which is a binary-file-excluded-from-diff confound.)
3. **Fail-polarity by cost-of-error.** Gates protecting irreversible/load-bearing state fail CLOSED;
   advisory/relevance filters fail OPEN so infra failure never drops good results or blocks legitimate work.
   The polarity is a deterministic safety decision independent of any LLM inside.
4. **When the answer is already in-context (parametric or hot-cache), retrieval/re-presentation is
   redundant-at-best, diluting-at-worst — curate the hot-cache, don't bolt on a retrieval engine.** Measured:
   runtime retrieval into planning added 0/−0.67 lift (Ph61); web-research injection was net-negative (Ph59).

### The kit's map (where the boundary sits today)

- **Correctly deterministic + measured value:** the binary eval corpus, the firing-coverage gate,
  registration/drift invariants, block-dangerous-bash, the memory storage/retrieval core (storage.py — zero
  LLM in the read/write path), wiki-index/search.py (BM25+vector), py-lint/py-test (tool exit codes are the verdict).
- **Correctly LLM (irreducible):** py-review (reuse/idiom/swallowed-exception/API-version judgment over a
  diff), wiki-absorb/wiki-bootstrap synthesis, dev-plan approach reasoning, dev-debrief conversation analysis,
  assumption *surfacing*.
- **Boundary done right — the model to emulate:** the assumption gate — LLM surfaces, a NO-LLM Bash/awk
  validator asserts the ledger row so the gate cannot be narrated without firing; the dev-plan/dev-debrief
  orchestrator (LLM reasoning) + executor (deterministic file I/O) split.
- **Mechanical-dressed-as-LLM (principle says script, but only WHEN NEXT TOUCHED — not a rewrite project):**
  dev-check (9 file-comparison checks), wiki-health (15 structural checks + count dashboard + regex
  staleness), wiki-registry (JSON read/count/atomic-rename); latent sub-steps (dev-plan Step-4 keyword tally,
  dev-debrief Step-1 significance scoring + Step-21 gate-log field audit). Deferred until a real mis-read is
  observed — the failure mode is hypothesized, the skills work, and the review inflated their size ~40%.
- **Weak/gameable deterministic gate:** enforce-memory — a deterministic marker-existence check wrapping an
  UNVERIFIABLE LLM-attested precondition (the agent touches the marker itself; field evidence shows ritual
  compliance). Either make it assert a real in-session MCP memory_search event (Principle 2) or retire it.
  Decided at Phase 95 against the Phase-94 re-measure.

## Consequences

Adopted as a **maintenance guideline**, not a work program. It is the tie-breaker for new skills/hooks
(default mechanical → script; reserve the LLM for irreducible synthesis), the design rule for enforce-memory's
redesign-or-retire (assert the artifact, not the narration), and the standing rationale for *not* rewriting
the working linter-skills until a real defect appears. Every measured positive in the kit's history lives on
the deterministic side of Principles 2–4; the LLM side is justified by irreducibility, not by a measured lift
the kit's own apparatus was never allowed to score (Ph63: LLM eval is calibration-only, never a gate).
