---
parent: dev-debrief
referenced_at: "Step 2"
---

# Delivery Flow Protocol

Extracted from dev-debrief. Runs after executor returns when phase_status = READY FOR COMPLETION.

## Step D1: Generate Delivery Report

Run `python3 scripts/generate-delivery-report.py` from the project root. This produces `docs/delivery-report.html` with:
- Phase summary (tasks done, files changed, lines +/-)
- Test results (make test pass/fail count)
- Eval results (make eval score)
- Decisions made this phase
- Files changed list

If the script fails or is not found, warn: `"Delivery report unavailable — present manual summary instead."` and skip to Step D3.

## Step D2: Present for Acceptance (Delivery Gate)

Present the delivery report summary to the user. This is the **delivery gate** — the second boundary checkpoint in the 2-gate ceremony model.

Options:
- **Accept**: User confirms the phase delivery. Proceed to Step D3.
- **Reject + Fix**: User identifies issues. Fix them, re-run the report script, re-present. Maximum 3 rounds, then proceed with acknowledged gaps.
- **Reject + Abort**: User wants to discard. Do NOT auto-commit. STOP.

A vague "looks good" or "ok" counts as acceptance. Silence does NOT.

## Step D3: Auto-Commit and Push

After acceptance:

1. **Stage all changes:** `git add -A` (the phase work is complete; all changes are intentional).
2. **Commit** with message: `Phase N: <phase name> — <1-line summary>` + Co-Authored-By trailer.
3. **Push** to the current branch's upstream: `git push`. If no upstream is set, run `git push -u origin HEAD`. If push fails, report the error but do NOT retry with --force.

**Safety:**
- Do NOT push to main/master without explicit user confirmation.
- If the branch has no remote, just commit locally and note: "No remote configured — committed locally."
- If there are merge conflicts on push, report and let the user resolve.

## Skip Conditions

- Quick debrief: skip the entire delivery flow (no report, no auto-commit).
- No phase completion (ongoing work): skip delivery report. Auto-commit is still offered for session work if the user requests it.
