# Run Guide — Harness Effectiveness Comparison

## Automated Run (Conditions A + B)

Conditions A and B are automated via the Phase 42 implementation (Task 6). Results are saved to `eval/comparison/results/`.

No manual steps required.

## Manual Run (Condition C — Full Harness)

After Phase 42 delivers the automated A+B results, run condition C manually:

### Prerequisites
- Same Claude Code version and model as the automated run
- nana-dev-kit installed (`bash install.sh --all`)

### Steps

1. **Set up the repo:**
   ```bash
   bash eval/comparison/scripts/setup-harness.sh /tmp/trial-harness eval/comparison/starters/feature-build
   ```

2. **Start a new Claude Code session** in the harness repo:
   ```bash
   cd /tmp/trial-harness
   claude
   ```

3. **Give the task prompt** (copy from `eval/comparison/tasks/feature-build.md` — the "Prompt" section).

4. **Let the harness work.** The session will have hooks, enforcement, and skills active. Do not intervene beyond answering direct questions from Claude.

5. **Collect metrics** after the session completes:
   ```bash
   bash eval/comparison/scripts/collect-metrics.sh /tmp/trial-harness eval/comparison/tasks/feature-build.md > eval/comparison/results/feature-build-harness.json
   ```

6. **Repeat for bug-fix** (optional):
   ```bash
   bash eval/comparison/scripts/setup-harness.sh /tmp/trial-bugfix eval/comparison/starters/bug-fix
   cd /tmp/trial-bugfix
   claude
   # Give the bug-fix task prompt
   bash eval/comparison/scripts/collect-metrics.sh /tmp/trial-bugfix eval/comparison/tasks/bug-fix.md > eval/comparison/results/bug-fix-harness.json
   ```

7. **Fill in Condition C section** of `results-template.md` with the collected metrics.

### Important Controls
- Run on the same day as the automated comparison
- Use the same Claude Code version and model
- Do not modify task files (checksums will be verified)
- Copy the hook invocation log: `cp /tmp/trial-harness/.claude/hook-invocations.jsonl eval/comparison/results/`
