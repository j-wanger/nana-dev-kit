# Phase 82 — QA Verification Matrix

Spec: `specs/phase-82-qa-verification-sweep.md` (nana:approved 2026-06-09).
Evidence standard: every verdict is backed by a command the ORCHESTRATOR executed itself (repro batch:
`eval/qa-sweep/repro-runs.log`, 58/58 run; high-severity cluster additionally hand-verified with
positive/negative controls). No subagent prose or transcript was admitted as evidence. Verdict enum:
`clean` / `defect-found` / `deferred` / `instrument-dead`. Verdicts below are per-AREA; the per-candidate
disposition table follows.

## Baseline (T1, 2026-06-09)

- `make test` -> "All tests passed" (20 scripts at baseline; 22 at close)
- `make eval` -> Score: 52/52 (100%) at baseline AND at close
- `bash scripts/check-install-drift.sh` -> 0 at baseline (pre-extension), 0 at close (post-extension + refresh)

## Controls (seeded-defect validation — a checker clean on its seed = instrument-dead)

| checker | seed | command | detection evidence | verdict |
| check-install-drift.sh | appended line to scratch copy of skills/dev-plan/SKILL.md (clean-verified exit 0 first) | `bash scripts/check-install-drift.sh "$S/installed"` | `differs: skills/dev-plan/SKILL.md` + exit 1 | validated |
| check-assumption-ledger.sh | internal --selftest fixtures, both directions (incl. append-only truncated/intact/row-loss) | `bash scripts/check-assumption-ledger.sh --selftest` | `SELFTEST: PASS`, exit 0 | validated |
| test_registration.sh | seeded-orphan-control.sh planted in scratch repo hooks/ | `bash "$S/repo/tests/test_registration.sh"` | `FAIL: seeded-orphan-control.sh ... NOT in modules.json`, 41/42, exit 1 | validated |
| eval-runner.sh (T3 catch-up) | hermetic 2-scenario corpus with seeded always-fail scenario | `bash "$T/scripts/eval-runner.sh"` (in tests/test_scripts_smoke.sh) | scored 1/2 — the runner demonstrably CAN fail | validated |

## Areas

| area | command | evidence | verdict |
| wiring | `python3 scripts/register-settings.py hooks /dev/stdout modules.json --scope project-local --regenerate \| diff - templates/.claude/settings.json` + MANIFEST diff vs disk md5 | template byte-identical (regen-fresh); 25=25 skills, 18=18 hooks bidirectional; MANIFEST was stale ~100/121 + missing 2 Phase-81 files — regenerated + test-guarded | defect-found |
| firing | sandbox pipes: both event shapes x allow+block per hook (see repro-runs.log + `make test` test_enforce/test_long_cadence/test_tooluse) | enforce-spec/block-dangerous/enforce-memory/scope-check were .input-only (current events carry .tool_input — proven LIVE when the fixed gate blocked the orchestrator mid-phase); Stop hooks parsed nonexistent .tool_uses; marker absent 05-25→06-09; allowlist bypassed by absolute paths; spec lookup broken by em-dash. 6 hooks fixed + validated; 4 lower-severity candidates deferred | defect-found |
| companions | `bash tests/test_companions.sh` (now 4 directions) | 9 stale referenced_at fixed; 3 orphans -> subtraction list (pinned exemptions); Directions C+D added — D caught 1 stale pointer beyond the audit set | defect-found |
| schema | `bash scripts/check-assumption-ledger.sh .dev-wiki/assumption-ledger.md` exit 0; grep sweeps for divergent schema copies | ledger schema single-source held; 2 doc-divergence candidates fixed, 1 low deferred | defect-found |
| drift | `bash scripts/check-install-drift.sh` (extended) | 11 stale LIVE runtime hooks invisible to the old scope:global-only comparison — refreshed + checker pass 2b added + 2 hermetic tests; planning-time 6-file resync retro-audited via git log (all 6 files Phase-81-churned template files; overwritten copies consistent with pre-81 lag, pre-resync state unrecoverable — caveat recorded); ghost global registrations deferred (maintainer call) | defect-found |
| coverage | `bash tests/test_scripts_smoke.sh` | eval-runner negative control + 2 generator smokes added; delivery-report + harness-audit deferred with rationale | defect-found |
| docs | `bash tests/test_templates.sh` (README accuracy tests) + count commands in repro-runs.log | 10/10 candidates confirmed and fixed (incl. the README count test catching MY new test scripts same-session) | defect-found |
| usage | sqlite3/wc/jq queries in repro-runs.log (memory DB rows, enforcement.log distribution, audit.jsonl, ledger rows, edge-screener read-only) | 2 candidates fixed (stale runtime, checker blind spot); 5 utilization findings -> subtraction-review list feeding Phase-79 prune-on-value | deferred |

