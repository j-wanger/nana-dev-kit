---
parent: dev-debrief
referenced_at: "Step 17"
---

# Debrief Finalization — Steps 17, 22, 23, 24, and the Assumption-Ledger Revisit

Companion file for dev-debrief SKILL.md. Contains mechanical finalization steps that run during full debrief. Read at: Step 17 (before Step 18), the Assumption-Ledger Revisit (at Step 21), and Steps 22-24 (after Step 19). Step 18 (active-phase.md rewrite) is handled inline in SKILL.md.

**Variables:** `$WIKI = $ROOT/.dev-wiki`, `$ROOT = project root` (defined in SKILL.md Step 2).

---

## Step 17: Create Status Snapshot

Use the Glob tool to check if `$WIKI/articles/status/$(date +%Y-%m-%d)-codebase-snapshot.md` exists. If none, create one with file metrics, module structure, dependency versions, test status, and recent commits (last 5 from `git log`).

**Scan article integration:** If `$WIKI/articles/status/*-scan.md` files exist from a prior `/dev-scan`, reference them in the snapshot rather than duplicating their content. The snapshot should summarize scan findings (module count, issue counts, hub modules), not replicate the full dependency maps.

Read `~/.claude/skills/dev-wiki/size-budgets.md` for size budgets.

## Assumption-Ledger Revisit (closing-phase forcing-function — referenced from SKILL.md Step 21)

The detect-after backstop for the assumption gate ([[assumption-approval-gate]], Phase 81). When a phase
completes, its surfaced assumptions must be revisited — did any prove wrong? Runs in full AND Lite debrief.

1. **Locate the closing phase's block** in `$WIKI/assumption-ledger.md`. If there is no block for it (the
   phase was planned before the gate existed, or surfaced no load-bearing assumptions), there is nothing to
   revisit — skip this section.
2. **Fill each `revisit-status:`** for the closing phase's block, judging from the implementation: `held`
   (the assumption held), `bit` (it proved wrong / forced rework), or `open` (a deferred don't-know still
   unresolved). Edit ONLY the `revisit-status:` field of the closing phase's rows — never rewrite a prior
   phase's block (the ledger is append-only; this in-place fill is the one permitted edit).
3. **Re-scan prior phases** for any row still `revisit-status: open`, or an `accept` that bit only later
   (the cascade pattern this project keeps hitting). Update those you can now judge — a later-phase bite is
   caught here, not only in the phase that recorded it.
4. **Surface `bit` assumptions:** note each in the journal and SUGGEST reviewing the linked decision
   article's `confidence` — do NOT auto-mutate it (the maintainer decides).
5. **Enforce (the mechanical bite):** run
   `bash scripts/check-assumption-ledger.sh --revisit "$WIKI/assumption-ledger.md" <closing-phase>`. A
   nonzero exit means the closing phase still has blank `revisit-status` rows — finalization is NOT clean;
   fill them and re-run. The format + validator (`scripts/check-assumption-ledger.sh`, its `## Ledger
   schema` block) is the single source of truth.

## Step 22: Rebuild index.md *(Lite: skip)*

Use the Glob tool to scan all files under `$WIKI/articles/`. Rebuild `$WIKI/index.md` with By Category, By Hierarchy, and Recent sections. Sort phases by numeric prefix, journal/status by date descending. Recent: last 10 articles by date.

## Step 23: Append to log.md

`[<ISO-timestamp>] DEBRIEF -- <N> decisions, 1 journal, tasks updated, state refreshed`

## Step 24: Clean Up Breadcrumbs

```bash
rm -f "$WIKI/.pending-commit" "$WIKI/.session-buffer" "$WIKI/.session-end"
```
