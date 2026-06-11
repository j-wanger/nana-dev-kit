# Fixture: clean verdict table (must PASS check-verdict-table.sh)
phase-base: abc1234
pin: Phase-87 verdicts stand as recorded under the checker versions that graded them.

| id | class | verdict | status | zero-class | revert-trigger | window | blockers-ref | evidence | removal-set |
|---|---|---|---|---|---|---|---|---|---|
| demo-trim | trim | trim-trial | proposed | n/a | recovery failures attributable to missing anchor | 5 phases | T6-filing | stage-1 verdict | skill step X |
| demo-leftover | leftover | keep | proposed | didnt-fire | n/a | n/a | n/a | snapshot row | n/a |
| demo-checker | checker | tightened | proposed | n/a | n/a | n/a | n/a | seeded controls | n/a |