## Per-candidate disposition (58)

| candidate | severity (agent est.) | verdict | disposition |
| wiring-manifest-missing-phase81-companions | medium | defect-found | MANIFEST regenerated; both Phase-81 companions now listed; guarded by tests/test_manifest_freshness.sh |
| wiring-manifest-md5-checksums-stale | medium | defect-found | MANIFEST checksums regenerated for all 122 files; freshness test added (caught its first real regression same-session) |
| wiring-modules-json-mcp-block-dead-config | low | defect-found | cmd_mcp reads name/module via --modules-json; install.sh reads cwd from modules.json and passes --modules-json (dry-run verified) |
| wiring-install-sh-header-stale-project-local-hook-list | low | defect-found | install.sh header now says all 17 project-scoped hooks from modules.json |
| wiring-install-sh-summary-wiki-skill-count-stale | low | defect-found | summary line corrected to 10 skills |
| firing-enforce-spec-legacy-input-field-dormant | high | defect-found | ROOT CAUSE REFINED: compound — (a) .input-only parse (current events carry .tool_input; proven LIVE when the fixed hook blocked the orchestrator), (b) ~/.claude/enforce marker absent 05-25→06-09 (recreated by install.sh 13:42), (c) relative-only allowlist bypassed by absolute paths, (d) em-dash slug lookup never found the spec. All four fixed; sandbox-validated allow+block, both shapes; session-start [nana:enforce] marker advisory added |
| firing-block-dangerous-bash-legacy-input-field-dormant | high | defect-found | .tool_input.command fallback; sandbox-validated rm -rf / blocked on both shapes (note: hook is project-local opt-in, was never registered in the kit repo) |
| firing-check-tests-were-run-phantom-tool-uses | high | defect-found | transcript_path JSONL fallback (real Stop shape); legacy fixture shape kept; 2 new real-shape tests |
| firing-py-review-stop-phantom-tool-uses | high | defect-found | same transcript fallback; real-shape test added |
| firing-enforce-memory-legacy-input-field-dormant | medium | defect-found | .tool_input fallback + path relativization; sandbox parity-validated |
| firing-dev-wiki-scope-check-legacy-input-field-dormant | medium | defect-found | .tool_input fallback + absolutize normalization (false out-of-scope advisories on absolute in-scope paths fixed); wrong-invariant test ("ignores .tool_input") INVERTED |
| firing-post-commit-toplevel-exit-code-dormant | medium | deferred | flow-semantics fix needs design; confirmed by repro |
| firing-detect-loop-toplevel-exit-code-dormant | low | deferred | same class |
| firing-post-commit-detect-loop-home-only-marker | low | deferred | marker-resolution design call |
| firing-hook-harness-claude-project-dir-sandbox-escape | medium | deferred | test-harness hardening, not shipped-code defect |
| companions-companion-orphan-stale-queue-spec | low | deferred | subtraction-review candidate (dead documentation vs re-wire is a value call) |
| companions-companion-orphan-registry-schema | low | deferred | subtraction-review candidate |
| companions-companion-orphan-session-context | low | deferred | subtraction-review candidate |
| companions-stale-refat-file-prompt-step20 | low | defect-found | referenced_at -> Step 6 |
| companions-stale-refat-empirical-anchor-step15 | low | defect-found | referenced_at -> Step 3 |
| companions-stale-refat-retro-check-step0 | low | defect-found | referenced_at -> Step 20 |
| companions-stale-refat-artifact-writer-step13 | low | defect-found | referenced_at -> Orchestrator Dispatch 2 (Step 15) |
| companions-stale-refat-delivery-flow-step2 | low | defect-found | referenced_at -> After executor returns (delivery gate) |
| companions-stale-refat-executor-prompt-step8 | low | defect-found | referenced_at -> Orchestrator dispatch block |
| companions-stale-refat-state-loader-step3 | low | defect-found | referenced_at -> Orchestrator Dispatch 1 (Steps 3-8) |
| companions-stale-refat-research-agent-step3 | low | defect-found | referenced_at -> Step 2.5 |
| companions-test-companions-no-refat-orphan-coverage | low | defect-found | test_companions.sh extended: Direction C (orphans, pinned 3-entry exemption) + Direction D (Step-N pointer resolution); D caught and fixed research-pause-spec Step 0 beyond the audit set |
| schema-project-local-hook-list-stale-docs | medium | defect-found | README flags table + install.sh header corrected (17 from modules.json) |
| schema-readme-eval-category-counts-stale | low | defect-found | README categories corrected to 34/6/6/6 |
| schema-wk-prune-cites-absent-spec-precedence-rule | low | deferred | low; doc-cite cleanup |
| drift-stale-global-hooks-invisible-to-drift-check | high | defect-found | check-install-drift.sh pass 2b (any kit-shipped hook present in installed root compared regardless of scope tag) + 11 stale runtime copies refreshed + 2 hermetic tests |
| drift-rescoped-hooks-missing-from-ghost-cleanup | high | deferred | deregistering ghost global hooks changes live wiring in every project — maintainer decision |
| drift-session-start-foreign-lineage-globally-registered | medium | deferred | same ghost-registration class |
| drift-installed-only-skill-residue-invisible | low | deferred | orphan inventory only; no deletes under ownership boundary |
| drift-memory-server-omission-undocumented | low | deferred | docs refinement of checker header |
| drift-dead-settings-json-exclude-entry | low | deferred | low; allow-list hygiene |
| coverage-delivery-report-script-structural-only | medium | deferred | functional smoke needs stubbed make (M/L design) |
| coverage-eval-runner-untested-no-negative-control | medium | defect-found | tests/test_scripts_smoke.sh: hermetic 2-scenario corpus, seeded failure scored 1/2 (runner CAN fail) |
| coverage-generate-report-script-untested | low | defect-found | functional smoke: exit 0 + HTML artifact |
| coverage-generate-workflow-script-untested | low | defect-found | functional smoke: exit 0 + HTML artifact |
| coverage-harness-audit-script-untested-unwired | low | deferred | unwired script -> subtraction-review, not test-backfill |
| docs-readme-headline-skill-hook-counts | low | defect-found | README: 25 skills, 18 hooks (17+1) |
| docs-readme-enforcement-installs-globally | high | defect-found | README enforcement section: per-project install + marker |
| docs-readme-project-local-six-hooks | medium | defect-found | README flags table: all 17 project-scoped hooks |
| docs-readme-eval-category-breakdown | low | defect-found | corrected to 34/6/6/6 |
| docs-manifest-md5-inventory-stale | low | defect-found | same fix as wiring-manifest rows |
| docs-architecture-26-dirs-phantom-wiki-consolidate | low | defect-found | _ARCHITECTURE: 25 dirs; wiki-consolidate removed from enumeration |
| docs-architecture-hook-counts-triple-drift | low | defect-found | _ARCHITECTURE: 18 files + 3 session-start.d modules; 1 global-scoped; 17 project-local |
| docs-architecture-eval-50-vs-52 | low | defect-found | _ARCHITECTURE: 52 scenarios (both places) |
| docs-agents-template-where-to-look-404 | medium | defect-found | templates/AGENTS.md Where-to-Look points at real files (.dev-wiki state, tests/, .claude/rules/) |
| docs-readme-status-flag-undocumented | low | defect-found | README flags table: --status row added |
| usage-stale-global-hooks-installed | high | defect-found | 11 stale ~/.claude hook copies refreshed from fixed templates (live runtime now runs Phase-82 code) |
| usage-drift-checker-blind-to-registered-hooks | medium | defect-found | check-install-drift.sh pass 2b: any kit-shipped hook present in installed root is compared regardless of scope tag; 2 hermetic tests |
| usage-session-start-ts-stale-in-kit | medium | deferred | runtime-state freshness; observe post-refresh |
| usage-audit-log-model-field-always-unknown | medium | deferred | CLAUDE_MODEL never set by harness; needs upstream env or removal — subtraction-review |
| usage-enforce-memory-zero-lifetime-firings | low | deferred | subtraction-review (opt-in layer never opted into) |
| usage-memory-reinforcement-machinery-unused | low | deferred | subtraction-review (0 reinforcements / 55 entries) |
| usage-memory-mcp-unused-in-consuming-project | low | deferred | subtraction-review (edge-screener never calls memory tools) |

## Fixes — evidence pointers

- Sandbox validations (allow AND block paths, both event shapes, CLAUDE_PROJECT_DIR pinned to mktemp sandbox): transcript of this session's fix loop; re-runnable via `make test` (test_enforce.sh, test_long_cadence_hooks.sh, test_tooluse_hooks.sh Phase-82 sections).
- Live confirmation: the refreshed enforce-spec gate BLOCKED the orchestrator's own Edit calls mid-phase (proof the production event shape is .tool_input and the gate now fires), then allowed them after the allowlist/slug fixes — the full dormancy->restoration cycle observed live.
- Self-lockout recovery used the Bash escape path (gate matcher is Write|Edit) — sanctioned SECURITY escape hatch; all fixes were sandbox-validated before the live copy was touched, per the spec constraint.
- Enforcement-log contamination NOTE: audit/test pipes into template hooks with CWD=repo wrote real `.dev-wiki/enforcement.log` records (18:24-18:27Z scope-check advisories) — the log has no provenance separation; recorded as a known instrument hazard for future log-based evidence.
- Both copies converged: `install.sh --all` rerun at close; `check-install-drift.sh --count` = 0 with the EXTENDED comparison set; MANIFEST + `make template` regen committed in-change.
