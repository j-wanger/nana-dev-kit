# Phase 84 — Capture Diagnosis (T2)

Real PostToolUse events captured 2026-06-09 via a temporarily instrumented runtime copy of
`~/.claude/hooks/detect-loop.sh` (the ghost global registration — restored byte-identical
afterwards, md5 `af644481d304cf8487a707ec2bc29857` matching the template). Fixtures under
`tests/fixtures/real-events/` are byte-for-byte unmodified captures with `.provenance` sidecars.

## Platform findings

1. **No exit code anywhere in the event.** `tool_response` keys for a Bash event are exactly
   `interrupted, isImage, noOutputExpected, stderr, stdout`. There is no `exit_code` at the top
   level (where both hooks read it) nor inside `tool_response`.
2. **PostToolUse does not fire for failing commands.** Two failing probes (`bash -c 'echo boom >&2; exit 7'`,
   `false`) produced NO capture, while every interleaved successful command was captured
   (9 events total during the window). The hook layer never sees a failing Bash call.
3. **Ghost registrations fire machine-wide, beyond kit-consuming roots.** The capture window
   collected events from concurrent Claude Code sessions in OTHER projects (e.g.
   `/Users/jwang/signal-watch` — not a discovered kit root). Global hook registrations fire in
   every project regardless of kit adoption. (T4a checkpoint evidence.)

## Verdicts

hook: post-commit.sh
fixture: tests/fixtures/real-events/post-commit-git-commit.json
branch: redesign
evidence: (.tool_response | has("exit_code") | not) and (.tool_input | has("command")) and (.tool_input.command | test("git\\b.*\\bcommit\\b"))
note: the capture's command is `git -c user.email=… -c user.name=… commit` — NO literal
"git commit" substring, so the hook's current `*"git commit"*` glob misses it. The real fixture
organically exhibits the flag-interleaved matcher edge (T3's parser-edge fixture class).
rationale: The exit-code dependency is unsatisfiable, but the needed signal exists by
construction — PostToolUse fires ONLY on successful tool calls (finding 2), so event arrival is
the success signal. Redesign: canonical jq parse of `.tool_input.command`, drop the exit-code
gate, keep a git-state confirmation (HEAD exists / commit recency) to guard compound commands
like `git commit -m x || true` that succeed overall while the commit failed (the reviewer's
false-positive class).

hook: detect-loop.sh
fixture: tests/fixtures/real-events/detect-loop-success-event.json
branch: upstream
evidence: .tool_response | keys == ["interrupted","isImage","noOutputExpected","stderr","stdout"]
rationale: The hook's design — warn after 3 CONSECUTIVE FAILING commands — is structurally
unimplementable hook-side: no exit code in the event (finding 1) AND no event at all on failure
(finding 2), so the counter can never increment on the platform as shipped. A stderr-nonempty
heuristic is not failure (successful events legitimately carry stderr, e.g. "Shell cwd was
reset"). Pre/Post pairing via tool_use_id would need cross-event state — complexity not earned
by an advisory hook. Per the pre-declared branch menu: platform defect filed (see below),
disable-at-boundary routed to the T4a checkpoint, pinned repro (repro-runs.log line 52)
criterion becomes N/A-upstream. The HOME-only marker defect (line 56 class) still gets fixed in
the shared marker-resolution change where applicable.

## Platform defect filing (upstream)

PostToolUse delivers no failure signal for Bash: no exit-code field in `tool_response`, and no
event delivery at all for failing tool calls. Any hook whose contract depends on observing
failures (detect-loop's consecutive-failure counter) cannot fire. Filed as a deferred Blocker at
T5 close-out; re-trigger: a platform release adding failure events or an exit-code field.
