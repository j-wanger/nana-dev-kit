# Ceremony Cost Table — Phases 76–85 (frozen corpus)

Sessions: 12; phases = 10; extractor: extract-costs.py (control: test-cost-extractor-control.sh, all checks). Raw = in+cw+cr+out summed; cache-adjusted = in*1.0 + cw*1.25 + cr*0.1 + out*5.0 (input-token-equivalents). KNOWN CAVEATS: materiality computed on pooled corpus share, not the registered per-phase median (verdict-neutral for the one immaterial step at 0.8%); interruptions count AskUserQuestion only (blocking permission prompts not recoverable from transcripts); session selection by first-timestamp may exclude phase-spanning sessions (PLAN-split not implemented) - same basis as the manifest under-enumeration caveat.

| step | msgs | in | cache_write | cache_read | out | raw | cache_adj | wall_s | interrupts | dispatches | subagent_out | %adj | %wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dev-plan-orchestration | 1365 | 184463 | 4887218 | 368597628 | 2002052 | 375671361 | 53163508 | 48880 | 10 | 10 | 1240217 | 34.4 | 23.0 |
| spec-generation | 386 | 47882 | 3313574 | 78700938 | 905665 | 82968059 | 16588268 | 8151 | 1 | 13 | 569995 | 10.7 | 3.8 |
| approach-reviewer | 217 | 19802 | 2187516 | 34370509 | 436289 | 37014116 | 8372692 | 37924 | 8 | 5 | 262221 | 5.4 | 17.8 |
| plan-reviewer | 24 | 564 | 451124 | 3872186 | 58481 | 4382355 | 1244092 | 776 | 0 | 5 | 256614 | 0.8 | 0.4 |
| review-gate-reviewer | 97 | 14636 | 1261994 | 36275452 | 142410 | 37694492 | 5931723 | 3076 | 1 | 3 | 345744 | 3.8 | 1.4 |
| debrief-capture | 273 | 114051 | 3803476 | 95865081 | 333311 | 100115919 | 16121459 | 37174 | 3 | 8 | 1071256 | 10.4 | 17.5 |
| implementation-other | 883 | 342338 | 11123299 | 278327272 | 2232085 | 292024994 | 53239613 | 76864 | 15 | 0 | 3823294 | 34.4 | 36.1 |

Interrupt allowance: dev-plan-orchestration + debrief-capture 1/phase (the 2 budgeted boundary gates); others 0 (pre-registration: Cost materiality).

MATERIALITY-VERDICT: dev-plan-orchestration=material spec-generation=material approach-reviewer=material plan-reviewer=immaterial review-gate-reviewer=material debrief-capture=material
EARLY-EXIT: no
