# Active Phase Context

Phase: 51 - Prompt-Type Hooks — Heuristic-Informed Runtime Judging
Status: COMPLETED (7/7 tasks done)
Objective: Trigger-based heuristic matching + fire-and-forget heuristic judge at Step 6.5. Ground-truth mapping (25 scenarios, 84% coverage), LLM + domain-tag matcher, plan-adapted judge, --selective eval mode.
Scope: templates/.claude/skills/dev-plan/**, eval/reasoning/**
Result: Ground-truth shows 84% coverage (21/25 scenarios matched). 4 blind-spot scenarios in organizational/distributed-systems domains. heuristic-matcher.md (60 lines), heuristic-judge-prompt.md (57 lines), SKILL.md Step 6.5 (316/350 lines). 2 decisions (1 upgraded medium to high). +6 test assertions, 96/96 companions, 50/50 eval.
Exit: All 8 exit criteria met -- matcher + judge exist, SKILL.md refs, ground-truth 25+, --selective works, results.json + analysis.md exist, make test + make eval pass.

Gates: [x] direction=approved [x] delivery=accepted
