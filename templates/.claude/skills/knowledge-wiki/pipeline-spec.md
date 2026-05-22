<!-- Canonical pipeline specification — SSOT for wiki resolution, subagent conventions, and A→W→R orchestration -->
<!-- REFERENCE, DO NOT PASTE. Each wiki skill's SKILL.md should link here rather than copy content inline. -->
<!-- To use Step 0 in a skill: write a short Step 0 section that reads "Read and follow the Step 0 section of ~/.claude/skills/knowledge-wiki/pipeline-spec.md. This skill is a [write|read-only] operation — in sub-step 0.6 [update the last_used field | SKIP the touch step]." Then link to this file. -->
<!-- Sub-step 0.6 (Touch the registry) is write-only. Read-only skills (wiki-query, wiki-health in read modes) follow the SKIP instruction. -->

# Pipeline Specification

Wiki resolution, subagent conventions, and the Analyst → Writer → Reviewer orchestration template.

---

## Step 0: Resolve Wiki

**Canonical path definition:** Throughout this template, "canonical path" means the absolute path with symlinks resolved (via `realpath`) and trailing slashes stripped. Use the Bash tool to run `realpath <path>` when comparing paths.

Determine which wiki this command targets. This runs BEFORE any existing pre-checks.

**Sub-step 0.0: Check Session Cache**

Check if `<wiki_path>/.wiki-resolved` exists (where wiki_path is the wiki root discovered in prior invocations). If it exists and was created in this session (check file mtime is within the last 4 hours):

1. Read `.wiki-resolved` for cached discovery results (wiki_path, schema summary, article count).
2. Skip Sub-steps 0.1-0.8 and proceed with the cached values.
3. Emit: "[wiki] Using cached discovery (skip step-0)."

If `.wiki-resolved` does not exist or is stale, proceed with full discovery (Sub-steps 0.1-0.8).

**Sub-step 0.1: Read the registry**

Read `~/.claude/wikis.json`. Handle these cases:
- File does not exist: treat as empty registry `{"version": 1, "wikis": []}`.
- File exists but is unparseable JSON: STOP. Report to user: "Registry at ~/.claude/wikis.json is corrupted. Back up the file and remove it to start fresh, then re-register your wikis with /wiki-init --register <path>."
- File exists and is valid: load it into memory for the rest of Step 0.

**Sub-step 0.2: Explicit --wiki flag**

If the user invoked the command with `--wiki <name>`:
- Look up the wiki by name in the registry.
- If not found: STOP. Report: "No wiki named '<name>' is registered. Run `/wiki-registry` to see available wikis."
- If found: verify the path still exists on disk. If not: STOP. Report: "Wiki '<name>' is registered at '<path>' but the directory does not exist. Restore the directory or use /wiki-registry rename to adjust."
- Verify `<path>/schema.md` exists and is readable. If not: STOP. Report: "Wiki '<name>' at '<path>' is missing schema.md. The wiki may be corrupted."
- If valid: set `wiki_path = <resolved-path>` and skip to Sub-step 0.6.

**Sub-step 0.3: Build the candidate list**

Build the list of candidate wikis:
- A wiki is a candidate if its `path` equals CWD or is a subdirectory of CWD (prefix match on canonical paths).
- A wiki is also a candidate if the user's current message contains the wiki's `name` field as a whole-word match (case-insensitive). The name MUST appear at a word boundary — the character before and after must be a space, punctuation, or string boundary. "ml" must NOT match "html" or "normalizing". For example, "capture this to the aml-compliance wiki" matches `aml-compliance` because hyphens are word boundaries.

**Sub-step 0.4: Auto-register unregistered local wiki**

If CWD contains a `./wiki/` directory with `./wiki/schema.md`, and no registered wiki's path matches the canonical path of `./wiki/`:

