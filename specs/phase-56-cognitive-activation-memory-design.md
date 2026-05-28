<!-- nana:approved 2026-05-28 -->
# Spec: Cognitive Activation & Memory Design

## Objective

Make the harness's cognitive layer (knowledge wiki, heuristics, domain research) activate at natural decision points in the development lifecycle, and classify each memory layer's activation mode (mandatory/automatic/voluntary) with rationale.

## Context

Phase 42's effectiveness experiment tested 5 implementations of the same stock screener. Engineering hooks (auto-ruff, scan-secrets, audit-log) fired automatically and worked perfectly. Cognitive tools (knowledge wiki, heuristic library, decision articles, spec review) are voluntary skills and never fired — the agent's natural behavior is to start coding.

Results: harness scored 7.5/10, bare Claude Code with open-ended prompt scored 7.25/10. The +0.25 gap came entirely from engineering quality. The cognitive layer contributed nothing because it never activated. Meanwhile, open-ended prompts outperformed prescriptive specs by +1.75 points.

Phase 55 fixed Category 1 (unwired components — nana-init cascade failure, +40 registration test assertions) and Category 3 (prescriptive specs — reformed to Success Vision + Domain Research Questions). Category 2 (cognitive tools don't activate) remains the open gap.

The harness has 5 memory/knowledge layers: MCP memory server (cross-session persistence via memory_store/memory_search), working knowledge (.claude/rules/working-knowledge.md — compaction-surviving facts), active knowledge (.claude/rules/active-knowledge.md — phase-specific context from wiki), knowledge wiki (wiki/ — domain articles + 16 heuristic articles, zero domain articles), and dev wiki (.dev-wiki/ — project lifecycle state).

Current state: cognitive-readiness.sh diagnostic at session-start detects gaps (wiki empty, memory status) but only reports — doesn't force any action. The knowledge-wiki module has zero hooks (all 11 skills are voluntary). The dev-wiki module has 11 hooks. This structural asymmetry explains why engineering enforcement works but cognitive tools don't.

## Scope

### In scope
- Memory architecture classification: assign each of the 5 layers a documented activation mode with rationale
- Activation point identification: where in the lifecycle cognitive tools should fire
- Session-level vs task-level activation distinction
- Wiki seeding trigger: conditions that cause wiki-bootstrap recommendation before proceeding
- Mandatory retrieval architecture: hooks or skill modifications that surface relevant knowledge at decision points
- Eval scenarios for cognitive activation (at least 2)
- Decision article documenting the memory architecture classification

### Out of scope
- Knowledge wiki content creation (wiki-bootstrap's job — this phase designs WHEN it triggers, not what content to create)
- Heuristic library expansion (Phases 44-52 completed the cognitive enhancement roadmap)
- Memory server code changes (vendored from nanaclaw, near-zero divergence maintained)
- New hook infrastructure types (use existing PreToolUse/PostToolUse/Stop/SessionStart)
- Language-agnostic mode (roadmap gap 4.1, separate phase)
- Behavioral delta measurement (measuring whether agent "used" injected knowledge is impractical to automate)

## Approach

Design a two-tier activation architecture that separates session-level readiness from task-level cognitive injection, using existing hook infrastructure for mandatory activation and skill integration for automatic activation at lifecycle boundaries.

**Activation mode definitions** (the three modes this spec classifies each layer into):
- **Mandatory**: content is injected into agent context by a hook at every occurrence of a lifecycle event. The agent sees it without choosing to. Hooks exit 0 (fail-open) — they inject, never block.
- **Automatic**: a skill reads the content as part of its own flow. The agent invokes the skill for another reason; the cognitive retrieval happens as a side effect. No separate invocation needed, but requires the skill to be invoked.
- **Voluntary**: the agent must explicitly choose to invoke a skill or tool. No hook, no side-effect retrieval. Agent's natural behavior is to skip it.

### Domain Research Questions
1. What is the right injection budget when multiple cognitive tools share context? Phase 46 showed anti-pattern table injection caused -1 regression on scenario 012 at roughly 400 tokens. If heuristic injection (up to 1200 chars), domain wiki content, and memory results all inject simultaneously, what's the combined ceiling before dilution?
2. How should empty-state activation differ from content-available activation? When the knowledge wiki has zero domain articles (current state), mandatory wiki consultation returns nothing — should this block with "seed wiki first" or pass through with a one-liner?
3. Where in dev-plan's flow is the highest-leverage point for domain knowledge injection? Step 2 (load wiki) already reads articles, but Step 6 (propose approach) is where design decisions happen. Is the injection point correct or should knowledge surface closer to the decision?

## Constraints (CRITICAL)

- **Shared injection budget:** total cognitive injection across ALL mandatory tools must stay under 1200 characters combined at any single decision point. Prevents the Phase 46 context dilution pattern. Guard: character count check before injection. Truncation priority: memory results truncated first, heuristics second, domain wiki last (domain wiki is highest priority, truncated last).
- **Mandatory retrieval, not mandatory compliance:** mandatory activation surfaces relevant information (framed as "relevant context") but does not prescribe how to use it. Prevents the "mandatory = prescriptive" anti-pattern the experiment identified. Guard: injected content uses retrieval framing, not directive framing.
- **Fail-open on all cognitive hooks:** every cognitive activation point must exit 0 even when wiki is empty, memory is broken, or content is missing. Prevents blocking on infrastructure gaps. Guard: jq fail-open guard pattern, all hooks follow existing `command -v jq >/dev/null 2>&1 || exit 0` convention.
- **No ceremony inflation:** the 2-gate model (direction + delivery) must not grow. No new user-facing approval points for cognitive tools. Guard: count of HARD-GATE tags in dev-plan SKILL.md must not increase beyond current count (test assertion).
- **Session-start.sh stays under 70-line cap:** any new mandatory activation logic uses the session-start.d/ extraction pattern, not inline in session-start.sh. Guard: `wc -l < session-start.sh` assertion in tests.
- **Circular bootstrap safety:** below minimum viable content threshold (e.g., zero domain wiki articles), mandatory activation emits a one-line diagnostic ("knowledge wiki empty — run /wiki-bootstrap to seed domain content") rather than injecting empty scaffolding. Prevents training the agent to ignore cognitive output. Guard: article count check before injection.

## Success Vision

The memory architecture has a clear, documented classification. Each of the 5 layers has a defined activation mode with rationale that traces to experiment evidence. At lifecycle boundaries (dev-plan, spec, review), relevant domain knowledge surfaces automatically — not because the agent chose to look it up, but because the architecture puts it in the path. When the knowledge wiki is empty, the system clearly signals "seed domain knowledge before proceeding" at the first natural checkpoint rather than silently running with nothing. An agent using the harness on a new domain project gets a clear path: init -> seed knowledge -> plan with knowledge -> implement with knowledge in context. The overall design follows the experiment's principle: mandatory retrieval of relevant information at decision points, open-ended reasoning about what to do with it.

## Exit Criteria (machine-checkable)

- [ ] `test -f .dev-wiki/articles/decisions/memory-architecture-classification.md && grep -q 'mandatory\|automatic\|voluntary' .dev-wiki/articles/decisions/memory-architecture-classification.md` (architecture decision documented with activation modes)
- [ ] `bash -n templates/.claude/hooks/session-start.d/cognitive-readiness.sh` (enhanced diagnostic passes syntax check)
- [ ] `grep -q 'wiki_article_count\|WIKI_EMPTY' templates/.claude/skills/dev-plan/SKILL.md` (dev-plan has functional empty-wiki handling with article count variable, not just an advisory comment)
- [ ] `[ $(find eval/corpus -type d -name 'cognitive-*' -o -name 'context-cognitive-*' 2>/dev/null | wc -l) -ge 2 ]` (at least 2 eval scenarios for cognitive activation)
- [ ] `make test && make eval 2>&1 | grep -qE 'Score.*100'` (no regressions, all scenarios pass)

## Checkpoints

- After memory architecture classification (decision article): report the mandatory/voluntary split and rationale before implementing any hooks or skill changes
- After activation point identification: report which lifecycle boundaries get mandatory injection and the injection budget allocation
- After eval scenarios written: verify each scenario has a concrete pass/fail condition covering at least one mandatory-activation path and one empty-wiki path
- If total injection content exceeds 1200-char budget at any point: STOP and redesign the injection strategy before continuing

## Assumptions

- Knowledge wiki infrastructure works (wiki-query, wiki-bootstrap, heuristic matcher are functional). If false: fix infrastructure bugs before activation work. Detection: `test -d wiki && test -f wiki/schema.md` for structure; distinguish "infrastructure broken" (schema.md missing, wiki-query errors) from "no content yet" (infrastructure intact, zero articles).
- Session-start.d/ extraction pattern supports additional modules without session-start.sh modification. If false: refactor session-start.sh first.
- Dev-plan Step 2 (Load Cross-Wiki Knowledge) is the right injection point for domain knowledge. If false: identify the correct step and modify the plan.
- The 5-layer memory model is complete — no missing layer needs to be added first. If false: add the missing layer in a prerequisite phase.
