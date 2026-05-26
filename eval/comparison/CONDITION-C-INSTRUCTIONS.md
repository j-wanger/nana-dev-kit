# Condition C — Full Harness Trial

## What this is

A controlled evaluation of nana-dev-kit's effectiveness on a hard SWE-bench task (django__django-16263). You are running condition C — full harness with all features active.

## Setup

```bash
bash eval/comparison/scripts/setup-swe-task.sh /tmp/swe-comparison/swe-harness
```

## Your Task

Read `eval/comparison/tasks/swe-bench-django-16263.md` for the issue description. Fix the Django ORM to strip unused annotations from count() queries.

Work in `/tmp/swe-comparison/swe-harness`.

## Important

- Do NOT look at any files under `eval/comparison/results/` — they may contain spoilers
- Do NOT read the gold patch from the SWE-bench dataset
- Use whatever approach the harness naturally encourages (thinking protocol, investigation before coding, etc.)
- Commit your changes when done

## After completion

The evaluator will apply a test patch and run 4 tests. Your score is the number of fail-to-pass tests that pass (out of 3, plus 1 regression test).

To run the tests yourself (requires Python 3.11 venv at /tmp/swe-comparison/.venv):
```bash
cd /tmp/swe-comparison/swe-harness
git apply /tmp/swe-comparison/test_patch.diff
PYTHONPATH=/tmp/swe-comparison/swe-harness /tmp/swe-comparison/.venv/bin/python tests/runtests.py aggregation.tests.AggregateAnnotationPruningTests -v 2
```
