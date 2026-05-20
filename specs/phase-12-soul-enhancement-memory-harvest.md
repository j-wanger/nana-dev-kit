# Spec: Phase 12 — Soul Enhancement & Memory Harvest

## Objective

Add a relational warmth layer to nana-soul.md (5 personality traits at OpenHuman-grade density), integrate a memory-harvest step into dev-debrief, and close two process enforcement gaps: spec-existence check in dev-plan and thinking-protocol enforcement before approach formulation.

## Context

OpenHuman comparison revealed that nana-soul.md is 52 lines of technical identity with no relational persona — warmth, directness, failure handling, register matching. OpenHuman (open-source system prompt known for high persona density) achieves this in 30 lines. The soul is the one file every interaction touches; making it as good as OpenHuman's is the highest-impact single change.

Institutional knowledge (corrections, preferences, failure lessons) is currently captured manually via ad-hoc memory_store calls. Dev-debrief already extracts this information (Step 4) but only routes it to wiki articles and tasks.md. Adding a memory-harvest step would automate what's currently manual.

Two process gaps exposed during Phase 12 planning: (1) dev-plan has no spec-existence check — standard ceremony phases can bypass /spec entirely because the routing is one-directional (spec routes TO dev-plan, but dev-plan doesn't check FOR spec). (2) The soul's thinking protocol ("challenge the frame, read subtext, delay commitment") is not triggered anywhere in dev-plan's procedural flow — skill procedures override soul behavioral guidance.

## Scope

### In scope
- nana-soul.md: compress >=3 lines from existing sections, add "Voice & presence" section (~5 bullets)
- nana.instructions.md: sync to match (byte-exact minus YAML frontmatter)
- dev-debrief: add memory-harvest step (new Step 4.7 in SKILL.md, companion file memory-harvest.md ~40 lines)
- dev-debrief executor: add memory-harvest dispatch in executor-prompt.md
- dev-plan SKILL.md: add spec-existence check (new Step 0.6 in pre-checks, ~5 lines)
- dev-plan SKILL.md: add thinking-protocol T0 check before Step 6 approach formulation (~5 lines)
- tests: soul ceiling assertion (<=60 lines), budget regression (<=300 total)

### Out of scope
- Standalone memory-keeper skill (decision: integrate into dev-debrief instead)
- install.sh changes (no new files to install — soul is already copied, debrief is a global skill)
- Automated hook trigger for memory-harvest (manual invocation via dev-debrief is sufficient)
- Session-length awareness (deferred from Phase 11 retro)
- Self-learning / correction-accumulation automation (premature at single-user scale)
- Dev-plan SKILL.md line reduction (306 lines is pre-existing technical debt, not Phase 12 scope)

## Approach

**Soul:** Compress "What to avoid" from 5 to 2 bullets (3 are provably redundant: "sycophantic agreement" is covered by Thinking protocol's "challenge the frame"; "writing more code" is covered by Work habits line 34 + Code quality lens #1; "over-broad exception handling" is covered by Code quality lens #2). Add "## Voice & presence" between Technical posture and Thinking protocol with 5 bullets: genuinely interested, warm but direct, match register, acknowledge frustration, celebrate real progress. Target: <=57 lines. Sync nana.instructions.md via copy.

**Memory harvest:** Add Step 4.7 to dev-debrief SKILL.md (~3 lines: heading + "Read companion file" instruction). Create ~/.claude/skills/dev-debrief/memory-harvest.md (~40 lines) defining: what to extract (corrections, preferences, failure lessons — NOT phase decisions which already go to wiki), output format (memory_store calls with category tags), 100-entry advisory ceiling, stale-entry removal guidance. Update executor-prompt.md to include the memory-harvest step.

**Spec-existence check:** Add Step 0.6 to dev-plan SKILL.md pre-checks (~5 lines). For standard ceremony: check if specs/<phase-slug>.md exists OR phase article has "## Formal Spec" section. If neither: "No spec found for Phase N. Run /spec first." STOP. Lite ceremony: skip this check.

**Thinking-protocol T0:** Add inline check before dev-plan Step 6 (~5 lines). Before proposing approach, require 3 explicit steps matching the soul's thinking protocol: (1) challenge the frame — is this the right problem to solve? (2) read subtext from constraints — what's the real ask behind the stated objective? (3) delay commitment — do we have enough information, or should Step 5 ask more questions? Output goes to conversation (visible to user), not to artifacts.

## Constraints (CRITICAL)

- Soul must stay <=60 lines: prevents instruction-following degradation from context bloat
- Instruction budget must stay <=300 lines total: regression test enforces this
- nana.instructions.md must byte-match soul minus frontmatter: existing diff test enforces sync
- Memory-harvest output must use memory_store MCP calls only: per memory-convergence-mcp-only decision, no file intermediary
- Memory-harvest must NOT duplicate dev-debrief's existing decision extraction (Step 5): decisions go to wiki articles, corrections/preferences/lessons go to memory_store
- SKILL.md additions must be minimal: dev-debrief at 306 lines (over 250 cap), dev-plan at similar scale. Each gets ~3-5 new lines only.
- "Voice & presence" traits must pass Rust litmus test: every trait applies universally, not Jake-specific
- Spec-existence check must only fire for standard ceremony: lite phases don't require specs
- Thinking-protocol T0 output is conversational only: no artifacts, no files, no gates — it's a reasoning prompt, not a blocking check

## Deliverables

1. templates/.claude/rules/nana-soul.md — updated (<=57 lines, new Voice & presence section)
2. templates/.github/instructions/nana.instructions.md — synced copy
3. ~/.claude/skills/dev-debrief/memory-harvest.md — new companion file (~40 lines)
4. ~/.claude/skills/dev-debrief/SKILL.md — Step 4.7 addition (~3 lines)
5. ~/.claude/skills/dev-debrief/executor-prompt.md — memory-harvest step addition
6. ~/.claude/skills/dev-plan/SKILL.md — Step 0.6 spec-existence check (~5 lines) + Step 6 thinking-protocol T0 (~5 lines)
7. tests/test_templates.sh — soul ceiling assertion (<=60 lines)

## Exit Criteria (machine-checkable)

- [ ] grep -qi 'Voice.*presence' templates/.claude/rules/nana-soul.md
- [ ] [ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ]
- [ ] diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md
- [ ] test -f ~/.claude/skills/dev-debrief/memory-harvest.md
- [ ] grep -qi 'memory.harvest\|memory-harvest' ~/.claude/skills/dev-debrief/SKILL.md
- [ ] grep -qi 'memory_store' ~/.claude/skills/dev-debrief/memory-harvest.md
- [ ] grep -qi 'memory.harvest\|memory-harvest' ~/.claude/skills/dev-debrief/executor-prompt.md
- [ ] grep -qi 'spec.*exist\|spec.*check\|spec.*found' ~/.claude/skills/dev-plan/SKILL.md
- [ ] grep -qi 'thinking.protocol\|challenge.*frame' ~/.claude/skills/dev-plan/SKILL.md
- [ ] bash tests/test_templates.sh (includes soul ceiling + budget regression)
- [ ] make test (full suite, 61+ tests)

## Checkpoints

- After soul compression (before adding new section): verify line count dropped by >=3, existing content reads coherently. If compression damages meaning: STOP, find alternative lines to compress.
- After Voice & presence section drafted: verify Rust litmus test on each bullet. If any bullet is Jake-specific rather than universal: move it to nana-personal.md instead.
- After memory-harvest companion drafted: verify it doesn't overlap with dev-debrief Step 5 (decision extraction). If overlap detected: refactor to reference Step 5 output rather than re-extracting.
- After dev-plan Step 0.6 added: verify it correctly skips for lite ceremony and fires for standard. If spec routing creates a circular dependency (spec pre-check routes to dev-plan, dev-plan pre-check routes to spec): add an explicit "spec pre-check is authoritative" tiebreaker.

## Assumptions

- nana.instructions.md frontmatter is exactly 4 lines (verified by existing tail -n +5 pattern in tests). If changed: update the tail offset in both exit criteria and tests.
- Dev-debrief executor reads companion files via "Read companion" instructions in SKILL.md. If executor doesn't support dynamic companion reads: embed the memory-harvest logic directly in executor-prompt.md instead of a separate file.
- The 3 compression targets ("sycophantic agreement," "writing more code," "over-broad exception handling") can be removed because their meaning is already expressed in other sections (verified by spec reviewer). If implementation shows they carry unique meaning: find alternative compression targets or accept slightly larger soul (<=60 still).
- Dev-plan SKILL.md step numbering is sequential (0, 0.5, 1, 2...). Adding Step 0.6 fits between 0.5 (ceremony detection) and 1 (load wiki state). If numbering convention forbids fractional steps: renumber as needed.
