# Active Phase Context

Phase: 89 — Post-Trim Dogfood & Demand-Evidence Round (planned 2026-06-11)
Objective: pre-registered four-stage evidence round — accrue real exposure for the two Phase-88
trim-trial observation windows and collect clean memory-layer demand evidence for the deferred
A4/A6 round (spec specs/phase-89-dogfood-demand-evidence.md, nana:approved).
Scope: eval/dogfood-round/** (new apparatus); edge-screener out-of-repo behind HARD checkpoint
(re-sync + ≥3 real sessions); window-events for BOTH kit-side and consuming-project sessions;
.dev-wiki Blockers/ledger updates.
Key constraints: evidence-only claim ceiling — file evidence/defects, NEVER dispositions;
pre-registration commit FIRST (T1 first-add-commit ancestry; post-hoc rule edits VOID);
orchestrator-only deterministic classification, never session self-attestation; no kit edits —
templates/**, modules.json, MANIFEST byte-untouched; no reverts of d43950f/df3e623/75b48af/b8bd416;
out-of-repo writes behind the HARD checkpoint; measurement-blind archived prompts.
Exit: the spec's 10 machine-checkable criteria via eval/dogfood-round/run-exit-criteria.sh ALL-PASS.
Abort: blocked >3 attempts → ask user; liveness-probe failure → demand strand BLOCKED, never
zeroed; trigger event observed → file verbatim + surface immediately.
Standing (Phases 90-93): EVERY working session appends its window-events attestation rows
(per-session, per-window) to eval/dogfood-round/evidence/window-events.md until the Phase-93
trim-trial disposition — protocol in eval/dogfood-round/pre-registration.md.
Gates:
- [x] Direction confirmed by user (assumption positions A1-A5 all accept, A2 defended; all_accept:true — 2026-06-11)
- [ ] Delivery accepted (post-implementation report)