1. Derive a name from CWD's PARENT directory basename (not CWD itself), lowercased and kebab-cased (e.g., `/Users/x/my-project/wiki/` → `my-project`). This avoids generic names like "wiki" when CWD is the wiki directory itself.
2. If that name collides with an existing registry entry with a different path, append a numeric suffix: `knowledge-wiki-2`, `knowledge-wiki-3`, etc.
3. Read `./wiki/schema.md`, extract the `description` field from the YAML frontmatter (the line after `description:`, multi-line strings supported).
4. Build the new registry entry:

        {
          "name": "<derived-name>",
          "path": "<canonical absolute path of ./wiki>",
          "description": "<from schema.md, or empty string>",
          "registered": "<today in YYYY-MM-DD>",
          "last_used": "<today in YYYY-MM-DD>"
        }

5. Use the atomic write pattern (see Sub-step 0.7) to append the entry to the registry.
6. Emit a one-line notice: `[Auto-registered '<name>' from ./wiki/. Run /wiki-registry rename to change the name.]`
7. Add the newly registered wiki to the candidate list.

**Sub-step 0.5: Select the wiki**

From the candidate list:
- If zero candidates:
  - If the registry is empty (no wikis registered at all): STOP. Report: "No wikis are registered. Run `/wiki-init` to create your first wiki, or `/wiki-init --register <path>` to adopt an existing one."
  - If the registry has wikis but none match CWD: STOP. Report: "No wiki applicable to this directory. Use --wiki <name> or cd into a project with a registered wiki. Run /wiki-registry to see available wikis."
- If exactly one candidate: use it directly. Set `wiki_path = <candidate-path>`.
- If multiple candidates:
  - Check for a cached inference result from earlier in this conversation. The cache is conversation-scoped only: remember the chosen wiki name within the current Claude conversation. Do not create any file, environment variable, or persistent storage for the cache. If you have already resolved a wiki via inference or user choice in this conversation, reuse that resolution here without re-running inference. **Cache invalidation:** If CWD has changed since the wiki was cached, invalidate the cache and re-resolve from Sub-step 0.3.
  - Otherwise, dispatch the inference subagent (see Sub-step 0.8). Cache the result.

**Sub-step 0.5b: Validate the resolved wiki**

Before proceeding, verify `<wiki_path>/schema.md` exists and is readable. If not: STOP. Report: "Wiki at '<wiki_path>' is missing schema.md. The wiki may be corrupted." This prevents downstream steps from failing with confusing errors.

**Sub-step 0.6: Touch the registry (write skills only)**

For write operations (wiki-add, wiki-absorb, wiki-bootstrap, wiki-reorg), update the `last_used` field for the resolved wiki to today's date. Use the atomic write pattern.

For read-only skills (wiki-query, wiki-health in full/audit/dry-run modes), SKIP this sub-step entirely — do not write to the registry on reads.

**Sub-step 0.7: Atomic write pattern**

For every registry mutation:
1. Read `~/.claude/wikis.json` fresh into memory.
2. Apply the mutation in memory.
3. Write the serialized JSON to `~/.claude/wikis.json.tmp` using the Write tool.
4. Use the Bash tool to rename: `mv ~/.claude/wikis.json.tmp ~/.claude/wikis.json`

The POSIX rename is atomic. Concurrent writers may lose each other's changes (last-writer-wins), but the file never becomes unparseable mid-write.

**Sub-step 0.8: Inference mechanics**

