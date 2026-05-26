<!-- nana:approved 2026-05-26 -->
# Spec: Phase 43 — Unified Init & Activation Gap

## Objective

Rename `/init` to `/nana-init` (resolving name collision with Claude Code's built-in `/init`) and expand it to bootstrap the full Nana experience — language scaffold, dev-wiki lifecycle, optional knowledge wiki — closing the activation gap where users currently get only ~30% of the kit's capabilities.

## Context

After running `install.sh` (once per machine), users run `/init` per project. But `/init` only detects the language and routes to `/py-init` or `/ts-init`. Dev-wiki lifecycle (`/dev-init`), knowledge wiki (`/wiki-init`), and session continuity require separate manual invocations that most users don't know about. The session-start hook degrades significantly without `.dev-wiki/` — showing only basic kit status instead of phase context, task tracking, crash recovery, and memory search guidance. Separately, Claude Code now has a built-in `/init` command for claude.me initialization, causing a naming collision that breaks the skill's slash-command routing.

## Scope

### In scope
- Rename `templates/.claude/skills/init/` directory to `nana-init/`
- Update `modules.json` skill reference from `"init"` to `"nana-init"`
- Update SKILL.md: new triggers, expand orchestration to include dev-wiki + wiki-init dispatch
- Update install.sh references and post-install guidance text
- Update MANIFEST (regenerate with new path + checksum)
- Update README.md (getting started, skill reference)
- Update test_install.sh assertion at line ~279 (`skills/init/SKILL.md` → `skills/nana-init/SKILL.md`)
- Update test_templates.sh assertions at lines ~700-714 (init SKILL.md content checks, MANIFEST `# init:` description)
- Update _ARCHITECTURE.md directory layout reference
- Per-component state detection: check each subsystem (language scaffold, dev-wiki, knowledge-wiki) independently before dispatching

### Out of scope
- Changes to `/dev-init` or `/wiki-init` internal logic (they work fine, nana-init dispatches to them)
- Changes to `/py-init` or `/ts-init` internal logic
- Automatic maintenance features (wiki re-index, auto-debrief) — separate phase
- Changes to session-start.sh behavior
- Changes to enforcement markers (already handled by install.sh)
- Working-knowledge entry updates (handled by dev-plan, not this spec)

## Approach

Two-part phase: (1) atomic rename of `init/` → `nana-init/` across all references, (2) expand `nana-init/SKILL.md` from a 44-line language router into a ~80-120 line multi-stage orchestrator. Orchestration order: detect all component states first (language markers, `.dev-wiki/`, `wiki/`), then run steps in sequence: language scaffold → dev-wiki → knowledge wiki. Each step is independently skippable. Language scaffold: if markers present, route to py-init/ts-init; if both (polyglot), ask; if neither, ask or skip. Dev-wiki: if `.dev-wiki/` absent, dispatch `Skill(skill="dev-init")`; if present, skip with note. Knowledge wiki: ask "Set up a knowledge wiki? (recommended for domain-heavy work)"; if yes dispatch `Skill(skill="wiki-init")`; if no, skip. If `Skill()` dispatch is unavailable, fall back to advisory text listing the commands. The orchestrator delegates all real work to existing skills — no logic duplication.

## Constraints (CRITICAL)

- Rename must be atomic across all 7+ files: directory name, modules.json, install.sh, MANIFEST, README, tests, _ARCHITECTURE.md — prevents divergence between installed path and skill resolution (Claude Code resolves skills by directory name under `~/.claude/skills/`)
- SKILL.md triggers must be tightened to `/nana-init` only — removes natural-language triggers ("set up a project", "scaffold this project") that could collide with Claude's built-in `/init` phrase matching
- Per-component state detection before dispatch: check `.dev-wiki/` exists (skip dev-init), check `wiki/` exists (skip wiki-init), check language markers (route or skip) — prevents double-initialization when running on partially bootstrapped projects
- Language scaffold must be skippable: if the user only wants lifecycle tracking, they can decline scaffolding — prevents polyglot repos from blocking the entire flow on a language choice prompt
- Wiki-init declining must cleanly fall through to completion message — prevents interview abandonment from aborting the entire nana-init flow
- SKILL.md must remain ≤120 lines (it's a router/orchestrator, not a complex skill) — prevents scope creep into reimplementing sub-skill logic

## Deliverables

1. `templates/.claude/skills/nana-init/SKILL.md` — expanded orchestrator (~80-120 lines)
2. Updated `modules.json` — `"nana-init"` in core skills list
3. Updated `install.sh` — references and post-install guidance
4. Updated `templates/.claude/skills/MANIFEST` — new path + checksum
5. Updated `README.md` — getting started section, skill reference
6. Updated `tests/test_install.sh` — skill directory assertions
7. Updated `tests/test_templates.sh` — SKILL.md content assertions
8. Updated `.dev-wiki/_ARCHITECTURE.md` — directory layout

## Exit Criteria (machine-checkable)

- [ ] `test -d templates/.claude/skills/nana-init && test ! -d templates/.claude/skills/init`
- [ ] `jq -e '[.modules[].skills[] | select(. == "nana-init")] | length == 1' modules.json && jq -e '[.modules[].skills[] | select(. == "init")] | length == 0' modules.json`
- [ ] `grep -q 'nana-init' install.sh && ! grep -qE '/init[^i]|/init"' install.sh`
- [ ] `grep -q 'nana-init/SKILL.md' templates/.claude/skills/MANIFEST && grep -q '# nana-init:' templates/.claude/skills/MANIFEST`
- [ ] `grep -q 'nana-init' README.md`
- [ ] `[ $(wc -l < templates/.claude/skills/nana-init/SKILL.md) -le 120 ]`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After rename (tasks 1-2): verify `make test` and `make eval` still pass before expanding SKILL.md logic — catches rename breakage early
- After SKILL.md expansion (task 3): verify the orchestration flow reads correctly and sub-skill dispatch paths are unambiguous

## Assumptions

- Claude Code resolves skill slash commands by matching the directory name under `~/.claude/skills/`. If false: the rename approach breaks; investigate Claude Code skill resolution mechanism first.
- `/dev-init` and `/wiki-init` are safe to invoke via `Skill()` dispatch from within another skill. If false: nana-init falls back to a "Next steps" advisory listing the commands.
- The built-in `/init` conflict is real and user-facing. If false: still rename for clarity (nana-init is more discoverable than generic init), but lower priority.
