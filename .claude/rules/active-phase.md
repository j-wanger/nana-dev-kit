# Active Phase Context

Phase: 29 - v0.5.1 Grade Push
Status: Active, 0/7 tasks done
Objective: Close 5 v0.5.0 critique gaps: root-skip test fix, dev-plan companion extraction, /nana + /memory-consolidate skills, spec provenance marker, enforcement hardening with event logging.

Constraints:
- enforce-spec.sh backward compat: OR logic (provenance marker OR exit-criteria)
- No vendored memory_server/ Python changes
- Enforcement log capped at 500 lines (tail truncation)
- dev-plan SKILL.md target <=330 lines post-extraction

Tests: 169 passing. Eval: 43/43. Budget: ~300/300.

Gates: [x] spec [x] approach [x] plan-review [x] tasks
