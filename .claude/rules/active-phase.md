# Active Phase Context

Phase: 63 - Harness Assessment & Eval-Validity
Status: COMPLETE (4/4 tasks [x]; all exit criteria met; delivery accepted 2026-05-29; committed). Next session: /dev-plan Phase 64 (top roadmap item: heuristic-machinery cut + self-dialogue removal, batched as one renumber pass).
Objective: Assess the whole harness from 4 angles (utilization audit / coherence map / eval-validity-spine / synthesis) via a multi-agent workflow, then EXECUTE the evidence-confirmed slam-dunk cuts in-phase + leave a `decidable-when:`-disciplined roadmap. Eval-validity is the spine: net-zero is ambiguous (worthless feature vs blind instrument) — an instrument-sensitivity probe must precede any cut-by-eval.
Scope: scripts/harness-audit.sh, .gitignore, eval/**, templates/**, modules.json, wiki/heuristics/**, .dev-wiki/articles/**
Tasks: T1 gitignore .memory/*.db [S, do FIRST] → T2 harness-audit.sh + 4-angle frozen-state pass [L] → T3 eval-validity verdict + decidable-when roadmap [M] → T4 batched quarantine-first cuts + re-verify [M].
Key constraints: NO cut on log-absence/loadedness (need a firing test); NO cut on net-zero until the probe shows the instrument is `sensitive`; every templates/ deletion is a migration (quarantine-first, cp -r blast radius); cuts batched at end of a frozen-state pass; `uses` counter is NOT the cut signal.
Exit criteria: harness-audit.sh runs + emits classified output + `MATCH=ok`; probe recorded with `instrument: sensitive|blind|mixed|untested` token + delta; AFTER batched cuts → make test ≥13 green + make eval 54/54 + test_registration.sh + referential-integrity all pass; .memory/*.db gitignored; verdict article + roadmap where item-count == decidable-when:-count; every never-fired cut cites a firing test.
Abort rule: if the probe shows the apparatus is BLIND, STOP cut-justification-by-eval and pivot remaining effort to the eval proposal (no more verdicts from a blind instrument); never cut on log-absence/loadedness; any cut that breaks test_registration.sh / referential-integrity / make test / make eval is reverted and kicked to the roadmap. If blocked >3 attempts, mark [blocked:], report, ask skip-or-abort.

Outcome: instrument verdict = MIXED (binary corpus SENSITIVE — probe 54→53→54; LLM-judge evals BLIND — 58/59/61 net-zeros inside their own noise). Shipped: session-start.d cp-fix (curator was never firing on scaffolds) + wiki-query flip-flop fix + /dev-context phantom fix + wiki-consolidate quarantine + scripts/harness-audit.sh (USED=47/LATENT=31/UNCERTAIN=5/DEADWEIGHT=4, MATCH=ok, DRIFT=none) + eval-validity verdict + 10-item decidable-when roadmap. make test green / make eval 54/54 / test_registration 41/41. Self-dialogue removal + heuristic-machinery cut deferred (batched — shared dev-plan renumber surface).

Gates:
- [x] Direction confirmed (approved 2026-05-29 via dev-plan direction gate: diagnose + cut slam-dunks, multi-agent workflow, eval-validity spine)
- [x] Delivery accepted (delivery gate — accepted 2026-05-29; reviewer ships-safely, no HIGH/MEDIUM; 2 LOW loose-ends fixed inline)
