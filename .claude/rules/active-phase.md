# Active Phase Context

Phase: 57 - Hook Consolidation and Enforcement Activation
Status: COMPLETED (5/5 tasks, delivery accepted, committed)
Objective: Reconcile the three disagreeing hook-registration sources into one scope-tagged source of truth in modules.json, generate the per-project template from it, make the enforce opt-in marker project-reachable, and verify enforce-spec actually fires (exit 2) in a fresh scaffold. Fix 1 of the Phase 57+ harness-activation roadmap.

Scope:
- modules.json
- scripts/register-settings.py
- templates/.claude/settings.json (generated artifact)
- templates/.claude/hooks/enforce-spec.sh, enforce-memory.sh, enforce-loop.sh
- templates/.claude/enforce (shipped marker)
- install.sh
- Makefile
- tests/

Key constraints:
- Backward compatible: existing global ~/.claude registrations + marker keep working (marker logic is project OR global, additive). No destructive global migration (upsert-only).
- Single source of truth: one canonical hooks list in modules.json; template is generated, never hand-edited; drift test in make test.
- Fail-open preserved: marker change must not make any fail-open hook block where it previously passed (no .dev-wiki, no marker, no jq → still exit 0).
- Verify firing, not presence: done = scaffold-from-template makes enforce-spec exit 2 under firing conditions, in an empty HOME.
- Out of scope: flipping the KIT itself to self-enforcement (self-lockout risk); Fixes 2-5.

Exit criteria:
- modules.json has one scope-tagged hooks array (every entry project|global)
- generated template registers enforce-spec/loop/memory
- `make template && git diff --quiet -- templates/.claude/settings.json` (deterministic, in sync)
- enforce-spec honors project marker + marker shipped in template
- tests/test_settings_template.sh firing test passes (enforce-spec exit 2 in scaffold)
- make test green

Abort: if Claude Code double-fires registered hooks harmfully (not merely cosmetically), STOP and reconsider scope project-only + kit migration. If the firing test only passes with the global marker present, the marker fix is incomplete — fix before declaring done.

Gates:
- [x] Direction confirmed by user (approach approved)
- [x] Delivery accepted (post-implementation report)
