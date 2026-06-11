# Edge-Screener Evidence Sessions — Phase 89 (VALID fixture)

Schema: eval/dogfood-round/pre-registration.md "## Session evidence schema".
Reachability fields are orchestrator-computed from transcripts, never self-reported.

### Session 1 — 2026-06-12 14:00–15:10Z — Phase-10 dev-plan planning
driver: headless-maintainer-agent
agenda: edge-screener Phase-10 planning (its own roadmap)
prompt: archived at evidence/prompts/session-1.txt (measurement-blind)
snapshots: db_rows before=11 after=12; enforcement_log_lines before=40 after=46

| hook | event | timestamp | judgment (helped/neutral/noise) |
|------|-------|-----------|---------------------------------|
| session-start.sh | SessionStart | 2026-06-12T14:00:05Z | helped |
| enforce-spec.sh | PreToolUse | 2026-06-12T14:12:00Z | neutral |
| session-stop.sh | Stop | 2026-06-12T15:09:58Z | neutral |

| memory-call | class (hook-prompted/rules-instructed/spontaneous) | timestamp | evidence (rule that classified it) |
| memory_search | rules-instructed | 2026-06-12T14:00:30Z | first memory call before any file-modifying tool |

reachability: compaction=n planning_or_recovery_decision=y pinned_decision_in_scope=y

### Session 2 — 2026-06-12 16:00–17:05Z — screener rule fixture refactor
driver: headless-maintainer-agent
agenda: edge-screener fixture refactor (its own backlog)
prompt: archived at evidence/prompts/session-2.txt (measurement-blind)
snapshots: db_rows before=12 after=12; enforcement_log_lines before=46 after=51

| hook | event | timestamp | judgment (helped/neutral/noise) |
|------|-------|-----------|---------------------------------|
| session-start.sh | SessionStart | 2026-06-12T16:00:04Z | neutral |
| block-dangerous-bash.sh | PreToolUse | 2026-06-12T16:21:10Z | helped |
| session-stop.sh | Stop | 2026-06-12T17:04:50Z | neutral |

| memory-call | class (hook-prompted/rules-instructed/spontaneous) | timestamp | evidence (rule that classified it) |
| memory_search | hook-prompted | 2026-06-12T16:00:40Z | nudge string precedes call in transcript |

reachability: compaction=n planning_or_recovery_decision=n pinned_decision_in_scope=n

### Session 3 — 2026-06-13 09:30–10:40Z — Phase-10 task implementation
driver: jake-interactive
agenda: edge-screener Phase-10 task 1 (its own plan)
prompt: archived at evidence/prompts/session-3.txt (measurement-blind)
snapshots: db_rows before=12 after=13; enforcement_log_lines before=51 after=58

| hook | event | timestamp | judgment (helped/neutral/noise) |
|------|-------|-----------|---------------------------------|
| session-start.sh | SessionStart | 2026-06-13T09:30:03Z | helped |
| enforce-loop.sh | PreToolUse | 2026-06-13T09:45:22Z | neutral |
| session-stop.sh | Stop | 2026-06-13T10:39:41Z | neutral |

| memory-call | class (hook-prompted/rules-instructed/spontaneous) | timestamp | evidence (rule that classified it) |
| memory_store | spontaneous | 2026-06-13T10:20:00Z | no preceding nudge; not a first-call search |

reachability: compaction=y planning_or_recovery_decision=y pinned_decision_in_scope=y
