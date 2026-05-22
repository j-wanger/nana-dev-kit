# phase-template.md

Template for phase articles stored in `.dev-wiki/articles/phases/`. Consumed by `dev-plan` (create) and `dev-debrief` (status updates).

## Phase Article Template

### Frontmatter

```yaml
---
title: "Phase N: Name"
aliases: []
category: phases
tags: []
parents: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: init | plan
status: not-started | active | completed
scope: ["path/globs/*"]
entry_criteria: "..."
exit_criteria: "..."
---
```

### Body

```markdown
# Phase N: Name

## Objective

<1-2 sentences describing what this phase accomplishes>

## Scope

Files and modules affected:
- `path/to/module/*`

## Exit Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>

## Constraints (optional)

<Safety rails preventing known failure modes. Each constraint names the bad outcome it prevents.>
- <Constraint: prevents <specific bad outcome>>

## Checkpoints (optional)

<When to pause and report. Proportional to risk.>
- After <milestone>: report progress, wait for approval
- If <unexpected condition>: STOP and ask

## Assumptions (optional)

<What must be true. Each has a stop-if-violated fallback.>
- <Assumption>. If false: <what to do instead>

## Notes

<Any relevant context from project analysis>
```
