---
parent: dev-debrief
referenced_at: "Step 18"
---

# Debrief Finalization — Steps 18, 23, 24, and 25

Companion file for dev-debrief SKILL.md. Contains mechanical finalization steps that run during full debrief. Read at two points: Step 18 (before Step 19), and Steps 23-25 (after Step 20). Step 19 (active-phase.md rewrite) is handled inline in SKILL.md.

**Variables:** `$WIKI = $ROOT/.dev-wiki`, `$ROOT = project root` (defined in SKILL.md Step 2).

---

## Step 18: Create Status Snapshot

Use the Glob tool to check if `$WIKI/articles/status/$(date +%Y-%m-%d)-codebase-snapshot.md` exists. If none, create one with file metrics, module structure, dependency versions, test status, and recent commits (last 5 from `git log`).

**Scan article integration:** If `$WIKI/articles/status/*-scan.md` files exist from a prior `/dev-scan`, reference them in the snapshot rather than duplicating their content. The snapshot should summarize scan findings (module count, issue counts, hub modules), not replicate the full dependency maps.

Read `~/.claude/skills/dev-wiki/size-budgets.md` for size budgets.

## Step 23: Rebuild index.md *(Lite: skip)*

Use the Glob tool to scan all files under `$WIKI/articles/`. Rebuild `$WIKI/index.md` with By Category, By Hierarchy, and Recent sections. Sort phases by numeric prefix, journal/status by date descending. Recent: last 10 articles by date.

## Step 24: Append to log.md

`[<ISO-timestamp>] DEBRIEF -- <N> decisions, 1 journal, tasks updated, state refreshed`

## Step 25: Clean Up Breadcrumbs

```bash
rm -f "$WIKI/.pending-commit" "$WIKI/.session-buffer" "$WIKI/.session-end"
```
