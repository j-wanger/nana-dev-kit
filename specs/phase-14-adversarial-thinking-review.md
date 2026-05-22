# Spec: Adversarial Thinking & Review

## Objective

Make the thinking protocol (T0) and spec constraint generation genuinely adversarial — forcing specific, falsifiable output rather than confirmatory rubber-stamping.

## Context

Phases 12-13 added T0 thinking protocol checks to dev-plan Step 6 and the /spec skill. In practice, every T0 execution produces "I challenged it and it's fine" — the agent treats user input as ground truth and confirms rather than challenges. Similarly, the Tier 1 spec reviewer evaluates constraints the agent chose to include but cannot surface constraints the agent missed entirely. Both problems share a root cause: the agent cannot adversarially review its own work when it holds full context and strong priors from prior steps.

User observation: "you are operating on the assumption that the user response is 100% accurate and informed, which defeats the purpose of the thinking protocol." And: "in practice you are writing your own grading rubric."

## Scope

### In scope

- Rewrite dev-plan Step 6 T0 to force specific, non-vacuous output (named assumptions, what breaks if wrong)
- Add adversarial constraint generation step to /spec skill (clean-context subagent produces constraints independently, before the spec author drafts)
- New companion file: `templates/.claude/skills/spec/adversarial-constraints-prompt.md`
- Update install.sh to copy the new companion file
- Tests for new files and install coverage

### Out of scope

- Soul wording changes (59/60 lines, no room; T0 fix belongs in skill files not identity)
- Dev-debrief or approach-reviewer changes (approach reviewer already uses clean context)
- /spec skill registration or routing issues (separate bug, not blocking)
- Changing the Tier 1 spec reviewer (it reviews what it receives — the fix is upstream, in what gets generated)

## Approach

Two complementary fixes targeting the same root cause from different angles:

1. **T0 wording fix (dev-plan Step 6):** Replace abstract checks ("challenge the frame") with output-format requirements that reject vacuous compliance. Specifically: require naming the weakest assumption in the approach and articulating what breaks if it's wrong. Add a structural non-vacuity gate — if the T0 output doesn't name a concrete assumption, the check has failed and must be re-done.

2. **Adversarial constraint generation (spec skill):** Insert a new Step 2.5 between "Apply Thinking Protocol" and "Draft Spec." Dispatch a clean-context subagent with ONLY the objective and context sections — no conversation history, no accumulated priors. The subagent independently generates: constraints (what could go wrong), edge cases, and scope boundary risks. The spec author then incorporates or explicitly rejects each generated item with rationale before proceeding to draft.

## Constraints (CRITICAL)

- Soul budget frozen: do NOT modify nana-soul.md (59/60 lines). Prevents: unintended soul regression.
- Spec skill SKILL.md must stay ≤ 350 lines (complex orchestration ceiling). Prevents: unbounded skill growth.
- Adversarial subagent receives ONLY objective + context — not the full conversation or Steps 1-4 state. Prevents: the subagent inheriting the same priors that cause confirmatory behavior.
- T0 output-format changes must not break the existing dev-plan flow — T0 is inline output, not a blocking gate on execution. Prevents: planning lockup from overly strict format checks.
- New companion file must be copied by install.sh alongside existing spec files. Prevents: deployed kits missing the adversarial prompt.

## Deliverables

1. Updated `~/.claude/skills/dev-plan/SKILL.md` — T0 rewrite at Step 6 (~15 lines changed)
2. Updated `templates/.claude/skills/spec/SKILL.md` — new Step 2.5 (~20 lines added)
3. New `templates/.claude/skills/spec/adversarial-constraints-prompt.md` (~40-50 lines)
4. Updated `install.sh` — copy adversarial-constraints-prompt.md to ~/.claude/skills/spec/
5. Updated `tests/test_install.sh` — verify new file is copied
6. Updated `tests/test_templates.sh` — verify adversarial prompt exists

## Exit Criteria (machine-checkable)

- [ ] `grep -qi 'weakest.*assumption\|name.*assumption.*wrong\|what breaks' ~/.claude/skills/dev-plan/SKILL.md`
- [ ] `grep -qi 'adversarial\|independent.*constraint\|clean.context.*subagent' templates/.claude/skills/spec/SKILL.md`
- [ ] `test -f templates/.claude/skills/spec/adversarial-constraints-prompt.md`
- [ ] `grep -q 'adversarial' install.sh`
- [ ] `make test`
- [ ] `[ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ]`
- [ ] `[ $(wc -l < templates/.claude/skills/spec/SKILL.md) -le 350 ]`

## Checkpoints

- After T0 rewrite (task 1): report new wording before proceeding to spec skill changes
- If spec SKILL.md exceeds 130 lines after adversarial step: check against 350 ceiling, compress if approaching limit
- After install.sh update: run test suite before marking complete

## Assumptions

- The T0 problem is addressable via prompt wording — forcing output format can overcome confirmatory bias. If false: document the limitation, propose contrarian subagent as structural alternative for Phase 15.
- The spec skill can accommodate Step 2.5 within the 350-line ceiling (currently 113 lines — 237 lines of headroom). If false: extract Step 2.5 logic into the companion file, keep SKILL.md as orchestrator-only.
- install.sh's existing copy pattern for spec/ files can extend to one additional file without refactoring. If false: use a loop or glob pattern.
