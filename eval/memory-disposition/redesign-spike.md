# enforce-memory redesign feasibility spike (Phase 95 T2)

SPIKE: PASS

**The redesign is mechanically feasible.** A PreToolUse hook CAN deterministically assert a real prior
in-session `memory_search` by reading the transcript, replacing the gameable agent-touched marker
(det-vs-LLM Principle 2: assert the artifact, not the narration). Feeds the T3 checkpoint. Probe:
`eval/memory-disposition/spike-probe.sh` (the candidate redesigned-hook core).

## What PASS rests on (verified)

- **PreToolUse delivers `transcript_path`.** Confirmed authoritative (claude-code hooks docs:
  `code.claude.com/docs/en/hooks` — PreToolUse stdin includes `session_id`, `transcript_path`, `cwd`,
  `hook_event_name`, `tool_name`, `tool_input`). PreToolUse hook execution timeout defaults to 600s.
- **The probe works end-to-end:** transcript WITH a real assistant `tool_use` `memory_search` → allow
  (exit 0); transcript WITHOUT (only a deferred-tool-catalog mention) → block (exit 2) — the catalog can NOT
  spuriously satisfy it (JSON `type==assistant`+`tool_use` gate, never grep); no `transcript_path` → fail-open
  allow (exit 0).
- **Latency is a non-issue:** 64ms on the largest kit transcript (4.1MB / 1956 lines), with a
  `"tool_use" not in line` pre-filter keeping the scan linear — three orders of magnitude under the 600s
  timeout. Flush timing holds: a COMPLETED prior tool call's `tool_use` is always on disk before the next
  tool's PreToolUse fires (verified by the adversarial review: 0 genuine inversions across 5,673 tool_use
  blocks) — the earlier `memory_search` is reliably readable.

## What the adversarial review found — caveats a sound redesign MUST address

1. **Freshness: `sessionId` is STABLE across `--resume`/`--continue`** (a >1-day transcript keeps ONE
   sessionId). So scoping "this session" by `session_id` does NOT enforce freshness — a `memory_search` from
   days ago in the same resumed session would pass forever (18/90 transcripts span >1 day). The current
   marker is actually BETTER on this axis: `session-start.sh` clears `.claude/.memory-consulted` per session
   start. **Recommended redesign shape:** keep the marker as a freshness ANCHOR (its mtime = last
   session-start), and have the hook assert a real `memory_search` event in the transcript with
   `timestamp >= marker_mtime`. This combines freshness (marker-clear) WITH a real-event assertion (transcript
   scan) — fixing BOTH the stale-pass AND the ritual marker-touch.
2. **It remains a fail-open relevance NUDGE, not a hard control.** Fail-open (allow on any infra failure) is
   correct for a relevance gate, but it means the bar is "≥1 real `memory_search` since session start" — one
   throwaway `memory_search("x")` satisfies it. The redesign HARDENS the gameability (a real search must
   happen, not a bare file-touch) but does not make it ungameble. That is an acceptable nudge, not a
   guarantee — frame it honestly at the checkpoint.

## Net for the T3 decision

- `redesign` is on the menu (SPIKE: PASS). The genuine improvement over `keep`: it kills the pure-ritual
  marker-touch (the ~45% of episodes where NO real search happened still passed the marker gate) by requiring
  a real event since session start.
- The improvement is REAL but MODEST: it does not make the gate ungameble (one search suffices), and it adds
  hook code + a transcript scan on every gated write. Weigh against `keep` (cheap, already ~55% value) and
  `retire` (the always-loaded nana-soul rules already instruct session-start `memory_search`; the hook's
  marginal value over rules-alone is unisolated — Phase 94 is confounded by domain).
