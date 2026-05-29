# Quarantine

Components removed from the install path but preserved (reversible) rather than hard-deleted.
Each entry was classified DEADWEIGHT/orphaned by the Phase 63 harness assessment with affirmative evidence.

- **wiki-consolidate/** (quarantined Phase 63, 2026-05-29) — consumes a `wiki/episodic/` tier that NO nana-dev-kit skill produces (episodic writes are attributed to external Nanaclaw/Qwen agents; the tier is declared "legacy — not actively fed"). Router-orphaned: 0 references in `knowledge-wiki/SKILL.md`'s dispatch table vs 2-6 for every sibling wiki-* skill. Restore by moving back under `templates/.claude/skills/` and re-adding to `modules.json` + `MANIFEST` if a producer for the episodic tier is reintroduced.
