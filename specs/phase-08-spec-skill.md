# Spec: Phase 8 — Spec Skill

## Objective

Create a portable `/spec` skill that produces structured contracts before execution, and integrate its template into `/dev-plan` so dev-wiki projects get the same rigor natively. Include an automatic spec review gate with dedicated subagent reviewers.

## Context

Every major failure in our project history traces to an under-specified contract: the trading wiki produced 1,406 paraphrases because "go through all raws" left the unit of work undefined; hours of Telegram silence because no progress reporting requirement existed; claim pipeline over-engineering because no exit gate demanded "demo ONE before building 8." Agents don't push back on bad specs — they execute reasonable interpretations of ambiguous contracts for hours. A spec skill that forces clarity before execution is the highest-ROI intervention.

### Current state (for post-compaction self-containment)

The existing `/dev-plan` skill produces phase articles with these sections: title, tags, scope, entry_criteria, exit_criteria, objective, approach, tasks summary. These cover 6 of the 9 spec template sections. The 3 sections `/dev-plan` currently lacks are: **Constraints** (safety rails preventing known failure modes), **Checkpoints** (when to pause and report), and **Assumptions** (what must be true — stop if violated).

The phase template lives at `~/.claude/skills/dev-wiki/phase-template.md`. The dev-plan Step 6 (propose approach) is in `~/.claude/skills/dev-plan/SKILL.md` under `### Step 6: Propose Approach`.

The SKILL.md frontmatter format is: `---\nname: <kebab-case>\ndescription: <trigger description>\n---`

Dev-wiki detection: if `.dev-wiki/_CURRENT_STATE.md` exists and `.dev-wiki/tasks.md` contains an uncompleted `- [ ]` task, an active phase is in progress — suggest `/dev-plan` instead.

## Scope

### In scope
- `templates/.claude/skills/spec/SKILL.md` — the skill file (≤120 lines)
- `templates/.claude/skills/spec/spec-reviewer-prompt.md` — spec quality reviewer prompt (≤80 lines)
- `~/.claude/skills/dev-wiki/phase-template.md` — add 3 sections: `## Constraints`, `## Checkpoints`, `## Assumptions` (each as optional H2 with template content)
- `~/.claude/skills/dev-plan/SKILL.md` — add note at Step 6 that the approach should cover constraints, checkpoints, and assumptions when present
- `install.sh` — add `cp` for spec/ skill directory
- `tests/test_install.sh` — add `assert_file_exists` for `~/.claude/skills/spec/SKILL.md`
- `tests/test_templates.sh` — add assertions for spec skill key sections
- `README.md` — add `/spec` to "After scaffolding" list

### Out of scope
- Changes to dev-plan orchestrator flow (Step ordering, subagent dispatch)
- Changes to nana-soul.md or AGENTS.md (instruction budget unchanged)
- Spec execution/enforcement at runtime
- Spec versioning or diff tracking
- Portability test harness (manual verification is sufficient for v1)

## Approach

1. **SKILL.md** (~100-120 lines): 9-section template (Objective, Context, Scope in/out, Approach, Constraints CRITICAL, Deliverables, Exit Criteria, Checkpoints, Assumptions). Workflow: (a) detect dev-wiki — if active phase exists, emit "Use /dev-plan for dev-wiki projects" and STOP; (b) gather context — read project state files + `specs/` directory; (c) apply thinking protocol from nana-soul.md internally (no output artifact) — is this the right problem? are the constraints real? do we have enough information to spec this?; (d) draft spec from template; (e) **Tier 0: structural lint** (inline, scripted checks — see below); (f) fix any Tier 0 failures before proceeding; (g) **Tier 1: dispatch spec reviewer subagent**; (h) incorporate reviewer feedback; (i) present to user for approval (hard gate); (j) persist to `specs/<slug>.md`.

2. **Two-tier review gate** (learned from our own spec review sessions — Sonnet caught structural gaps at 6/10, Opus caught semantic gaps at 8/10):

   **Tier 0 — Structural lint** (inline, deterministic, no tokens spent):
   - All 9 H2 section headers present (`## Objective` through `## Assumptions`)
   - Scope has both `### In scope` and `### Out of scope` H3s
   - Constraints has ≥1 bullet point
   - Exit Criteria has ≥1 `- [ ]` item with backtick-fenced command
   - Checkpoints has ≥1 bullet
   - Assumptions has ≥1 bullet with fallback language ("if missing", "if false", "if unavailable")
   - No self-containment violations: flag "as discussed", "as we agreed", "established earlier"
   - Tier 0 is a gate — if it fails, fix before dispatching Tier 1

   **Tier 1 — Semantic review** (subagent, `spec-reviewer-prompt.md`):
   - 6 dimensions: ambiguity detection, constraint completeness, exit criteria verifiability (adversarial litmus + grep fragility), checkpoint proportionality, assumption explicitness, self-containment
   - Score 1-10, verdict accept/revise/reject
   - Pattern matches dev-plan's approach-reviewer-prompt.md

3. **spec-reviewer-prompt.md** (~60-80 lines): Tier 1 reviewer prompt. Evaluates the 6 semantic dimensions above. Outputs Score/Issues/Suggestions/Verdict format (same as dev-plan reviewers). SKILL.md parses verdict to route flow.

3. **Dev-wiki integration**: Add `## Constraints`, `## Checkpoints`, `## Assumptions` as optional sections to phase-template.md (each with template placeholder text). Add one-line note to dev-plan Step 6: "When proposing the approach, ensure it covers constraints (safety rails), checkpoints (pause points), and assumptions (stop-if-violated conditions)."

