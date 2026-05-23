# Active Phase Context

Phase: 22 - Session-Start Refactor + v0.4.0 Ship
Objective: Extract session-start.sh modules, fix scan-secrets BSD grep, update gap analysis, bump v0.4.0.
Scope: templates/.claude/hooks/session-start.sh, session-start.d/*, scan-secrets.sh, eval/corpus/hook-scan-secrets-pattern/*, .dev-wiki/articles/roadmap-gap-analysis.md, tests/test_templates.sh, VERSION
Key constraints: Source (not subprocess) for modules; no install.sh changes; eval fixture update atomic with scan-secrets fix.
Exit criteria: session-start.sh ≤70 lines, 2 sourced modules pass bash -n, no \x27 in scan-secrets, ≥4 CLOSED gaps, make test + make eval 100%, v0.4.0 tagged.
Abort: if blocked >3 attempts, ask user: skip or abort.

Tests: 128 passing. Eval: 38/38 scenarios. Budget: 245/300.

Gates: [x] spec [x] approach [x] plan-review [x] tasks [ ] memory: session-start search done
