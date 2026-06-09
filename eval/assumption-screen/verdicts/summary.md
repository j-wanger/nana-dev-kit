# Per-cell + per-case results (Phase 80 T5)

## Cells (check.sh --cell, n=5, ≥4/5 consensus; entity-presence, NO LLM)
| fixture | NAIVE | SURFACER | naive leak | surfacer leak |
|---|---|---|---|---|
| mcp-cwd | RECOVERED 5/5 | RECOVERED 5/5 | 0/5 | **4/5** |
| line-cap | MISSED 0/5 | RECOVERED 5/5 | 0/5 | **5/5** |
| cascade | RECOVERED 4/5 | RECOVERED 5/5 | 1/5 | **5/5** |
| costsort-adversarial | RECOVERED 5/5 | RECOVERED 5/5 | 0/5 | 0/5 |
| negative (forbid) | clean 5/5 | clean 5/5 | 0/5 | 0/5 |

"leak" = runs citing nana-dev-kit project-specific facts (Phase numbers, working-knowledge specifics,
`is_active`, amplifier, `[nana:…]`, memory-nudge.sh, cascade-failure) that a clean-context agent in a
CONSUMING project could not know.

## Naive per-case classification (BEFORE accounting for the leak)
mcp-cwd BOTH-CATCH · line-cap SURFACER>NAIVE · cascade BOTH-CATCH · costsort BOTH-CATCH.
By the frozen rule that would read DEGENERATE (≥2 BOTH-CATCH; only 1 SURFACER>NAIVE).

## Why that reading is INVALID — the clean-context control failed for SURFACER
The three REAL silent cases are the project's own documented failures; their buried assumptions are
written verbatim in always-loaded `working-knowledge.md` (e.g. "session-start.sh line cap 70→137, Phase
22"; "Claude Code ignores settings.json cwd → DB at <project_root>/.memory"; the cascade hook-firing
class). The workflow subagents ran INSIDE nana-dev-kit, so they inherited that context. The SURFACER
prompt ("enumerate infrastructure, is-it-actually-so, hooks/installers/config paths/budgets") TRIGGERED
retrieval of those documented answers — leaking 4/5, 5/5, 5/5 on exactly the three real cases, and 0/5 on
the two cases NOT in working-knowledge (costsort, negative). The line-cap SURFACER>NAIVE delta (5/5 vs
0/5) is therefore an ARTIFACT: SURFACER recalled "70→137, Phase 22" from working-knowledge; it did not
surface it from the plan. NAIVE, leaking ~0/5, reasoned cleanly.

This is the amplifier program's central finding caught red-handed: with the harness present, the
"surfacer" recovers documented decisions BY RE-PRESENTATION, not by capability — and on the two cases the
harness does NOT document (costsort/negative), SURFACER had nothing to recall (leak 0/5).

## The uncontaminated signal
- NAIVE (clean throughout): recovered 3/4 silent-class assumptions by pure reasoning (mcp-cwd, cascade,
  costsort), MISSED only line-cap (the accretion/size-budget class). The project's silent failures were
  silent because nobody ASKED at planning time — not because they are unsurfaceable.
- The ONE fully-clean comparison (costsort-adversarial: invented, 0 leak both conditions): BOTH-CATCH.
  On an uncontaminated case, surfacer = naive.
- Cost-sort-adversarial control: SURFACER recovered the buried assumption planted on the under-rated-cost
  item (did NOT bury it via the cost-sort) — but so did NAIVE, so no headroom shown.
- Negative control: no infra-fabrication by either condition (5/5 clean) — SURFACER does not spuriously
  inject infrastructure-doubt where there is none.

## Residual open question (NOT answered by this run)
The one place NAIVE genuinely missed (line-cap = accretion/budget class) is exactly where the leak was
strongest, so whether scope-anchoring GENUINELY helps on the accretion class — independent of the
working-knowledge leak — is UNMEASURED. A valid test needs a truly clean context (a consuming project
that does NOT carry nana-dev-kit's working-knowledge).
