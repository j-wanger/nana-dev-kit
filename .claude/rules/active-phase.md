# Active Phase Context

Phase: 28 - DX Discoverability
Status: Planning complete, implementation ready
Objective: Normalize hook messages to [nana:<hook>] prefix across 11 hooks, add install.sh --status, enrich MANIFEST with skill descriptions, add session-start [nana:kit] summary line.

Scope: templates/.claude/hooks/*.sh, install.sh, templates/.claude/skills/MANIFEST, eval/corpus/, tests/
Key constraints: [dev-wiki:post-commit] kept as semantic trigger (do not rename). MANIFEST descriptions are additive (comment section after checksums). Eval assertions use substring matching.
Exit criteria: All hooks prefixed, --status works, MANIFEST enriched, [nana:kit] line, make test + make eval pass.
Abort: if blocked >3 attempts on any task, ask user: skip or abort.

Tests: 163 passing. Eval: 43/43.

Gates: [x] spec [x] approach [x] plan-review [x] tasks [x] memory: session-start search done
