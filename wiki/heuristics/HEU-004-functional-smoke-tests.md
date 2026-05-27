---
id: HEU-004
trigger: "verifying that a registered or configured component actually works"
domain: testing
source_phase: 38
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Functional Smoke Tests Over Structural Tests

## When this applies
A component is registered in configuration (config file, settings, manifest)
and you need to verify it works — not just that it exists.

## Always
- For every registered component, write at least one test that pipes real input and checks output
- Test the happy path end-to-end: create input → invoke component → assert output
- Treat "file exists" and "JSON is valid" as Tier 0 (necessary but insufficient)
- Treat "pipe input, check output" as Tier 1 (the actual verification)

## Never
- Rely solely on file-existence checks (`test -f`) as proof a component works
- Trust that registration in a config file means the component functions
- Skip functional tests because "it's just a config change"

## Why
Structural tests (file exists, JSON parses, key present) catch registration
errors but miss integration failures. A component can be registered, present
on disk, syntactically valid, and completely non-functional. Only functional
tests — feeding real input and checking real output — catch this class of bug.

## Anti-pattern
"The file exists and the config is valid, so it must work" → Four silent
breakages persisted for 8-33 phases because tests only checked structure.
The components were registered, present, but broken at runtime. A single
`echo '{}' | bash hook.sh; check $?` would have caught each one immediately.

## Source
Phase 38: Four silent breakages discovered. Phase 40: Functional smoke
invariant codified as a rule — every component registered in settings.json
or install.sh must have at least one functional test.
