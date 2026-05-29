---
name: dev-plan
description: "Use when .dev-wiki/ exists for phase planning. MUST BE USED instead of brainstorming in .dev-wiki/ projects. Do NOT use for mid-phase task changes (edit tasks.md directly)."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/_ARCHITECTURE.md, $WIKI/tasks.md, $WIKI/articles/phases/*, $WIKI/articles/decisions/*]
writes: [$WIKI/_CURRENT_STATE.md(Active Phase, Contract, Decisions, Blockers), $WIKI/tasks.md, $WIKI/articles/phases/*, $WIKI/articles/decisions/*, $ROOT/.claude/rules/active-phase.md, $ROOT/.claude/rules/active-knowledge.md, $ROOT/.claude/rules/working-knowledge.md(append cross-phase entries; curator enforces dedup/cap)]
dispatches: [plan-reviewer, approach-reviewer, state-loader, artifact-writer]
tier: complex-orchestration
---

# dev-plan

Plan one phase at a time, informed by accumulated wiki knowledge. Replaces brainstorming for projects with a `.dev-wiki/` directory. Reads project state, asks targeted questions, proposes an approach, writes the plan to the wiki with compaction anchors.

**Orchestrator + executor pattern.** State loading and artifact writing are dispatched to background Agent subagents. Interactive steps (user questions, approach approval, plan review) stay with the orchestrator. See [Orchestrator Protocol](#orchestrator-protocol) below.

---

## Orchestrator Protocol

### Dispatch 1: State Loading (Steps 3-8)

After pre-checks, dispatch state loading to a background Agent:

```
Agent({
  description: "Dev-plan state loader",
  prompt: `<read ~/.claude/skills/dev-plan/state-loader-prompt.md and interpolate:>
    ROOT: <project root>
    TARGET_PHASE: <phase number and name>
    PHASE_OBJECTIVE: <objective>
    CEREMONY: <lite|standard>`,
  run_in_background: true
})
```

When it returns, you receive: project state summary, scope analysis, wiki knowledge insights, existing decisions, and design questions. Use this to drive Steps 9-14.

### What you do inline (Steps 9-14)

- **Step 9:** Ask user goal-oriented questions (informed by state loader's design questions + your own memory/knowledge recall)
- **Step 10:** Propose approach (using state loader's wiki insights + your judgment)
- **Step 13:** Dispatch approach reviewer (agent-internal quality check — incorporate findings, do not present to user)
- **Step 14:** Present approach, get user approval — this is the **direction gate**
- **Step 15:** Draft tasks, dispatch plan reviewer (agent-internal — incorporate findings, proceed to Step 16)

Before formulating your approach (Step 10), search memory and knowledge for relevant prior context. Form a position — don't default to asking the user.

### Dispatch 2: Artifact Writing (Step 16)

After user approves the direction (Step 14) and tasks are drafted (Step 15), dispatch artifact writing:

```
Agent({
  description: "Dev-plan artifact writer",
  prompt: `<read ~/.claude/skills/dev-plan/artifact-writer-prompt.md and interpolate:>
    ROOT: <project root>
    DATE: <today>
    TARGET_PHASE: <phase number and name>
    CEREMONY: <lite|standard>
    APPROACH: <approved approach>
    DECISIONS: <list of decisions>
    TASKS: <approved task list>
    WIKI_KNOWLEDGE: <key insights from state loader>
    KNOWLEDGE_GAPS: <unfilled gaps>`,
  run_in_background: true
})
```

### After artifact writer returns

1. Parse the structured return
2. If `cross_phase_facts > 0`, ask user about working-knowledge seeding (Step 16f-ter)
3. Mirror tasks to TodoWrite (Step 16g) — do this inline since TodoWrite is orchestrator-side
4. Present Step 17 implementation transition gate (interactive)
5. Report conversationally — "Phase N is planned with X tasks. Here's the approach: ..."

---

## Section Ownership — _CURRENT_STATE.md

This skill OWNS and rewrites these sections (preserve all others verbatim):
- `## Recommended Next Action`
- `## Active Phase`
- `## Active Phase Contract`
- `## Recent Decisions`

May APPEND to: `## Blockers and Open Questions` (planning questions only — do not rewrite or remove existing entries).
May SEED: `.claude/rules/working-knowledge.md` (Step 16f-ter, user-gated). wiki-query also writes this file (Steps 7a, 8) — caps are idempotent.

---

## Direction Gate

<HARD-GATE>
Do NOT write any implementation code until the user has approved the direction in Step 14.
</HARD-GATE>

---

**Triggers:** the dev-wiki session-start protocol suggests `/dev-plan` when: active phase has 0 open tasks, all tasks are done, or user invokes it directly. If no `.dev-wiki/` exists: "No dev wiki found. Run `/dev-init` first." STOP.

## Pre-checks

0. **Resume check.** If invoked with `--resume` and `$ROOT/.dev-wiki/.planning-pause` exists, read `~/.claude/skills/dev-plan/research-pause-spec.md` and follow the resume protocol (skip to Step 9 with saved state). Delete `.planning-pause` after the user provides a non-pause answer (i.e., Step 10 begins).

1. **Discover dev wiki.** Run `git rev-parse --show-toplevel 2>/dev/null || pwd` to find `$ROOT`. Check `$ROOT/.dev-wiki/_CURRENT_STATE.md`. If missing: "No dev wiki found. Run `/dev init` first." STOP.

2. **Verify living documents.** Confirm `_CURRENT_STATE.md`, `_ARCHITECTURE.md`, `tasks.md` exist under `.dev-wiki/`. If any are missing, note which ones -- they will be created during Step 16.

3. **Determine target phase.** Use the Read tool on `_CURRENT_STATE.md`:
   - If active phase has open tasks: "Phase N has X open tasks. Continue implementation." STOP.
   - If active phase has all tasks done: target = next phase (N+1).
   - If active phase has 0 tasks: target = active phase (needs planning).
   - If no active phase: target = first `not-started` phase.
   - If no phases at all: "No phases defined. Run `/dev init` or create phases manually." STOP.

4. **Ensure article directories exist:** `mkdir -p "$ROOT/.dev-wiki/articles/decisions" "$ROOT/.dev-wiki/articles/phases"`

Throughout this flow, `$ROOT` is the project root. `$WIKI` is `$ROOT/.dev-wiki`. Today's date is `$(date +%Y-%m-%d)`.

### Step 1: Ceremony Level Detection

Read `$WIKI/config.md` for `ceremony:` value (lite or standard). If absent, default to `lite`. Check target phase article frontmatter for `ceremony:` override (frontmatter wins). Precedence: phase frontmatter > config.md > default (lite). Steps marked *(Lite: skip)* below are skipped under lite ceremony. Under lite, task schema is simplified: `- [ ] <Description> | scope: <globs> | success: <criterion>` (no TDD cycle fields).

### Step 2: Spec Generation *(Lite: skip)*

For standard ceremony: check if `$ROOT/specs/<phase-slug>.md` exists OR the target phase article has a `## Formal Spec` section. Derive `<phase-slug>` from the phase name (kebab-case, e.g., "phase-12-soul-enhancement"). If neither exists: read `~/.claude/skills/dev-plan/spec-auto-invoke.md` and invoke `/spec` with `--internal` flag (agent-internal — auto-run quality checks, persist spec, no user approval gate). On completion, restart from Step 3 with the new spec.

---

## Orchestration Flow

### Step 3: Load Wiki State

Read silently -- do NOT print contents to the user. Required: `$WIKI/_CURRENT_STATE.md`, `$WIKI/_ARCHITECTURE.md`, `$WIKI/tasks.md`, target phase article (Glob `$WIKI/articles/phases/`). Optional: last 5 decision articles (Glob `$WIKI/articles/decisions/`, Read 5 most recent).

**Missing phase article:** If no article exists for the target phase, warn: "No article for Phase N. Creating a stub." Create a minimal phase article using the template from `~/.claude/skills/dev-wiki/phase-template.md` with `status: not-started` and empty scope/exit_criteria, then proceed.

**Budget:** Read at most 10 files in this step.

### Step 4: Load Cross-Wiki Knowledge (Multi-Wiki, Index-Then-Retrieve)

Discover relevant wikis, then retrieve articles from each:

1. **Discover wikis.** Read `~/.claude/wikis.json`. Collect all registered wikis. Always include the CWD wiki (`$ROOT/wiki/`) if it exists. For other registered wikis, score relevance: match wiki `description` keywords against phase objective and scope (+1 per keyword match), then read each wiki's `schema.md` and score +1 per custom tag overlap and +1 per hierarchy root keyword overlap with phase objective/scope. Include the top 1-2 scoring non-CWD wikis (skip score-0). Cap: 3 wikis total.
2. **Index each wiki.** For each selected wiki, read its `index.md` and `schema.md` (hierarchy roots, domain tags). Skip wikis missing `index.md`.
3. **Match articles by relevance** across all selected wikis. Score each article: frontmatter `tags` overlap with phase tags (+2 each), hierarchy root membership (+1), title keyword overlap with phase objective (+1 each). Rank descending across all wikis, skip score-0.
4. Read the top 3-5 articles by combined score.

If no articles score >0 across all wikis, emit: `"Cross-wiki retrieval: N wikis scored, 0 relevant articles found."` and continue (planning proceeds without wiki knowledge).

If wiki exists, count domain articles (excluding heuristics, inbox, scaffolding): `wiki_article_count=$(find $ROOT/wiki -name "*.md" -not -name "schema.md" -not -name "index.md" -not -name "SCHEMA.md" -not -path "*/heuristics/*" -not -path "*/inbox/*" -not -path "*/.processed/*" 2>/dev/null | wc -l)`. If `wiki_article_count` is 0 (WIKI_EMPTY state):

**Recommended action:** `"Knowledge wiki has no domain articles. Run /wiki-bootstrap to seed domain knowledge before planning — Phase 42 experiment showed +1.75 quality delta with domain research. Takes 2-5 minutes."` Persist `- [planning] Knowledge wiki empty — domain research unavailable (raised <today>)` to `_CURRENT_STATE.md` `## Blockers and Open Questions`. Continue without wiki knowledge.

If no `~/.claude/wikis.json` and no `$ROOT/wiki/`, skip. **Budget:** 5 articles initially (Step 5 may expand to 14 via iterative loop).

### Step 5: Iterative Knowledge Completeness Check *(Lite: skip)*

Read `~/.claude/skills/dev-plan/iterative-retrieval-spec.md` for the full loop protocol. Extract concepts (frozen set), then iterate up to 3 rounds until coverage ≥ 70% or no new articles. Pass unfillable gaps to Step 8 as design questions. If Step 4 was skipped (no wikis), skip this step.

### Step 6: Explore Phase Scope (Bounded)

Read `~/.claude/skills/dev-plan/scope-exploration-spec.md` for the full scope exploration protocol. Inputs: phase article `scope` field, `$WIKI/articles/files/*.md`, `$WIKI/articles/modules/*.md`. Budget: ~5000 tokens.

### Step 7: Pre-Implementation Validation Gate *(Lite: skip)*

Read `## Development Toolchain` from `$WIKI/_ARCHITECTURE.md`. If present, check: (1) test framework exists if TDD tasks planned — surface as Step 9 question if missing, (2) type checker/linter — note as non-blocking warnings if absent. If section absent: `"Toolchain status unknown — run /dev-scan."` (non-blocking). Optional: run lightweight tool checks (pytest --co, mypy --version, tsc --noEmit) if tools detected. **Budget:** Max 3 Bash calls.

### Step 8: Identify Design Questions (Targeted)

Based on Steps 3-6, identify design questions. These are NOT open-ended brainstorming questions -- they are targeted, constrained by prior decisions and wiki knowledge.

For each question, check: Does a prior decision already answer this? Does a knowledge wiki article provide guidance? Is this genuinely open?

**PERSIST immediately:** Write identified questions to `_CURRENT_STATE.md` under `## Blockers and Open Questions` as `- [planning] <question text> (raised <today>)`.

### Step 9: Ask User Goal-Oriented Questions

The wiki provides domain knowledge; the user provides **intent**. Three question types: **Goal** ("Should this produce a prototype or a design doc?"), **Constraint** ("Are we allowed to change the ownership contract?"), **Priority** ("If we can only fit 3 of 4, which do we drop?"). 1-3 questions total *(Lite: 0-1)*, one at a time, A/B/C choices preferred. Zero questions is valid if prior decisions fully constrain the approach.

**Research pause:** If the user's answer reveals they need to research a topic before committing to a direction (e.g., "I need to learn about X first"), read `~/.claude/skills/dev-plan/research-pause-spec.md` and follow the save protocol. This preserves planning state so `/dev-plan --resume` can skip Steps 3-8 after research completes.

### Step 10: Propose Approach

**Thinking Protocol T0 (inline, before proposing):** Three mandatory outputs — produce specific, non-vacuous content visible in conversation. Restating the user's input or confirming "this is correct" is a failed check.

1. **Name the weakest assumption** — identify the assumption in the user's input, prior state, or accumulated context most likely to be wrong. State what breaks if it IS wrong. "The approach is sound" is not an assumption — name a concrete belief that could be false.
2. **Identify an alternative framing** — describe one way the objective could be reframed that hasn't been considered. Not a strawman — a genuine reframing that could change the approach.
3. **State what would change your recommendation** — name the specific information that, if different, would lead to a different approach. Then check: do you already have it?

**Non-vacuity gate:** Review your T0 output. If any response merely confirms the user's framing without naming a specific risk or alternative, redo that check. After one retry, if still vacuous, log `"T0: unable to generate genuine challenge for [check N]"` and proceed — do not block planning.

Based on user's answers (or prior constraints), propose the approach for THIS PHASE ONLY.

- **1-2 options with trade-offs.** Lead with your recommendation.
- **Reference knowledge wiki patterns** where applicable (`[[wiki:slug|Display]]` links).
- **Reference prior decisions** that constrain this phase.
- **YAGNI ruthlessly.** If not in exit criteria, it does not belong.
- **Cover spec fields:** When proposing, ensure the approach addresses constraints (safety rails preventing known failure modes), checkpoints (when to pause and report), and assumptions (what must be true — stop if violated). These complement the existing objective/scope/exit-criteria fields.

**PERSIST immediately:** Write draft decision article at `$WIKI/articles/decisions/<slug>.md` with `confidence: low`. Read `~/.claude/skills/dev-wiki/decision-template.md` for the decision article template.

### Step 11: Self-Dialogue (Devil's Advocate) *(Lite: skip)*

Read `~/.claude/skills/dev-plan/self-dialogue-prompt.md`. Dispatch Agent with: self-dialogue prompt + proposed approach text + condensed IRON RULES (`iron-rules-injection-v2.md` format) + phase objective/exit criteria. Collect 2-3 counterarguments with IRON RULE citations. **Timeout:** 60 seconds.

**Resolve inline:** For each counterargument: accept (revise approach) or reject (state specific reason). Update the approach text before proceeding. **Fail-open:** If companion missing, subagent times out, or output contains no `IRON-` citations, skip — proceed with unmodified approach.

### Step 12: Contradiction Check (Inline) *(Lite: skip)*

Search for wiki knowledge that might contradict the proposed approach. Serial inline (not subagent).

1. Extract 3-5 key claims from the proposed approach.
2. Search wiki indexes for tag-overlapping articles NOT in the Steps 4/5 retrieval set.
3. **HARD skip:** If 0 unread articles found, proceed to Step 13.
4. Read up to 3 new articles. Flag contradictions or better alternatives.
5. If contradictions found, revise approach before dispatching the reviewer.

### Step 13: Automatic Approach Critique *(Lite: skip)* — Agent-Internal

Critique the approach using a subagent. This is an **agent-internal quality check** — incorporate findings automatically, do not present reviewer output to the user.

1. **Read** `~/.claude/skills/dev-plan/approach-reviewer-prompt.md`.
2. **Dispatch** Agent with: approach-reviewer prompt + proposed approach + phase article (objective, exit criteria) + top 3-5 articles from Steps 4/5 + prior decision articles (Step 3).
3. **Collect** Score/Issues/Suggestions/Verdict. **Timeout:** 120 seconds.
4. **Handle verdict:**
   - Score 6-10: Incorporate feedback into approach, proceed to Step 14.
   - Score 1-5: Revise approach to address CRITICAL issues, then proceed to Step 14. Note unresolved concerns in the phase article.
5. **Graceful fallback:** If companion file missing or subagent times out, proceed to Step 14 without critique.
6. **Heuristic judge (optional):** If `$ROOT/wiki/heuristics/` exists with ≥1 article: **Read** `~/.claude/skills/dev-plan/heuristic-matcher.md`, dispatch trigger matcher subagent with phase objective/scope. If ≥1 match: **Read** `~/.claude/skills/dev-plan/heuristic-judge-prompt.md`, dispatch judge subagent with approach + matched heuristic content (≤1200 chars). Merge heuristic judge verdict with approach reviewer verdict (lower score wins). **Timeout:** 60 seconds combined. **Fail-open:** skip silently if wiki missing, no matches, or timeout.
7. **Counter update (after judge):** If heuristic judge ran and produced a verdict: **Read** `~/.claude/skills/dev-plan/heuristic-counter-update.md`, update helpful/harmful counters on matched heuristic articles. Then **Read** `~/.claude/skills/dev-plan/heuristic-lifecycle.md`, evaluate lifecycle transitions. Both are fail-open.

### Step 14: User Approves Direction (Direction Gate)

Present the approach and wait for explicit approval. This is the **direction gate** — the only pre-implementation user approval point. The user confirms intent and scope, not technical details.

<HARD-GATE>
Do NOT write any implementation code until the user has approved.
A vague "sure" counts as approval. Silence does NOT.
</HARD-GATE>

If the user requests changes, revise, update the draft decision article, and re-present. **Maximum 3 revision rounds.** After 3: proceed with the best available version and note unresolved concerns in the phase article.

### Step 15: Draft Tasks and Review Plan Quality *(Lite: skip — merge into Step 14)*

Read `~/.claude/skills/dev-plan/plan-review-companion.md` for the full protocol: draft tasks, dispatch plan reviewer subagent, handle verdict. This step is **agent-internal** — incorporate reviewer findings and proceed to Step 16 without blocking on user approval. The direction gate (Step 14) already confirmed the approach.

### Step 16: Write to Dev Wiki

All wiki artifacts are updated atomically. Follow this order:

#### 16a: Finalize Decision Articles *(Lite: skip)*
Update draft decisions: set `confidence` to `medium`/`high`, set `source: plan`. Create additional articles for new decisions from Steps 9-14.

#### 16a-bis: Memory Bridge *(Lite: skip)*
Read `~/.claude/skills/dev-plan/memory-bridge.md` and follow the procedure: budget guard via `memory_stats`, select 1-3 key decisions, store to memory with `category="custom"` and `tags=["bridge-decision"]`. Fail-open — skip silently on any error.

#### 16b: Write Tasks to tasks.md
Write tasks for the target phase (see `~/.claude/skills/dev-plan/task-schema.md` for enriched task schema, `~/.claude/skills/dev-wiki/size-budgets.md` for size budgets). Each task MUST include TDD cycle (RED/GREEN/REFACTOR), scope, success criterion, and size *(Lite: simplified — description+scope+success only)*. Order by dependency. At most 1 L task per phase.

#### 16c: Update _CURRENT_STATE.md
Rewrite `## Recommended Next Action`, `## Active Phase` (status: active, ~0%), `## Active Phase Contract`, `## Recent Decisions`, and `## Blockers and Open Questions` (remove resolved `[planning]` questions). Read `~/.claude/skills/dev-wiki/state-template.md` for the template.

#### 16d: Update _ARCHITECTURE.md
Only update if the approach changes project structure. If no structural changes, skip.

#### 16e: Update Phase Article
Set `status: active`, `updated: <today>`. If creating a new phase article, read `~/.claude/skills/dev-wiki/phase-template.md` for the template.

#### 16f: Write Compaction Anchor -- active-phase.md
Do NOT create any other hooks or rules files beyond `active-phase.md` and `active-knowledge.md` (Steps 16f and 16f-bis). Ensure `$ROOT/.claude/rules/` exists (`mkdir -p`). Write `$ROOT/.claude/rules/active-phase.md` with: Phase, Objective, Scope (file globs), Key constraints (from decisions), Exit criteria, Abort rule, **and a Gates section**. Size: 10-20 lines.

The Gates section tracks the two boundary checkpoints (2-gate ceremony model):

```
Gates:
- [ ] Direction confirmed by user (approach approved)
- [ ] Delivery accepted (post-implementation report)
```

The direction gate must be marked before implementation begins. The delivery gate is marked post-implementation when the user accepts the delivery report (see dev-debrief).

#### 16f-bis: Write Compaction Anchor -- active-knowledge.md *(Lite: skip)*

Distill cross-wiki articles from Step 4 and phase decisions from Steps 9-14 into `.claude/rules/active-knowledge.md`. Read `~/.claude/skills/dev-wiki/active-knowledge-spec.md` for the template, evaluation criteria, and size budget.

**Process:** (1) Extract 2-5 key propositions per source. (2) Evaluate each: must pass 2 of 3 filters from `~/.claude/skills/dev-wiki/active-knowledge-spec.md` (multi-turn, non-obvious, phase-dependent) -- drop the rest. (3) Assemble using the template. (4) Count lines: if >30 re-distill; if still >40: skip writing active-knowledge.md, report: "Active knowledge exceeds 40-line cap. Skipping." Continue with Step 16g. (5) Write to `$ROOT/.claude/rules/active-knowledge.md`, overwriting any prior phase file.

**Skip:** If no knowledge wiki and no new decisions in Steps 9-14, skip entirely. Delete any prior-phase file if it exists; if absent, skip silently.

#### 16f-ter: Seed Working Knowledge (Cross-Phase Facts)

After writing active-knowledge.md, evaluate retrieved facts from Step 4 that were NOT included in active-knowledge (failed phase-dependent filter but passed multi-turn + non-obvious). These are cross-phase facts useful beyond this phase. If any exist, offer: `"N cross-phase facts available for working knowledge. Activate? (y/n)"`. On confirmation: (1) read existing `.claude/rules/working-knowledge.md` if it exists, (2) append genuinely new entries as `[uses: 1]` with `activated: <today>`. Dedup (by proposition text, NOT source slug), the 100-entry cap, and ordering are enforced deterministically by the session-start curator — see `~/.claude/skills/dev-wiki/working-knowledge-spec.md`; do NOT hand-dedup, hand-sort, or hand-prune here. Skip if no cross-phase facts found.

#### 16g: Mirror Tasks to TodoWrite (Compaction Anchor)
Write each task to TodoWrite with embedded constraints. Set all to `pending`. Set first to `in_progress` only if user will continue in this session (determined in Step 17).

#### 16h: Append to log.md; 16i: Update index.md
`[<ISO-timestamp>] PLAN -- Phase N planned, X tasks, Y decisions`. Add new decision articles and update the phase article entry in index.md.

### Step 17: Auto-Transition to Implementation

Report: "Phase N planned with X tasks. Beginning implementation." Set `Transition: continue` in contract. Proceed to Step 18 automatically — no user choice menu.

For phases with 8+ tasks, note in the report that a fresh session may be beneficial, but do not block.

### Step 18: Begin Implementation

Read `~/.claude/skills/dev-plan/implementation-guide.md` for implementation instructions.

---

## Tool Standards

- **Glob** for file discovery (not find/ls via Bash)
- **Grep** for content search (not grep/rg via Bash)
- **Read** for reading files (not cat/head/tail via Bash)
- **Bash** reserved for git, build tools, and system commands with no dedicated tool

> Compaction anchors and error handling extracted to companion. See `dev-plan/compaction-anchors-spec.md`.
