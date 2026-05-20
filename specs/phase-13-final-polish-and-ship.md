# Spec: Phase 13 — Final Polish & Ship

## Objective

Apply the 3 reviewer-recommended changes (thinking heuristics, personal calibration, SKILL.md ceiling) and ship v0.3.0 as the first release ready for corporate project testing.

## Context

External review across Phases 10-12 assessed the kit as "ready for the corporate project test" with 3 remaining items. Two are 2-4 line edits to existing files (soul thinking heuristics H8+H9, personal profile calibration). One is a policy decision (raise SKILL.md advisory ceiling). The kit has 12 completed phases, 63 tests, 239/300 instruction budget, and full decision traceability. This is a polish-and-ship phase, not a feature phase.

## Scope

### In scope
- nana-soul.md: add H8 (informed search) and H9 (lateral scope expansion) to Thinking protocol section (+2 lines, 57->59/60)
- nana.instructions.md: sync to match soul (byte-exact minus YAML frontmatter)
- nana-personal.md: expand from 3->7 lines with thinking calibration
- self-check-checklist.md: raise complex-orchestration SKILL.md ceiling from 250 to 350
- VERSION: bump to 0.3.0
- docs/report.html, docs/workflow.html: regenerate
- tests: verify all pass, budget regression at new totals

### Out of scope
- New skills or features (deferred to post-corporate-test feedback)
- SKILL.md refactoring (ceiling raise acknowledges the debt; refactoring is future work)
- install.sh changes (no new files to copy — personal profile is already copied)
- Session-length awareness, memory scoring automation (deferred)
- README.md rewrite (spot-check only)

## Verbatim Additions

### H8 and H9 (add to Thinking protocol section in nana-soul.md):
```
- Before searching, name what you already know — then construct targeted queries from it, not generic topic keywords.
- Check adjacent domains: upstream causes, downstream effects, parallel developments.
```

### Personal calibration (replace nana-personal.md content):
```markdown
# Who you're working with

Jake Wang. Software engineer, AML/financial crime domain.
Terse, technical, no fluff. Expects pushback on weak ideas, not agreement.
When he provides a pre-written plan, follow it — don't re-derive his decisions.

Jake's thinking pattern: cost-of-error analysis. He allocates attention proportional
to the cost of being wrong. He reads constraints as signals about the person
(risk appetite, time, expertise), not just as problem parameters. He will almost
never accept a problem framing at face value — expect him to challenge it.
```

## Approach

Sequential: (1) add 2 heuristic lines to soul Thinking protocol, sync nana.instructions.md, (2) replace nana-personal.md with expanded version, (3) update self-check-checklist.md complex-orchestration ceiling from 250 to 350, (4) bump VERSION to 0.3.0, regenerate reports, (5) verify all tests, commit, tag v0.3.0, push.

## Constraints (CRITICAL)

- Soul must stay <=60 lines after H8+H9: currently 57, adding 2 -> 59. No compression needed.
- Instruction budget must stay <=300 lines: currently 239, adding 2 (soul) + 4 (personal) -> 245/300.
- nana.instructions.md must byte-match soul minus 4-line YAML frontmatter: existing diff test enforces.
- H8 and H9 wording must match the verbatim text above exactly — calibrated across 3 reviews.
- Personal profile additions must be Jake-specific (NOT universal) — inverse of Rust litmus test.
- Version tag v0.3.0 must be annotated (consistent with v0.1.0 and v0.2.0 convention).
- SKILL.md ceiling change targets self-check-checklist.md line 25 (not size-budgets.md, which has no SKILL.md row).

## Deliverables

1. templates/.claude/rules/nana-soul.md — 59/60 lines (+H8, +H9)
2. templates/.github/instructions/nana.instructions.md — synced
3. templates/.claude/rules/nana-personal.md — 7 lines (calibration added)
4. ~/.claude/skills/dev-plan/self-check-checklist.md — complex-orchestration ceiling 250->350
5. VERSION — 0.3.0
6. docs/report.html, docs/workflow.html — regenerated
7. Git tag v0.3.0

## Exit Criteria (machine-checkable)

- [ ] grep -qi 'targeted queries' templates/.claude/rules/nana-soul.md
- [ ] grep -qi 'adjacent domains' templates/.claude/rules/nana-soul.md
- [ ] [ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ]
- [ ] diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md
- [ ] grep -qi 'cost-of-error\|cost.of.error' templates/.claude/rules/nana-personal.md
- [ ] [ $(wc -l < templates/.claude/rules/nana-personal.md) -ge 7 ]
- [ ] grep -q '350' ~/.claude/skills/dev-plan/self-check-checklist.md
- [ ] grep -qx '0.3.0' VERSION
- [ ] make test (63+ tests pass)
- [ ] git tag -l 'v0.3.0' | grep -q 'v0.3.0'

## Checkpoints

- After soul edit: verify line count is exactly 59. If 60+: something was miscounted — STOP.
- After personal profile edit: verify each new line is Jake-specific. If any passes Rust litmus test: move to soul.

## Assumptions

- nana.instructions.md frontmatter is exactly 4 lines. If changed: update tail offset.
- self-check-checklist.md contains the string "complex orchestration <=250" on line 25. If wording differs: adapt the edit to match.
- README.md needs no major changes at v0.3.0. If gaps found: add as discovered task.
