---
parent: dev-debrief
referenced_at: "Step 19"
---

# dev-debrief — Active Knowledge Transition Logic

Companion to `SKILL.md` Step 19. Handle `.claude/rules/active-knowledge.md` based on phase state. Read `~/.claude/skills/dev-wiki/active-knowledge-spec.md` for the specification.

## If phase changed this session (phase transitioned to a new phase, or phase marked completed)

1. **Carry forward all entries.** Read `.claude/rules/active-knowledge.md`. Convert every distilled proposition to a working-knowledge entry.
   - Example: `"- Fan-out topology: reviewers run in parallel"` → `- [uses: 1] Fan-out topology: reviewers run in parallel with disjoint scopes` / `source: [[wiki:subagent-delegation-patterns]] | activated: 2026-04-14`
2. **Write to working-knowledge.md** using the format from `~/.claude/skills/dev-wiki/working-knowledge-spec.md`. If the file doesn't exist, create it with the header from that spec. Just APPEND the carried-forward entries — content-dedup, the 100-entry cap, and ordering are enforced deterministically by the session-start curator (see that spec); do NOT hand-dedup or hand-prune here. **Keep each entry TERSE (~1-2 sentences + a `[[pointer]]`) — this file loads into every session's context, so detail belongs in the dev-wiki, not here; the curator warns above ~1500 chars/entry (Phase 79).**
3. Delete `.claude/rules/active-knowledge.md` (`rm -f`).
4. Report: "Active knowledge cleared. N facts carried forward to working knowledge."

## If same phase (no phase transition)

No action needed. Active knowledge is not updated mid-phase.

## Skip condition

If no knowledge wiki and no active-knowledge.md file, skip entirely.
