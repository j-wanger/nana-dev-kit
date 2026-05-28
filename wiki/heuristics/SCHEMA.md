# Heuristic Article Schema

Heuristics are reusable reasoning shortcuts with defined trigger conditions. Each captures a transferable pattern — it should apply beyond the project where it was discovered.

## YAML Frontmatter (required)

```yaml
---
id: HEU-NNN            # Sequential ID (HEU-001, HEU-002, ...)
trigger: "<situation>"  # Specific situation where this heuristic activates
domain: <domain>        # Domain tag (dev-tooling, testing, architecture, debugging, etc.)
source_phase: <N>       # Phase number where this pattern was discovered (or "multi")
confidence: high|medium # How well-validated is this pattern?
helpful: 0              # Counter: times this heuristic led to a good outcome
harmful: 0              # Counter: times this heuristic misled or was ignored to good effect
status: active          # active | deprecated | under-review | iron
---
```

## Required Sections

### ## When this applies
1-3 sentences describing the trigger situation in concrete terms.
Must be specific enough to match real situations but general enough to transfer.

**Bad:** "When using jq in bash hooks" (too project-specific)
**Good:** "When choosing a JSON parser for latency-critical shell scripts" (transferable)

### ## Always
Bulleted list of what to DO when this heuristic triggers.
Each bullet must be a concrete, verifiable action — not an aspiration.

### ## Never
Bulleted list of what to AVOID when this heuristic triggers.
Each bullet should name the specific wrong action and why it fails.

### ## Why
2-4 sentences explaining the underlying principle. This is what makes the heuristic transferable — readers who understand the WHY can adapt the ALWAYS/NEVER to novel situations.

### ## Anti-pattern
Name the most common wrong approach, then optionally add a structured table of additional failure modes.

**Primary anti-pattern (required):** Name the pattern, then "→" followed by why it breaks.

**Anti-pattern table (optional, 3-5 rows max):** For heuristics with multiple known failure modes, add a structured table after the primary anti-pattern paragraph:

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Name of the wrong approach | Concrete observable: metric, file pattern, phrase in rationale, or structural property | Specific mechanism of failure |

Each Detection Signal must be a concrete observable — answerable by "Could I write a grep/lint/eval check for this?" If not, rewrite it. Vague signals like "watch for complexity" are not allowed.

If a heuristic has no observed failure modes beyond the primary anti-pattern, omit the table or add: *"No additional anti-patterns observed — monitor."*

### ## Source
Which project phases, decisions, or incidents generated this heuristic.
Link to specific decision articles or working-knowledge entries where possible.

## Quality Criteria

A heuristic must pass all three:

1. **Trigger specificity (≥3/5):** Would an agent encountering a matching situation recognize this trigger? "When building software" fails. "When choosing between vendoring and forking a dependency" passes.

2. **Transferability (≥3/5):** Would this help on a web app, data pipeline, CLI tool, or other project type — not just the originating project? "Always use jq" fails. "Always match your parser to the runtime's input format" passes.

3. **Actionability (≥3/5):** Does the Always/Never section give clear, immediate guidance? "Be careful" fails. "Check concurrent write requirements before choosing SQLite" passes.

## Example

```markdown
---
id: HEU-001
trigger: "choosing a storage backend for a single-user developer tool"
domain: dev-tooling
source_phase: 4
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Embedded Databases for Single-User Tools

## When this applies
Choosing a storage backend for a developer tool, CLI, or agent component
that will be used by one process at a time.

## Always
- Default to SQLite (zero-deploy, single-file, no server)
- Check: concurrent writes needed? If no → SQLite
- Check: data > 10GB? If no → SQLite
- Check: need network access from multiple hosts? If no → SQLite

## Never
- Reach for Postgres/Redis/Mongo for single-user dev tools
- Add Docker/server dependencies to a tool's install path
- Let "the right tool for the job" override deployment complexity budget

## Why
The deployment complexity budget for dev tooling is near-zero. Users should
not install database servers to use a development tool. SQLite's single-file
model also makes debugging trivial — one .db file to inspect, copy, or delete.

## Anti-pattern
"Postgres is more robust" → True, but irrelevant when robustness isn't the
constraint. The constraint is: `pip install && run` must work without Docker,
without servers, without configuration. Every external dependency is a
potential install failure.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Redis for caching in a CLI tool | `docker` or `redis-server` in install steps | Adds server dependency to a tool that runs once per invocation |
| MongoDB for document storage | `pymongo` or `mongoose` in dependencies + single-user context | Network server for local-only data; connection setup cost exceeds query time |
| Custom file-based JSON store | Hand-rolled `json.load/dump` with manual locking | Re-invents SQLite poorly; no ACID, no indexing, breaks on concurrent access |

## Source
Phase 4: memory server chose SQLite. Phase 32: LongMemEval benchmark showed
FTS5 handles 500+ questions at 91% recall@5. Phase 38: CWD bug proved
SQLite's single-file model is also debuggable (one .db file to inspect).
```

## Lifecycle Transitions

Heuristic status evolves based on helpful/harmful counter ratios from the heuristic judge (dev-plan Step 6.5). Counters are retrospective analytics — they never influence heuristic selection.

### Counter Semantics

- `helpful`: incremented when heuristic matched AND judge global score ≥ 6/10
- `harmful`: incremented when heuristic matched AND judge score ≤ 4/10 AND approach reviewer score ≥ 6/10 (heuristic guidance conflicted with a reviewer-accepted approach)
- No update at judge score = 5 or when both judge and reviewer reject

### Status Transitions

| From | To | Trigger | Action |
|------|------|---------|--------|
| `active` | `under-review` | `harmful/(helpful+harmful) > 0.3` AND `helpful+harmful >= 5` | Automatic (orchestrator edits YAML) |
| `under-review` | `active` or `deprecated` | Manual user review | User edits YAML, optionally resets counters |
| `deprecated` | — | Terminal | Manual recovery only (user edits YAML) |
| `iron` | — | Never transitions | Counters accumulate for observability; dashboard flags harm ratio > 0.3 |

Minimum sample size of 5 total invocations prevents premature transitions from small-sample noise.
