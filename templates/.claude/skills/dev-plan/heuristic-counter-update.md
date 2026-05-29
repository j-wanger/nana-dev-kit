---
parent: dev-plan
referenced_at: "Step 13"
---

# Heuristic Counter Update

After the heuristic judge returns in Step 13, update helpful/harmful counters on each matched heuristic article. Counters are retrospective analytics — they do NOT feed back into matcher selection.

## Inputs (from Step 13 orchestrator context)

- **matched_heuristics**: List of heuristic IDs that the matcher selected (1-3)
- **judge_score**: Global Score N/10 from heuristic judge
- **reviewer_score**: Global Score N/10 from approach reviewer

## Attribution Rules

For EACH matched heuristic, apply ONE rule (first match wins):

1. **Helpful**: judge_score >= 6 → increment `helpful` counter by 1
2. **Harmful**: judge_score <= 4 AND reviewer_score >= 6 → increment `harmful` counter by 1
3. **No update**: judge_score = 5, OR both judge_score <= 4 AND reviewer_score <= 5

Rule 2 captures: the heuristic flagged the approach as misaligned, but the approach reviewer accepted it. The heuristic's guidance conflicted with a good approach.

## Update Protocol

For each matched heuristic ID:

1. Locate the article at `$ROOT/wiki/heuristics/<id-slug>.md` (glob `wiki/heuristics/<ID>-*.md`)
2. Read the file, extract current counter value from YAML frontmatter
3. Compute new value (current + 1)
4. Edit the file: replace `helpful: <old>` with `helpful: <new>` (or `harmful:` respectively)
5. After counter update, read `heuristic-lifecycle.md` and evaluate lifecycle transitions

## Fail-Open

If any step fails (file not found, Edit fails on stale match, YAML parse error):
- Log: `"Counter update skipped for <ID>: <reason>"`
- Skip silently — do not block planning flow
- Continue with remaining matched heuristics

Counter updates are best-effort observability. A missed increment is acceptable; a blocked planning session is not.