## Constraints (CRITICAL)

- **No split-brain**: MUST NOT create a separate spec file when `.dev-wiki/_CURRENT_STATE.md` exists AND `.dev-wiki/tasks.md` contains `- [ ]` (uncompleted task). Instead: emit "Active dev-wiki phase detected. Use `/dev-plan` to plan within the dev-wiki lifecycle." STOP.
- **Portability**: The skill MUST work with only SKILL.md + spec-reviewer-prompt.md present. No imports from dev-wiki, dev-plan, or other nana-dev-kit components. Context gathering uses `test -f` guards on all optional state files.
- **Line budgets**: SKILL.md ≤ 120 lines. spec-reviewer-prompt.md ≤ 80 lines. Not always-loaded (on-demand only), so no impact on the 300-line instruction budget.
- **Two-tier review gate is mandatory**: Every spec MUST pass Tier 0 structural lint (inline) AND Tier 1 semantic review (subagent) before user presentation. No `--skip-review` flag. If the Agent tool is unavailable for Tier 1, warn and present with disclaimer — but Tier 0 always runs.
- **Template, not prescription**: The 9-section template provides structure. The skill fills sections based on the task at hand — it does NOT require the user to answer 9 questions. The skill drafts, the user approves.

## Deliverables

1. `templates/.claude/skills/spec/SKILL.md` (new, ≤120 lines)
2. `templates/.claude/skills/spec/spec-reviewer-prompt.md` (new, ≤80 lines)
3. `~/.claude/skills/dev-wiki/phase-template.md` (updated: +3 optional sections)
4. `~/.claude/skills/dev-plan/SKILL.md` (updated: Step 6 one-line note)
5. `install.sh` (updated: copies spec/ directory)
6. `tests/test_install.sh` (updated: spec copy assertion)
7. `tests/test_templates.sh` (updated: spec content assertions)
8. `README.md` (updated: /spec mention)

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/spec/SKILL.md && [ $(wc -l < templates/.claude/skills/spec/SKILL.md) -le 120 ]`
- [ ] `test -f templates/.claude/skills/spec/spec-reviewer-prompt.md && [ $(wc -l < templates/.claude/skills/spec/spec-reviewer-prompt.md) -le 80 ]`
- [ ] `grep -qi 'constraints' templates/.claude/skills/spec/SKILL.md && grep -qi 'checkpoints' templates/.claude/skills/spec/SKILL.md && grep -qi 'assumptions' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -qi 'tier 0\|structural.*lint\|tier 1' templates/.claude/skills/spec/SKILL.md && grep -qi 'subagent\|reviewer' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -qi 'dev-wiki\|dev.plan' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -qi 'specs/' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -qi 'ambiguity\|constraint.*complete\|verifiab' templates/.claude/skills/spec/spec-reviewer-prompt.md`
- [ ] `grep -qi 'constraints' ~/.claude/skills/dev-wiki/phase-template.md && grep -qi 'checkpoints' ~/.claude/skills/dev-wiki/phase-template.md && grep -qi 'assumptions' ~/.claude/skills/dev-wiki/phase-template.md`
- [ ] `grep -qi 'constraints' ~/.claude/skills/dev-plan/SKILL.md && grep -qi 'checkpoints' ~/.claude/skills/dev-plan/SKILL.md && grep -qi 'assumptions' ~/.claude/skills/dev-plan/SKILL.md`
- [ ] `grep -q 'spec' install.sh && bash tests/test_install.sh`
- [ ] `bash tests/test_templates.sh && grep -qi 'spec' tests/test_templates.sh`
- [ ] `grep -qi '/spec' README.md && [ $(wc -l < README.md) -le 65 ]`

## Checkpoints

- After SKILL.md + reviewer prompt written: verify 9-section template present, thinking protocol referenced, review gate workflow complete, dev-wiki detection logic correct. Do NOT proceed to dev-wiki integration until skill file is solid.
- After phase-template.md + dev-plan updated: verify changes are non-breaking — grep existing phase articles to confirm they still parse correctly with the new optional sections.
- After install.sh updated: run `bash tests/test_install.sh` immediately. If fail: STOP and fix before test_templates.sh or README changes.
- If any assumption proves false (e.g., phase-template.md doesn't exist at expected path): STOP and surface to user.

## Assumptions

- `~/.claude/skills/dev-wiki/phase-template.md` exists at the expected path (installed by dev-wiki skill suite). If missing: skip the backport task, note in issues.
- `~/.claude/skills/dev-plan/SKILL.md` exists with a `### Step 6: Propose Approach` section. If section heading differs: adapt the grep, don't force-match.
- The `Agent` tool is available in the runtime for dispatching the spec reviewer subagent. If unavailable: the skill falls back to presenting the unreviewed spec with a `"⚠️ Spec reviewer unavailable"` warning.
- SKILL.md frontmatter format: `---\nname: spec\ndescription: ...\n---` — consistent with existing skills (py-init, py-lint, etc.).
- `specs/` directory will be created by the skill at runtime (`mkdir -p specs/`). Not pre-created by install.sh. Spec files are committed to the repo. Naming uses slug derived from objective. No collision handling in v1 — overwrite is acceptable.
- The spec reviewer subagent outputs Score/Issues/Suggestions/Verdict format (same as dev-plan's approach-reviewer). SKILL.md parses the verdict string to route flow.