When inference is needed, dispatch a ONE-SHOT Agent call (NOT a full Analyst/Writer/Reviewer cycle):

    Agent tool:
      description: "wiki-<skill-name> -- Inference phase"
      prompt: |
        You are picking the most relevant wiki for a user command.

        ## Candidate Wikis
        [for each candidate: name, description, last_used]

        ## User Message
        [the user's current message verbatim]

        ## Recent Conversation Context
        [last 3-5 messages from the conversation, or "No prior context" if session is fresh]

        ## Your Job
        Return exactly one of:
        - CONFIDENT: <name> — if one wiki clearly matches based on name mentions, description keywords, or recent context
        - AMBIGUOUS: <name1>, <name2>, <name3> — if 2-3 wikis plausibly match

        Do not explain your reasoning. Output only the classification line.

Parse the response:
- `CONFIDENT: <name>` → use that wiki. Set `wiki_path` and remember this choice in the current conversation so subsequent wiki commands in this conversation reuse it without re-running inference.
- `AMBIGUOUS: ...` → present to user: "Which wiki? [list with descriptions]". Wait for user choice. Cache the choice for the session.

**Sub-step 0.9: Write Session Cache**

After full discovery completes (Sub-steps 0.1-0.8), write `<wiki_path>/.wiki-resolved` with the discovery results:

```
wiki_path: <absolute path>
schema_domain: <domain from schema.md>
article_count: <count>
resolved_at: <ISO timestamp>
```

This cache is valid for the current session only. It will be ignored if older than 4 hours.

**After Step 0 completes:** `wiki_path` is the canonical absolute path to the resolved wiki. All subsequent steps use `<wiki_path>/` wherever the skill previously used `wiki/`.

---

## Pipeline Conventions

Shared conventions for wiki pipeline subagents (writer + reviewer prompts).

### Wiki Path

**IMPORTANT — Wiki Path:** The Runtime Context will include a `### Wiki Path` field containing the absolute path to the target wiki directory. All file paths below use `<wiki_path>` as a placeholder. Replace it with the actual path from Runtime Context when reading or writing files. Do NOT use the literal path `wiki/` — that was the old single-wiki convention.

### Tool Usage

- Use the **Write** tool to create new files. Do NOT use Bash echo/cat.
- Use the **Edit** tool to modify existing files. Do NOT use Bash sed/awk.
- Use the **Read** tool to read files. Do NOT use Bash cat/head/tail.
- Use the **Glob** tool to find files. Do NOT use Bash find/ls.
- Use the **Grep** tool to search content. Do NOT use Bash grep/rg.

---

## Orchestration Template

Standard subagent pipeline shared by all wiki skills that dispatch Analyst, Writer, and Reviewer subagents. Each skill references this template and provides skill-specific inputs.

### Pipeline Overview

```
Analyst -> [User Approval Gate (optional)] -> Writer -> Reviewer -> [Revision Loop] -> Completion
```

### Dispatch Analyst

1. Read `analyst-prompt.md` from the skill's own directory (e.g., `~/.claude/skills/wiki-bootstrap/analyst-prompt.md`).
2. Append a `## Runtime Context` section containing the context gathered in the skill's context-gathering step. **Context budget:** Include at most 30 article summaries in the inventory. For wikis with >30 articles, include a count + category breakdown instead of full inventory rows. Use this format:

```
## Runtime Context

### Wiki Path
{{resolved wiki_path from Step 0}}

### Schema
---
domain: {{from <wiki_path>/schema.md}}
description: {{from <wiki_path>/schema.md}}
---

Domain Context: {{from <wiki_path>/schema.md}}
Custom Tags: {{bullet list from <wiki_path>/schema.md}}
Hierarchy Roots: {{bullet list from <wiki_path>/schema.md}}
Conventions: {{bullet list from <wiki_path>/schema.md}}

### [Skill-Specific Context Sections]
{{Each skill appends its own context here -- e.g., Focus Topic, Article Inventory, Inbox Entries, Question, Session Context, Interview Answers, Source Material, etc.}}
```

3. Dispatch via Agent tool:

```
Agent tool:
  description: "<skill-name> -- Analyst phase"
  prompt: [contents of analyst-prompt.md] + [runtime context above]
```

4. Receive the analyst's response. It must contain `## Plan`, `## Classifications`, and `## Risks` sections.

5. **Validate analyst output:** If the response does NOT contain all three required sections (`## Plan`, `## Classifications`, `## Risks`), re-dispatch once with: "Your previous response was missing required sections. You MUST include ## Plan, ## Classifications, and ## Risks." If still malformed after 1 re-dispatch, report to user and stop.

6. **Handle analyst risks:** If the `## Risks` section lists anything other than "None" (ambiguities, coverage gaps, potential overlaps, vague answers needing follow-up), present the risks to the user and ask for guidance. Re-dispatch the analyst with the user's clarifications if needed. Do not re-ask about items that were already clear.

### User Approval Gate (skill-dependent)

Some skills require explicit user approval before dispatching the writer. The skill's SKILL.md specifies whether this gate applies and what format to use.

- **Skills with approval gate:** wiki-bootstrap, wiki-reorg
- **Skills without approval gate:** wiki-absorb, wiki-add (ingest modes), wiki-init, wiki-query
- **Skills with conditional gate:** wiki-add (capture-identify mode only)

When the gate applies, present the analyst's plan to the user grouped by hierarchy root or numbered by change. Wait for the user's response before proceeding. If the user rejects, stop gracefully.

### Dispatch Writer

0. **Pre-check directories:** Before dispatching, verify that all four category directories exist under `<wiki_path>/articles/`: `concepts/`, `patterns/`, `decisions/`, `action-plans/`. Create any missing with `mkdir -p`. This prevents writer failures on fresh wikis.

1. Read `writer-prompt.md` from the skill's own directory.
2. Append the analyst's full response under `## Analyst Plan`.
3. Append any additional context the skill requires (e.g., article inventory, inbox entries, source content, batch topics).
4. If the skill uses batching and the plan exceeds the batch threshold, split into batches and process sequentially. Report progress between batches.

```
Agent tool:
  description: "<skill-name> -- Writer phase (batch K of N)"
  prompt: [contents of writer-prompt.md] + [analyst plan] + [skill-specific context]
```

5. Receive the writer's response. Expected output sections vary by skill but typically include `## Files Created`, `## Files Modified`, `## Schema Proposals`, and `## Self-Review`.

6. **Verify files exist:** For each file listed in the writer's `## Files Created` section, use the Glob tool to verify it exists on disk. If any declared file is missing, report the discrepancy to the user before dispatching the reviewer.

### Dispatch Reviewer

1. Read `reviewer-prompt.md` from the skill's own directory.
2. Append the analyst's plan under `## Analyst Plan`.
3. Append the writer's report (combined across all batches if applicable) under `## Writer Report`.
4. Append any additional context the skill requires (e.g., original source material for wiki-add ingest modes, index content for wiki-query).

```
Agent tool:
  description: "<skill-name> -- Reviewer phase"
  prompt: [contents of reviewer-prompt.md] + [analyst plan] + [writer report] + [skill-specific context]
```

### Handle Review Result

Parse the reviewer's response for three fields:

- **Score:** Extract the number from the `Score: N/10` line.
- **Issues:** Extract the bulleted list after `Issues:` (or "none").
- **Verdict:** Extract the value from the `Verdict:` line.

Then branch on the verdict:

- `Verdict: accept` -- proceed to the skill's completion step.
- `Verdict: revise` -- enter revision loop (score 6-8, fixable issues).
- `Verdict: reject` -- escalate to user: "Reviewer rejected with score N/10: [issues]. Please review and decide how to proceed." Do NOT auto-revise on reject.

### Revision Loop (max 1 round)

Only entered when `Verdict: revise`. Re-dispatch the writer with a DIFFERENT prompt:

```
Agent tool:
  description: "<skill-name> -- Writer revision"
  prompt: |
    You are fixing issues found by the reviewer in your previous work.

    ## Original Analyst Plan
    [paste analyst's plan]

    ## Reviewer Issues
    [paste reviewer's issues list from the reviewer's response]

    ## Your Job
    Read the files you previously wrote. Fix the issues listed below.
    If your fix requires additional changes to maintain wiki conventions
    (cross-links, frontmatter consistency, index updates), make those too.
    Do not re-read original source material. Do not redo work that was approved.
    Report what you fixed using the standard writer output format.
```

After writer fixes, re-dispatch the reviewer. **Maximum 1 revision round.** If the reviewer's verdict is still `revise` or `reject` after 1 revision, accept the best version and report to the user:

"Reviewer found unresolved issues after 1 revision (score N/10): [issues]. Accepting best version — please review manually."

Do NOT loop more than once. Unbounded loops waste tokens and rarely converge.

### Error Handling

If any Agent tool call fails (timeout, error), surface the error to the user:

"[Phase] failed: [error]. You can retry with /[skill-command] or investigate the error."

Do not retry automatically. Do not skip the failed phase.
