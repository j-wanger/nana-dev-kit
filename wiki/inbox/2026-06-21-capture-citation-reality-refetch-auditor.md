---
source_type: session
source_path: conversation
ingested: 2026-06-21T18:42:00
---

# Raw: A Dedicated Citation-Reality Re-Fetch Auditor Earns Its Keep in Any Research Sweep

## Context

nana-dev-kit Phase 97 ran a multi-source frontier sweep: ~14 agents fetched live lab documentation
and classified each source against a frozen rubric, with every classification required to cite a
verbatim quote from the fetched page. A separate adversarial verification phase ran four auditors,
one of which (citation-reality) had the single job of RE-FETCHING cited URLs and confirming the
quoted strings actually appear on the page.

## Insight

Agents that fetch-and-classify external sources will sometimes **hallucinate a verbatim quote even
while reaching the correct classification** — the conclusion is right, the evidence string is
fabricated. This is invisible to a reviewer who trusts the quote, and in a pipeline where a downstream
verdict is read mechanically off the classifications, a fabricated load-bearing citation corrupts the
audit trail (and could corrupt the verdict if the wrong classification rode on it).

Two-part defense for any deep-research / multi-source sweep:
1. **Retrieval-integrity rule at fetch time:** agents MUST fetch live, quote verbatim, and mark a
   source UNREACHABLE rather than fill it in from training/memory. State this explicitly — models
   default to "helpfully" reconstructing.
2. **A dedicated citation-reality auditor:** a verification pass whose ONLY job is to re-fetch the
   highest-stakes citations (every load-bearing FOR/AGINST, every UNREACHABLE) and confirm the quoted
   string is actually on the page. Diversity-of-lens matters — pair it with separate value/logic
   auditors; redundancy of identical reviewers would miss this.

This is the research-workflow instance of verify-by-re-fetch / orchestrator-only-evidence: a clean
classification is not evidence until its citation is independently re-confirmed against the source.

## Evidence

Worked example (nana-dev-kit Phase 97, 2026-06-21): an agent classifying a lab's safety docs reached
the correct conclusion (the primitive is NOT value-capturing) but presented a SYNTHESIZED verbatim
quote that did not exist on the page. The citation-reality auditor re-fetched the URL twice, found the
string absent, flagged it (severity medium), and replaced it with on-page text supporting the SAME
conclusion — so the classification held, only the citation was unsound, and it was fixed before
reaching the verdict. The same audit pass also caught a mis-attributed quote (right text, wrong page)
and a paraphrase-presented-as-quote. Cost: a handful of re-fetch calls. Generalizes to any agentic
research/RAG/sweep harness. Related: [[HEU-012]] (verify firing/reality, not presence/claim),
[[qa-verification-sweep]] orchestrator-only-evidence standard, controls-first verification.
