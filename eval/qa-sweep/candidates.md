# Phase 82 — Audit Candidates (T2 fan-out output)

Generated from the ultracode fan-out (8 read-only candidate-generator agents). NO entry here is a
confirmed defect — each carries a proposed reproduction command the ORCHESTRATOR runs in T3; candidates
whose repro does not demonstrate the defect are dismissed. Severity is the AGENT'S estimate.

## wiring

### wiring-manifest-missing-phase81-companions
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/MANIFEST
- claim: MANIFEST has no path lines for the two Phase-81 dev-plan companions assumption-gate.md and assumption-gate-example.md, which exist on disk (added in commit e4e6e07 without a MANIFEST regen; MANIFEST last touched in Phase 63 commit 7f2200e).
- repro: `cd /Users/jwang/nana-dev-kit && grep -q 'dev-plan/assumption-gate.md' templates/.claude/skills/MANIFEST && grep -q 'dev-plan/assumption-gate-example.md' templates/.claude/skills/MANIFEST`

### wiring-manifest-md5-checksums-stale
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/MANIFEST
- claim: MANIFEST md5 checksums are stale for roughly 100 of 121 listed files (everything edited since Phase 63), including the Phase-81-modified dev-plan/SKILL.md and dev-debrief/SKILL.md; only files untouched since Phase 63 (e.g. dev-check/SKILL.md, py-lint/SKILL.md) still match, and line 1 records the empty-string md5 (d41d8cd98f00b204e9800998ecf8427e) for MANIFEST itself.
- repro: `cd /Users/jwang/nana-dev-kit && [ "$(grep 'skills/dev-plan/SKILL.md$' templates/.claude/skills/MANIFEST | cut -d' ' -f1)" = "$(/sbin/md5sum templates/.claude/skills/dev-plan/SKILL.md | cut -d' ' -f1)" ]`

### wiring-modules-json-mcp-block-dead-config
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/register-settings.py
- claim: The modules.json core-module mcp block (name/module/cwd) is consumed by nothing — register-settings.py cmd_mcp hardcodes server name 'memory' and args '-m memory_server' (lines 112-116) and install.sh hardcodes '--cwd ~/.claude' (line 253) — so editing the declared single source of truth has zero effect; values currently coincide, making this latent.
- repro: `cd /Users/jwang/nana-dev-kit && grep -q '\.mcp' install.sh scripts/register-settings.py`

### wiring-install-sh-header-stale-project-local-hook-list
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/install.sh
- claim: install.sh usage header (lines 10-12) documents --project-local as installing 6 named hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start) but the code installs all 17 scope==project hooks from modules.json (line 72), including enforce-spec, enforce-loop, session-stop, etc.
- repro: `cd /Users/jwang/nana-dev-kit && bash -c '! { h=$(sed -n "1,14p" install.sh); echo "$h" | grep -q "audit-log" && ! echo "$h" | grep -q "enforce-spec"; }'`

### wiring-install-sh-summary-wiki-skill-count-stale
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/install.sh
- claim: install.sh summary line 328 prints 'knowledge-wiki pipeline (11 skills)' but the knowledge-wiki module in modules.json declares 10 skills (matching the 10 dirs on disk).
- repro: `cd /Users/jwang/nana-dev-kit && bash -c 'n=$(jq -r ".modules[]|select(.name==\"knowledge-wiki\").skills|length" modules.json); grep -q "($n skills)" install.sh'`

**Area notes:** Clean areas, verified deterministically: (1) hooks — all 18 modules.json hooks[] scripts exist in templates/.claude/hooks/; the 17 scope==project hooks appear in templates/.claude/settings.json with ${CLAUDE_PROJECT_DIR} paths and the sole scope==global hook (context-size-check.sh) is correctly absent from the project template (registered to ~/.claude/hooks by install.sh global path, line 286/306); no orphan hook scripts on disk. (2) skills — modules.json union (25) exactly matches skill dirs on disk, no orphans either direction; all 25 have MANIFEST description comments; the two new Phase-81 companions carry correct parent frontmatter. (3) generated template — regenerating via register-settings.py --scope project-local --regenerate to /dev/stdout is byte-identical to the committed templates/.claude/settings.json (no make-template drift). (5) install.sh — all skill/hook lists flow through jq on modules.json (module_skills(), lines 72/186-188/286-287/302); no hardcoded bypass lists in code, only the two stale doc strings reported. Impact caveat on the MANIFEST candidates: no code consumes the md5/path lines (nana SKILL, generate-report.py, generate-workflow.py parse only '# name:' description comments, and tests/test_templates.sh checks only line count + descriptions), so the staleness is an integrity-record defect rather than a runtime breakage — but it means the kit's only checksum manifest has been unverifiable since Phase 63 and silently skipped Phase 81's additions, and no test guards it (the test_templates.sh:294 'MANIFEST freshness' name is misleading — it checks descriptions only). Shell note for orchestrator: repros use absolute /sbin/md5sum because plain md5/md5sum was PATH-invisible inside loop subshells in this sandbox; /sbin/md5sum output validated against known-good entries (Phase-63-untouched files match their recorded checksums).

## firing

### firing-enforce-spec-legacy-input-field-dormant
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-spec.sh
- claim: enforce-spec.sh parses only .input.file_path, a field current PreToolUse events no longer carry (path now lives at .tool_input.file_path), so the spec gate silently allows every write in production: the live-format hook logs every allow/block to .dev-wiki/enforcement.log yet its last record is 2026-05-25 across 15 days of daily Write/Edit traffic, while the field-free Stop sibling enforce-loop logged 329 records through 2026-06-09, and the .tool_input-fallback sibling stale-queue.sh kept appending through ~Jun 4; tests stay green only because tests/test_enforce.sh pipes the legacy {"input":{...}} shape.
- repro: `T=$(mktemp -d) && mkdir -p "$T/.dev-wiki" "$T/.claude" && touch "$T/.claude/enforce" && cd "$T" && printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py"}}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-spec.sh 2>/dev/null; rc=$?; cd /; rm -rf "$T"; test "$rc" -eq 2`

### firing-block-dangerous-bash-legacy-input-field-dormant
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/block-dangerous-bash.sh
- claim: block-dangerous-bash.sh parses only .input.command, so under the current PreToolUse schema (.tool_input.command) the dangerous-command blocker allows everything it exists to block — verified live: piping {"tool_input":{"command":"rm -rf /"}} exits 0 (allow) while the legacy {"input":{...}} shape exits 2; its own eval fixtures (eval/corpus/hook-block-*/scenario.json) and tests/test_tooluse_hooks.sh:43 pin the legacy shape, keeping the gate green while dormant.
- repro: `printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/block-dangerous-bash.sh 2>/dev/null; test $? -eq 2`

### firing-check-tests-were-run-phantom-tool-uses
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/check-tests-were-run.sh
- claim: check-tests-were-run.sh derives its only blocking signal from .tool_uses[], a field that exists in no Claude Code Stop event payload (real Stop input is session_id/transcript_path/hook_event_name/stop_hook_active), so HAS_PY_CHANGES is permanently "false" and the gate can never block; the field appears nowhere outside the repo's own tests/eval fixtures (git grep tool_uses → only tests/ and eval/ fabricate it), and .dev-wiki/enforcement.log contains zero check-tests-were-run records ever despite the hook logging unconditionally whenever .dev-wiki exists.
- repro: `cd /tmp && r=$(printf '{"session_id":"s","transcript_path":"/tmp/t.jsonl","hook_event_name":"Stop","stop_hook_active":false}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/check-tests-were-run.sh >/dev/null 2>&1; echo $?) && f=$(printf '{"tool_uses":[{"input":{"file_path":"src/x.py"}}]}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/check-tests-were-run.sh >/dev/null 2>&1; echo $?) && echo "documented-stop-shape=$r fabricated-tool_uses=$f" && { test "$f" -eq 0 || test "$r" -eq 2; }`

### firing-py-review-stop-phantom-tool-uses
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/py-review-stop.sh
- claim: py-review-stop.sh gates its review prompt on the same nonexistent Stop-event field .tool_uses[] (HAS_PY_CHANGES always false → always exits 0 silently), meaning the Phase-74 conversion from the unconditional prompt-type hook silently killed the self-review entirely — it can only fire on the fabricated shape piped by tests/test_long_cadence_hooks.sh:111 and never on a real Stop event.
- repro: `cd /tmp && r=$(printf '{"session_id":"s","transcript_path":"/tmp/t.jsonl","hook_event_name":"Stop","stop_hook_active":false}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/py-review-stop.sh >/dev/null 2>&1; echo $?) && f=$(printf '{"stop_hook_active":false,"tool_uses":[{"input":{"file_path":"src/x.py"}}]}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/py-review-stop.sh >/dev/null 2>&1; echo $?) && echo "documented-stop-shape=$r fabricated-tool_uses=$f" && { test "$f" -eq 0 || test "$r" -eq 2; }`

### firing-enforce-memory-legacy-input-field-dormant
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-memory.sh
- claim: enforce-memory.sh parses only .input.file_path (no .tool_input fallback), so even with both opt-in markers present (.claude/enforce-memory or ~/.claude/enforce-memory, which exists on this machine) the memory gate never blocks under the current PreToolUse schema — same root cause as enforce-spec, same legacy-shape-only test coverage.
- repro: `T=$(mktemp -d) && mkdir -p "$T/.dev-wiki" "$T/.claude" && touch "$T/.claude/enforce-memory" && cd "$T" && printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py"}}' | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-memory.sh 2>/dev/null; rc=$?; cd /; rm -rf "$T"; test "$rc" -eq 2`

### firing-dev-wiki-scope-check-legacy-input-field-dormant
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/dev-wiki-scope-check.sh
- claim: dev-wiki-scope-check.sh parses only .input.file_path, so the out-of-scope advisory never fires on current PreToolUse events — corroborated by transcripts: the newest of 76 session transcripts containing a genuine [dev-wiki:scope-check] emission is dated May 31, with zero emissions across ~10 days of heavy Phase 73-81 editing since, while Stop-hook [dev-wiki:stop] emissions continue through Jun 9.
- repro: `T=$(mktemp -d) && mkdir -p "$T/.dev-wiki" && printf -- '- [ ] T1 task | scope: `src/**` | success: `true`\n' > "$T/.dev-wiki/tasks.md" && cd "$T" && OUT=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/docs/x.py"}}' "$T" | bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/dev-wiki-scope-check.sh); rc=$?; cd /; rm -rf "$T"; echo "out=[$OUT]"; test -n "$OUT"`

### firing-post-commit-toplevel-exit-code-dormant
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/post-commit.sh
- claim: post-commit.sh requires a top-level .exit_code field that current PostToolUse(Bash) payloads do not carry (result data lives under .tool_response), so EXIT_CODE parses empty and the hook exits before ever writing .dev-wiki/.pending-commit or emitting [dev-wiki:post-commit] — transcripts confirm: 165 [dev-wiki:post-commit] emissions up to May 29, zero in any transcript since, despite near-daily commits through Jun 9; tests/test_tooluse_hooks.sh:93 keeps it green by fabricating top-level exit_code.
- repro: `T=$(mktemp -d) && mkdir -p "$T/h/.claude" && touch "$T/h/.claude/enforce" && cd "$T" && git init -q && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m test && mkdir .dev-wiki && printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"},"tool_response":{"stdout":"done","stderr":""}}' | HOME="$T/h" bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/post-commit.sh >/dev/null 2>&1; test -f "$T/.dev-wiki/.pending-commit"; rc=$?; cd /; rm -rf "$T"; test "$rc" -eq 0`

### firing-detect-loop-toplevel-exit-code-dormant
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/detect-loop.sh
- claim: detect-loop.sh greps the raw payload for a literal "exit_code" key that current PostToolUse(Bash) events do not contain anywhere, so EXIT_CODE is always empty and the loop advisory can never fire — transcripts show the last genuine [nana:loop] emission on May 29 and none since, consistent with the other exit_code consumer (post-commit) dying on the same date.
- repro: `T=$(mktemp -d) && mkdir -p "$T/h/.claude" "$T/.claude" && touch "$T/h/.claude/enforce" && cd "$T" && OUT=$(for i in 1 2 3; do printf '{"tool_name":"Bash","tool_input":{"command":"badcmd"},"tool_response":{"stdout":"","stderr":"boom"}}' | HOME="$T/h" bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/detect-loop.sh; done); cd /; rm -rf "$T"; echo "out=[$OUT]"; test -n "$OUT"`

### firing-post-commit-detect-loop-home-only-marker
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/post-commit.sh
- claim: post-commit.sh (line 10) and detect-loop.sh (line 27) gate on $HOME/.claude/enforce ONLY, while enforce-spec.sh:26 and enforce-loop.sh:28 use the dual project-OR-global check — so in a consuming project bootstrapped project-locally (template ships templates/.claude/enforce, copied by py-init/ts-init/install.sh --project-local) on a machine without a global install, these two hooks never fire even with correct payloads.
- repro: `T=$(mktemp -d) && mkdir -p "$T/h/.claude" "$T/.claude" "$T/.dev-wiki" && touch "$T/.claude/enforce" && cd "$T" && git init -q && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m test && printf '{"tool_input":{"command":"git commit -m test"},"exit_code":0}' | HOME="$T/h" bash /Users/jwang/nana-dev-kit/templates/.claude/hooks/post-commit.sh >/dev/null 2>&1; test -f "$T/.dev-wiki/.pending-commit"; rc=$?; cd /; rm -rf "$T"; test "$rc" -eq 0`

### firing-hook-harness-claude-project-dir-sandbox-escape
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/scripts/eval-runner.sh
- claim: Neither scripts/eval-runner.sh run_hook() (line 72, isolation = cd "$work_dir" only) nor any test-local run_hook (tests/test_tooluse_hooks.sh:16, test_long_cadence_hooks.sh:21, test_firing_log.sh:29) clears CLAUDE_PROJECT_DIR, while every Phase-79 hook begins with cd "${CLAUDE_PROJECT_DIR:-.}" — so whenever the variable is set in the invoking environment, hooks escape the mktemp fixture into the real project; the kit's real .dev-wiki/enforcement.log already holds 165 new-schema dev-wiki-scope-check records (phases 65-82, incl. 14 phase=unknown) that only template-version code running with cwd at a real repo could write, since the installed ~/.claude copy contains no logging at all.
- repro: `test "$(grep -c CLAUDE_PROJECT_DIR /Users/jwang/nana-dev-kit/scripts/eval-runner.sh)" -gt 0`

**Area notes:** Core finding: a runtime event-schema migration (~May 29-31 per transcript evidence) left every template hook that parses legacy fields production-dormant while the repo's tests/eval fixtures pin the same legacy shapes, so the firing-coverage gate stays green. Triangulation, all filesystem/git: (a) .dev-wiki/enforcement.log — old-schema enforce-loop (Stop, parses no tool fields) logs through Jun 9; old-schema enforce-spec (logs every allow incl. allowlisted paths) stops 2026-05-25; (b) 76 transcripts in ~/.claude/projects/-Users-jwang-nana-dev-kit — newest genuine emissions: [dev-wiki:post-commit] May 29, [nana:loop] May 29, [nana:enforce-spec] May 29, [dev-wiki:scope-check] May 31, while [dev-wiki:stop] appears in the newest transcript (Jun 9); (c) .dev-wiki/.stale-queue (hook WITH .tool_input fallback) appended Phase-78 files ~Jun 2-4, i.e. PostToolUse events still delivered after the .input-only/.exit_code consumers died — isolating the cause to field shape, not hook delivery. Clean areas (no candidates manufactured): test_hook_firing_coverage.sh exemption allow-list is EMPTY (EXEMPT_EXPECTED=0) so no flaggable exemptions; denominator floor 21 matches modules.json exactly (18 command hooks + 3 session-start.d curators, all type-less = command, prompt_set empty); no advisory hook or curator contains a non-zero exit (grep 'exit [1-9]' over all advisory hooks + curators: zero matches) and curators are sourced by session-start.sh lines 10-12; context-size-check (UserPromptSubmit) correctly reads .transcript_path; templates ship the .claude/enforce marker. Secondary (folded, not separate candidates): block-dangerous-bash regex gaps — 'rm -fr /' bypasses (regex requires r before f) and 'git push --force-with-lease' is blocked by the --force pattern while the block message recommends it — both moot until the dormancy candidate is fixed. Environment observations (user install state, NOT repo defects, but they shape the log evidence): all 13 live ~/.claude/hooks are stale pre-Phase-65/79 copies (every diff non-empty) and 6 project-local hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, py-review-stop, scan-secrets) are registered nowhere live, so block-dangerous-bash/check-tests/py-review have zero live exposure on this machine regardless of the schema defect. Unresolved residue for orchestrator: 4 enforcement.log scope-check records carry phase=82 while .claude/rules/active-phase.md reads Phase 81 — consistent with a concurrent Phase-82 context (worktree or briefly-updated active-phase.md) running template hooks via the CLAUDE_PROJECT_DIR escape (candidate 10); CLAUDE_PROJECT_DIR is unset in subagent Bash shells (verified) so the exact triggering context for the 165-record pollution is unconfirmed, but no other vector matches template-version code + real-repo cwd.

## companions

### companions-companion-orphan-stale-queue-spec
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-wiki/stale-queue-spec.md
- claim: templates/.claude/skills/dev-wiki/stale-queue-spec.md is an orphan companion: no SKILL.md, companion, hook, script, test, or modules.json entry references it (referenced_at says only "companion"), so it ships to ~/.claude as dead documentation.
- repro: `grep -rn "stale-queue-spec" /Users/jwang/nana-dev-kit/templates /Users/jwang/nana-dev-kit/scripts /Users/jwang/nana-dev-kit/tests /Users/jwang/nana-dev-kit/install.sh /Users/jwang/nana-dev-kit/Makefile /Users/jwang/nana-dev-kit/modules.json 2>/dev/null | grep -v "skills/dev-wiki/stale-queue-spec.md"`

### companions-companion-orphan-registry-schema
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/knowledge-wiki/registry-schema.md
- claim: templates/.claude/skills/knowledge-wiki/registry-schema.md is an orphan companion: nothing in templates/scripts/tests/install.sh/Makefile/modules.json references it (not even wiki-registry/SKILL.md, its natural consumer).
- repro: `grep -rn "registry-schema" /Users/jwang/nana-dev-kit/templates /Users/jwang/nana-dev-kit/scripts /Users/jwang/nana-dev-kit/tests /Users/jwang/nana-dev-kit/install.sh /Users/jwang/nana-dev-kit/Makefile /Users/jwang/nana-dev-kit/modules.json 2>/dev/null | grep -v "skills/knowledge-wiki/registry-schema.md"`

### companions-companion-orphan-session-context
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/knowledge-wiki/session-context.md
- claim: templates/.claude/skills/knowledge-wiki/session-context.md is an orphan companion: no file in templates/scripts/tests/install.sh/Makefile/modules.json references the name session-context.
- repro: `grep -rn "session-context" /Users/jwang/nana-dev-kit/templates /Users/jwang/nana-dev-kit/scripts /Users/jwang/nana-dev-kit/tests /Users/jwang/nana-dev-kit/install.sh /Users/jwang/nana-dev-kit/Makefile /Users/jwang/nana-dev-kit/modules.json 2>/dev/null | grep -v "skills/knowledge-wiki/session-context.md"`

### companions-stale-refat-file-prompt-step20
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-scan/file-prompt.md
- claim: dev-scan/file-prompt.md frontmatter says referenced_at: "Step 20" but dev-scan/SKILL.md has no Step 20 at all (steps end at Step 7); the actual reference is inside Step 6 at SKILL.md line 201.
- repro: `sh -c 'grep -q "referenced_at: \"Step 20\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-scan/file-prompt.md || exit 0; grep -qE "^#+.*Step 20" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-scan/SKILL.md'`

### companions-stale-refat-empirical-anchor-step15
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-health/empirical-anchor-spec.md
- claim: wiki-health/empirical-anchor-spec.md frontmatter says referenced_at: "Step 15" but wiki-health/SKILL.md has no Step 15 (steps end at Step 5); the actual reference is inside Step 3 at SKILL.md line 146.
- repro: `sh -c 'grep -q "referenced_at: \"Step 15\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-health/empirical-anchor-spec.md || exit 0; grep -qE "^#+.*Step 15" /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-health/SKILL.md'`

### companions-stale-refat-retro-check-step0
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/retro-check.md
- claim: dev-debrief/retro-check.md frontmatter says referenced_at: "Step 0" but dev-debrief/SKILL.md has no Step 0 heading; the actual reference is in Step 20 (Retro Check) at SKILL.md line 265.
- repro: `sh -c 'grep -q "referenced_at: \"Step 0\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/retro-check.md || exit 0; grep -qE "^#+.*Step 0:" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/SKILL.md'`

### companions-stale-refat-artifact-writer-step13
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/artifact-writer-prompt.md
- claim: dev-plan/artifact-writer-prompt.md frontmatter says referenced_at: "Step 13", but Step 13 is now the Phase-81 Assumption-Approval Gate and contains no artifact-writer reference — the actual reference is the orchestrator dispatch block at SKILL.md line 55, making the pointer actively misleading post-rewrite.
- repro: `sh -c 'grep -q "referenced_at: \"Step 13\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/artifact-writer-prompt.md || exit 0; awk "/^### Step 13:/,/^### Step 14:/" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/SKILL.md | grep -q artifact-writer-prompt'`

### companions-stale-refat-delivery-flow-step2
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/delivery-flow.md
- claim: dev-debrief/delivery-flow.md frontmatter says referenced_at: "Step 2", but Step 2 (Read Existing State) contains no delivery-flow reference — the actual reference is the 'After executor returns' delivery-gate section at SKILL.md line 60.
- repro: `sh -c 'grep -q "referenced_at: \"Step 2\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/delivery-flow.md || exit 0; awk "/^### Step 2:/,/^### Step 3:/" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/SKILL.md | grep -q delivery-flow'`

### companions-stale-refat-executor-prompt-step8
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/executor-prompt.md
- claim: dev-debrief/executor-prompt.md frontmatter says referenced_at: "Step 8", but Step 8 (Create Journal Entry) contains no executor-prompt reference — the actual reference is the orchestrator 'How to dispatch' block at SKILL.md line 38.
- repro: `sh -c 'grep -q "referenced_at: \"Step 8\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/executor-prompt.md || exit 0; awk "/^### Step 8:/,/^### Step 9:/" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-debrief/SKILL.md | grep -q executor-prompt'`

### companions-stale-refat-state-loader-step3
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/state-loader-prompt.md
- claim: dev-plan/state-loader-prompt.md frontmatter says referenced_at: "Step 3", but Step 3 (Load Wiki State) contains no state-loader-prompt reference — the actual reference is the orchestrator dispatch block at SKILL.md line 27.
- repro: `sh -c 'grep -q "referenced_at: \"Step 3\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/state-loader-prompt.md || exit 0; awk "/^### Step 3:/,/^### Step 4:/" /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/SKILL.md | grep -q state-loader-prompt'`

### companions-stale-refat-research-agent-step3
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-bootstrap/research-agent-prompt.md
- claim: wiki-bootstrap/research-agent-prompt.md frontmatter says referenced_at: "Step 3", but wiki-bootstrap Step 3 (Present topic plan) contains no research-agent-prompt reference — the actual reference is inside Step 2.5 (Research Phase) at SKILL.md line 126.
- repro: `sh -c 'grep -q "referenced_at: \"Step 3\"" /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-bootstrap/research-agent-prompt.md || exit 0; awk "/^### Step 3:/,/^### Step 4:/" /Users/jwang/nana-dev-kit/templates/.claude/skills/wiki-bootstrap/SKILL.md | grep -q research-agent-prompt'`

### companions-test-companions-no-refat-orphan-coverage
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/tests/test_companions.sh
- claim: tests/test_companions.sh validates only parent: (Direction A) and Read-pointer resolution (Direction B); it never checks referenced_at validity nor orphan companions, which is exactly the gap that let 8 stale referenced_at values and 3 orphan files accumulate while the test passes 2/2.
- repro: `grep -q "referenced_at" /Users/jwang/nana-dev-kit/tests/test_companions.sh`

**Area notes:** Core integrity is CLEAN: all 91 companions have YAML frontmatter with parent: matching their skill dir and a referenced_at: field; all 83 SKILL.md Read pointers resolve in templates; all companion-to-companion pointers resolve; test_companions.sh passes 2/2. No high/medium findings — everything filed is metadata hygiene (8 stale referenced_at values), dead shipped docs (3 orphans), and the test gap that explains both. Repro convention: every command exits non-zero iff the defect is real; the stale-refat repros are guarded on the current frontmatter value so they self-kill if the frontmatter is fixed. dev-init/templates/AGENTS.md and project-CLAUDE.md carry parent: dev-init with referenced_at: 'companion' — consistent with the test's first-path-component rule, not flagged. The dispatch-block trio (artifact-writer/state-loader/executor-prompt) shares one root cause: the orchestrator refactor moved subagent-prompt reads into dispatch blocks without updating frontmatter — a single fix pass covers candidates 7, 9, 10. referenced_at is consumed by no runtime code, hence uniform low severity.

## schema

### schema-project-local-hook-list-stale-docs
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md's --project-local row and install.sh's own usage header both document the pre-rescope 6-hook set (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start) while install.sh --project-local actually installs all 17 project-scoped hooks from modules.json (including behavior-changing enforce-spec/enforce-memory/block-dangerous-bash plus the .claude/enforce marker), so 11 installed hooks are undocumented at the point of decision.
- repro: `bash -c 'cd /Users/jwang/nana-dev-kit; ok=0; row="$(grep -- "--project-local" README.md | head -1) $(sed -n "10,12p" install.sh)"; for s in $(jq -r ".hooks[] | select(.scope==\"project\") | .script" modules.json); do case "$row" in *"${s%.sh}"*) ;; *) echo "stale doc: $s installed by --project-local but absent from README row and install.sh header"; ok=1;; esac; done; exit $ok'`

### schema-readme-eval-category-counts-stale
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md line 80 claims eval category breakdown 'skill artifact validation (8)' and 'context injection (4)' but the actual scenario JSON category fields count skill=6 and context=6 (hook=34 and lifecycle=6 are correct); the total coincidentally still sums to 52 so the headline '52 scenarios' masks the rot.
- repro: `bash -c 'cd /Users/jwang/nana-dev-kit; c() { find eval/corpus -name "*.json" -exec jq -r .category {} \; | grep -c "^$1$"; }; grep -q "skill artifact validation ($(c skill))" README.md && grep -q "context injection ($(c context))" README.md'`

### schema-wk-prune-cites-absent-spec-precedence-rule
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-wiki/working-knowledge-spec.md
- claim: templates/.claude/hooks/session-start.d/wk-prune.sh (lines 175 and 225) justifies its lines-over-cap-while-entries-under-cap no-op behavior by citing a 'spec: cap precedence' rule, but templates/.claude/skills/dev-wiki/working-knowledge-spec.md — declared the 'Policy single source of truth' at wk-prune.sh line 15 — contains no precedence statement and instead says the curator 'brings the file back within bounds' of a '210-line hard cap', so the declared single source and the implementation describe different line-cap semantics.
- repro: `bash -c 'cd /Users/jwang/nana-dev-kit; ! grep -q "cap precedence" templates/.claude/hooks/session-start.d/wk-prune.sh || grep -qi "precedence" templates/.claude/skills/dev-wiki/working-knowledge-spec.md'`

**Area notes:** CLEAN sub-areas (verified, no candidate): (1) Ledger schema single-source HOLDS — the '## Ledger schema' block exists only in scripts/check-assumption-ledger.sh; assumption-gate.md, debrief-finalization.md, and the ledger file header all reference it by path; assumption-gate-example.md contains positions narrative only, no row-format copy; live .dev-wiki/assumption-ledger.md rows conform to the validator's field regexes. (2) Hook registration single-source HOLDS — modules.json's 17 project-scoped hooks diff-match the generated templates/.claude/settings.json exactly (event+matcher+script); no second place defines the registration schema (the README/install.sh finding filed is about the --project-local hook LIST, not the schema format). (3) Caps are consistent everywhere stated: CLAUDE.md 80-line cap (4 places, all 80); active-knowledge 30-soft/40-hard (3 places agree); working-knowledge 100-entries/210-lines (spec + wk-prune.sh defaults agree — the filed candidate is about line-cap SEMANTICS, not the value); SKILL.md 350-line caps live only in tests/test_templates.sh. (4) Task schema: task-schema.md is the sole repo source; ~/.claude/rules/dev-wiki-hooks.md is user-local and was NEVER in this repo's git history, so its task-format prose is outside kit management (handoff note: it treats `success:` as optional while task-schema.md marks it Required — unfixable in-repo). Minor non-candidate rot: task-schema.md claims it is 'Consumed by ... dev-check (validation)' but templates/.claude/skills/dev-check/ contains zero references to it. (5) Counts: 52 scenario total ✓ (52 corpus dirs), 20 test scripts ✓, no hardcoded 52 in Makefile/eval-runner (computed). HANDOFF to docs area: README '7 Layers' table row 3 says '11 lifecycle hooks' — likely stale vs 17 project + 1 global, but the row's referent (scaffolded-project layer vs kit) is ambiguous so I did not file it; also README --core-only row says 'Identity rules + memory server only' while line 21-area text elsewhere says '+ spec' — not checked.

## drift

### drift-stale-global-hooks-invisible-to-drift-check
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh
- claim: Eleven hook scripts registered in global ~/.claude/settings.json (enforce-spec, enforce-loop, enforce-memory, detect-loop, dev-wiki-scope-check, post-commit, post-compact, pre-compact, session-start, session-stop, stale-queue) all differ from their templates/ copies — they are pre-Phase-65/79 stale versions that EXECUTE on every matching event in every project — yet check-install-drift.sh reports 0 drift because it compares only scope:global hooks, and its header rationale ('project-scoped hooks ... install per-project, NOT to ~/.claude, so their drift is out of this set by design') is factually false for the live install where these files both exist in ~/.claude/hooks and are registered in global settings.json.
- repro: `bash -c 'jq -r ".hooks | to_entries[] | .value[] | .hooks[]?.command" "$HOME/.claude/settings.json" | grep -q "hooks/enforce-spec.sh" && ! cmp -s "$HOME/.claude/hooks/enforce-spec.sh" /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-spec.sh && [ "$(bash /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh --count)" = "0" ] && exit 1; exit 0'`

### drift-rescoped-hooks-missing-from-ghost-cleanup
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/modules.json
- claim: Phase 79 rescoped 11 hooks from global to project scope in modules.json, but ghost_cleanup lists only dev-wiki-post-commit, so re-running install.sh neither updates nor removes the stale ~/.claude/hooks copies nor deregisters them from global settings.json — the drift checker's advertised remedy ('run install.sh to sync') cannot heal this class, leaving pre-Phase-65 enforcement hooks firing globally (and double-firing alongside fresh project-local copies in scaffolded projects).
- repro: `bash -c 's=$(jq -r ".hooks[] | select(.script==\"enforce-spec.sh\") | .scope" /Users/jwang/nana-dev-kit/modules.json); g=$(jq -r ".ghost_cleanup | index(\"enforce-spec\")" /Users/jwang/nana-dev-kit/modules.json); if [ "$s" = "project" ] && [ -f "$HOME/.claude/hooks/enforce-spec.sh" ] && [ "$g" = "null" ]; then exit 1; fi; exit 0'`

### drift-session-start-foreign-lineage-globally-registered
- severity (agent est.): medium
- file: /Users/jwang/.claude/hooks/session-start.sh
- claim: The installed ~/.claude/hooks/session-start.sh matches NO version of templates/.claude/hooks/session-start.sh ever committed to this repo (closest committed version differs by 42 lines; content is old '[dev-wiki]'-prefixed pre-monorepo lineage lacking all post-Phase-15 [nana:] features) yet it is registered in global settings.json and runs at every SessionStart — the only globally-executing kit-dir file with unverifiable provenance; the other 10 stale hooks each byte-match a committed ancestor (detect-loop=ef91738, enforce-spec/enforce-loop=c6ee854, enforce-memory=dac7c90, post-commit/stale-queue=7310391, post-compact/session-stop=48c4d3d, pre-compact=04d0ba8, dev-wiki-scope-check=ef9f6d0).
- repro: `bash -c 'for c in $(git -C /Users/jwang/nana-dev-kit log --format=%H --all -- templates/.claude/hooks/session-start.sh); do git -C /Users/jwang/nana-dev-kit show "${c}:templates/.claude/hooks/session-start.sh" 2>/dev/null | cmp -s - "$HOME/.claude/hooks/session-start.sh" && exit 0; done; jq -r ".hooks | to_entries[] | .value[] | .hooks[]?.command" "$HOME/.claude/settings.json" | grep -q "session-start.sh" && exit 1; exit 0'`

### drift-installed-only-skill-residue-invisible
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh
- claim: check-install-drift.sh enumerates files from the templates/ side only (find "$sdir" at line 85), so installed-only residue inside COMPARED skill dirs is invisible — six Phase-64-cut heuristic companions (dev-plan/heuristic-matcher.md, heuristic-lifecycle.md, heuristic-counter-update.md, heuristic-judge-prompt.md, self-dialogue-prompt.md, dev-debrief/heuristic-capture.md) survive in ~/.claude with 0 drift reported, while the header claims the set is 'every file under each installed skill dir' — a one-directional implementation contradicting its own documentation.
- repro: `bash -c '[ -f "$HOME/.claude/skills/dev-plan/heuristic-matcher.md" ] && [ ! -f /Users/jwang/nana-dev-kit/templates/.claude/skills/dev-plan/heuristic-matcher.md ] && [ "$(bash /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh --count)" = "0" ] && exit 1; exit 0'`

### drift-memory-server-omission-undocumented
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh
- claim: install.sh copy-verbatim-manages ~/.claude/memory_server/*.py + requirements.txt (lines 235-237) but check-install-drift.sh never references memory_server and its header comment does not document the omission — drift in the vendored MCP memory server (currently in sync, so latent) would be invisible by design and undocumented.
- repro: `bash -c 'grep -q "memory_server" /Users/jwang/nana-dev-kit/install.sh && ! grep -q "memory_server" /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh && exit 1; exit 0'`

### drift-dead-settings-json-exclude-entry
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh
- claim: The EXCLUDE allow-list entry "settings.json" (line 38) is dead code: every REL_FILES addition is prefixed skills/, hooks/, or rules/, so the bare relative path settings.json can never enter the comparison set and the exclusion never matches anything — misleading for a list whose stated purpose is guarding against scope-shrink.
- repro: `bash -c 'bash /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh --excludes | grep -qx "settings.json" && ! grep "REL_FILES+=" /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh | grep -qv -e "skills/" -e "hooks/" -e "rules/" && exit 1; exit 0'`

**Area notes:** CURRENT STATE: check-install-drift.sh exits 0, --count prints 0 — the compared set (26 modules.json skills present in both trees, context-size-check.sh, rules/nana-soul.md + file-lifecycle.md) is byte-synced. RETRO-AUDIT VERDICT (the 6 resynced files): the drift set is EXACTLY the union of templates-skill changes in cc6a3ae (Phase 79: dev-plan/SKILL.md, active-knowledge-transition.md) and e4e6e07 (Phase 81: 5 files, overlapping dev-plan/SKILL.md) = 6 files, no more, no fewer. Sync-point window pinned to [add2ee7 (Phase 75), cc6a3ae): add2ee7's other files (delivery-flow.md, executor-prompt.md) did NOT drift (so install >= add2ee7), active-knowledge-transition.md DID (so install < cc6a3ae). Pre-resync content is unrecoverable (~/.claude/backups holds only .claude.json backups; install.sh has no backup logic), so a hot-fix inside those exact 6 files cannot be strictly ruled out — but risk is LOW: the set matches a committed-window explanation exactly, and the still-inspectable sibling artifacts (11 stale hooks) show the same stale-ancestor pattern, 10/11 byte-matching committed versions. EXCLUDE-LIST ASSESSMENT: rules/nana-personal.md legit (user-customized, differs as expected); rules/py-session-state.md legit (not installed to ~/.claude/rules — confirmed absent); settings.json entry is dead code (candidate dead-settings-json-exclude-entry). OMITTED CLASSES: project-scope hooks omission IS documented in the header but its premise is false on this machine (candidates 1-3); installed-only files in compared skill dirs (candidate 4); memory_server (candidate 5, undocumented, currently in sync); MANIFEST is templates-only, never installed, /nana reads it from the repo via kit path marker — not a gap. ORPHANS in kit-managed dirs (list only, per instructions): ~/.claude/skills/wiki-consolidate/ (5 files; deleted from templates at 7f2200e Phase 63 'quarantine deadweight', still installed AND still an active registered skill), 6 heuristic-era companions (dev-plan: heuristic-matcher.md, heuristic-lifecycle.md, heuristic-counter-update.md, heuristic-judge-prompt.md, self-dialogue-prompt.md; dev-debrief: heuristic-capture.md — cut Phase 64), ~/.claude/rules/dev-wiki-hooks.md (never present in ANY commit of this repo at any path, yet loaded into every session as a global rule), plus inert __pycache__/*.pyc under wiki-index/ and wiki-consolidate/. TOOLING CAVEAT for the orchestrator: repros are wrapped in bash -c because the interactive shell is zsh, where \"$c:templates/...\" silently applies the :t history modifier and corrupts git show paths (this produced false NO-MATCH results in my first provenance scan; fixed with ${c}:)."

## coverage

### coverage-delivery-report-script-structural-only
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/scripts/generate-delivery-report.py
- claim: scripts/generate-delivery-report.py is invoked at every delivery gate (templates/.claude/skills/dev-debrief/delivery-flow.md:12) but has zero functional tests — the only tests/ mention is an assert_file_exists existence check (test_templates.sh:388), violating the functional-smoke invariant for a component on the registered debrief path.
- repro: `grep -rEn '(python3|bash|run).*generate-delivery-report' /Users/jwang/nana-dev-kit/tests/`

### coverage-eval-runner-untested-no-negative-control
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/scripts/eval-runner.sh
- claim: scripts/eval-runner.sh, the scorer behind 'make eval' (Makefile:41) whose 52/52 result is used as a phase gate, has no functional test anywhere in tests/ and no negative control — a counting/classifier bug in the runner would silently green the eval metric (the exact vacuous-detector class the firing-coverage gate guards against for itself).
- repro: `grep -rln 'eval-runner' /Users/jwang/nana-dev-kit/tests/`

### coverage-generate-report-script-untested
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/generate-report.py
- claim: scripts/generate-report.py is wired as a Makefile target (Makefile:44) but has no test mention of any kind in tests/ (functional or structural).
- repro: `grep -rln 'generate-report.py' /Users/jwang/nana-dev-kit/tests/`

### coverage-generate-workflow-script-untested
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/generate-workflow.py
- claim: scripts/generate-workflow.py is wired as a Makefile target (Makefile:47) but has no test mention of any kind in tests/ (functional or structural).
- repro: `grep -rln 'generate-workflow' /Users/jwang/nana-dev-kit/tests/`

### coverage-harness-audit-script-untested-unwired
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/scripts/harness-audit.sh
- claim: scripts/harness-audit.sh has no functional test in tests/ AND no live consumer (not referenced in Makefile, modules.json, or templates/ — only historical .dev-wiki articles and a prose pointer in a global rules file), making it both untested and possibly deadweight.
- repro: `grep -rln 'harness-audit' /Users/jwang/nana-dev-kit/tests/ /Users/jwang/nana-dev-kit/Makefile /Users/jwang/nana-dev-kit/modules.json /Users/jwang/nana-dev-kit/templates/`

**Area notes:** Hook layer is CLEAN: tests/test_hook_firing_coverage.sh passes 5/5 with coverage 21/21, EXEMPT list is empty (EXEMPT_EXPECTED=0) so item (3) of the audit is vacuously satisfied — no exemption rationales to re-validate; the gate has a permanent negative control proving the detector is non-vacuous. All `# fires:` declarations cross-checked against the 18 command hooks + 3 curators. Inventory discrepancy vs the brief: session-start.d has THREE curators (cognitive-readiness.sh, memory-nudge.sh, wk-prune.sh), not 2 — all three covered, and the gate's REQUIRED_FLOOR=21 already encodes 3. scripts/ layer carries all the gaps: 5 of 10 scripts/ entries are double-blind (no functional test, no eval scenario); install.sh, register-settings.py, check-install-drift.sh, check-assumption-ledger.sh, signal-richness-probe.sh, sync-rules.sh are all functionally tested (verified invocation+assertion context, not just mentions). Eval corpus (52 scenarios) covers 13 hooks; hooks without eval scenarios (dev-wiki-scope-check, stale-queue, session-stop, post-compact, py-review-stop, the curators) ALL have firing tests, so none are double-blind — not raised as candidates. The 3 Python scripts ast.parse clean, so the candidates are coverage-class defects (silent-breakage exposure), not current breakages. Caveat on severity: a delivery-report breakage would surface at the next delivery gate run (every phase), so the 8-33-phase silent-breakage history argues medium, not high.

## docs

### docs-readme-headline-skill-hook-counts
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md line 3 claims the kit "Installs 22 skills, 11 hooks" (and the Layer-3 row repeats "11 lifecycle hooks") but disk reality is 25 skill dirs and 18 hook scripts (17 project-scoped + 1 global-scoped per modules.json) — 11 matches no current count.
- repro: `cd /Users/jwang/nana-dev-kit && [ "$(grep -m1 -oE 'Installs [0-9]+ skills' README.md)" = "Installs $(ls -d templates/.claude/skills/*/ | wc -l | tr -d ' ') skills" ]`

### docs-readme-enforcement-installs-globally
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md line 95 says "Enforcement hooks install globally and activate per-project via a marker file", but modules.json scopes enforce-spec/enforce-loop/enforce-memory/detect-loop as project and install.sh's global path copies only scope==global hooks (context-size-check.sh alone), so a user following the README quick start plus `touch .claude/enforce` gets NO enforcement.
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q 'Enforcement hooks install globally' README.md || jq -e '[.hooks[] | select(.script|test("^(enforce|detect)")) | select(.scope=="global")] | length > 0' modules.json >/dev/null; }`

### docs-readme-project-local-six-hooks
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md --project-local table row says it installs 6 named per-project hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start), but install.sh --project-local installs ALL project-scoped hooks from modules.json, which is 17.
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q 'audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start' README.md || [ "$(jq '[.hooks[]|select(.scope=="project")]|length' modules.json)" -eq 6 ]; }`

### docs-readme-eval-category-breakdown
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/README.md
- claim: README.md line 80 claims eval categories "hook fidelity (34), skill artifact validation (8), lifecycle compliance (6), context injection (4)" but eval/corpus prefix counts are hook=34, skill=6, lifecycle=6, context=6 (total 52 only coincidentally matches).
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q 'skill artifact validation (8), lifecycle compliance (6), context injection (4)' README.md || { [ "$(ls eval/corpus | grep -c '^skill-')" -eq 8 ] && [ "$(ls eval/corpus | grep -c '^context-')" -eq 4 ]; }; }`

### docs-manifest-md5-inventory-stale
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/skills/MANIFEST
- claim: MANIFEST's md5 inventory is missing the two Phase-81 dev-plan companions (assumption-gate.md, assumption-gate-example.md) and ~103 of its ~123 checksum lines no longer match disk (verified via per-line md5 -q comparison; e.g. dev-plan/SKILL.md manifest=45277c93... actual=386a291d...), making the checksum section dead data; the 25 description lines are complete and match all 25 skill dirs.
- repro: `cd /Users/jwang/nana-dev-kit && { ! test -f templates/.claude/skills/dev-plan/assumption-gate.md || grep -q 'dev-plan/assumption-gate.md' templates/.claude/skills/MANIFEST; }`

### docs-architecture-26-dirs-phantom-wiki-consolidate
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/.dev-wiki/_ARCHITECTURE.md
- claim: _ARCHITECTURE.md claims "26 dirs + MANIFEST" (lines 40, 64, 75, 90) and its line-42 enumeration includes wiki-consolidate, but that skill dir was removed in Phase 63 (commit 7f2200e "quarantine deadweight") — the TRUE count is 25 dirs, and 26 was only correct when wiki-consolidate existed.
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q 'wiki-{absorb,add,bootstrap,consolidate' .dev-wiki/_ARCHITECTURE.md || test -d templates/.claude/skills/wiki-consolidate; }`

### docs-architecture-hook-counts-triple-drift
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/.dev-wiki/_ARCHITECTURE.md
- claim: _ARCHITECTURE.md hook counts are wrong three ways: line 73 says "17 files + session-start.d/ with 2 modules" (actual: 18 top-level .sh — py-review-stop.sh added Phase 74 commit 9c70a70 — and 3 session-start.d modules: cognitive-readiness.sh, memory-nudge.sh, wk-prune.sh), line 37 says "13 lifecycle hooks", and line 64 says "~/.claude/hooks/ (11 global hooks)" vs 1 global-scoped hook in modules.json (line 56's "--project-local installs 6 per-project hooks" is also stale vs 17).
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q '17 files + session-start.d/ with 2 modules' .dev-wiki/_ARCHITECTURE.md || { [ "$(ls templates/.claude/hooks/*.sh | wc -l | tr -d ' ')" -eq 17 ] && [ "$(ls templates/.claude/hooks/session-start.d/*.sh | wc -l | tr -d ' ')" -eq 2 ]; }; }`

### docs-architecture-eval-50-vs-52
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/.dev-wiki/_ARCHITECTURE.md
- claim: _ARCHITECTURE.md line 58 (Entry Points: eval-runner) claims "50 scenarios in 4 categories" while eval/corpus holds 52 scenario dirs, and line 7 contradicts itself in one paragraph ("50 eval scenarios" in the file inventory vs "52 eval scenarios via make eval").
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q '50 scenarios in 4 categories' .dev-wiki/_ARCHITECTURE.md || [ "$(ls eval/corpus | wc -l | tr -d ' ')" -eq 50 ]; }`

### docs-agents-template-where-to-look-404
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/AGENTS.md
- claim: templates/AGENTS.md "Where to Look" (lines 63-65) points the agent at docs/architecture.md, docs/testing.md, docs/security.md, but py-init copies AGENTS.md verbatim (SKILL.md line 94) and nothing in templates/ or the py-init scaffold creates a docs/ directory, so every freshly scaffolded project ships always-loaded pointers to three files that 404.
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q 'docs/architecture.md' templates/AGENTS.md || test -e templates/docs/architecture.md || grep -rq 'docs/architecture' templates/.claude/skills/py-init/; }`

### docs-readme-status-flag-undocumented
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/README.md
- claim: install.sh parses a --status flag (line 38, also shown in its own usage string at line 59) but README.md's Installer Flags table documents only --all/--core-only/--no-python/--no-typescript/--project-local/--dry-run and never mentions --status.
- repro: `cd /Users/jwang/nana-dev-kit && { ! grep -q -- '--status' install.sh || grep -q -- '--status' README.md; }`

**Area notes:** TRUE counts resolved (off-by-ones the orchestrator asked about): skill dirs under templates/.claude/skills/ = 25 (+MANIFEST file); _ARCHITECTURE's \"26\" was correct only while wiki-consolidate existed — it was deleted in Phase 63 (commit 7f2200e) but lines 40/42/64/75/90 were never updated. Top-level hook scripts = 18 (py-review-stop.sh added Phase 74, commit 9c70a70, after the \"17 files\" claim was written) + 3 session-start.d modules (doc says 2; cognitive-readiness.sh missing from its list); modules.json registers exactly 18 hooks: 17 project-scoped + 1 global-scoped (context-size-check.sh). Eval corpus = 52 dirs: hook 34, skill 6, lifecycle 6, context 6. Tests = 20 test_*.sh + helpers.sh (README \"20 scripts\" and _ARCHITECTURE line 33 correct; _ARCHITECTURE line 72 \"19 scripts\" is internally inconsistent but inside the same already-flagged table as other counts — folded into existing candidates rather than a separate one). CLEAN areas: README Getting-started commands all exist as skill dirs (/nana-init, /py-init, /ts-init, /dev-init, /wiki-init); git clone URL matches `git remote -v` (j-wanger/nana-dev-kit); README-referenced paths exist (scripts/eval-runner.sh, scripts/sync-rules.sh, benchmark/README.md; .pre-commit-config.yaml and workflows/ci.yml exist under templates/ which is the intended scaffold context); make targets report/sync-rules/eval/test all exist; MANIFEST description lines complete: 25 descriptions, one per existing dir, no orphan descriptions for nonexistent skills; install.sh flag set matches README except undocumented --status; eval total \"52\" in README is correct (only the per-category split is wrong). Caveats: the MANIFEST self-entry (first line) is the md5 of an empty string — inherently unverifiable self-hash, not filed as a candidate. Severity call on readme-enforcement-installs-globally: filed high because a user following README's documented flow (global install + touch .claude/enforce) gets zero enforcement — install.sh's own summary text contradicts the README (\"enforcement hooks install per-project via /py-init or --project-local\"). All repro commands are of the form `! grep -q '<claim text>' <doc> || <assert claim true on disk>`: they exit non-zero now, and exit 0 once the doc text is fixed (or if a candidate were false), per the dies-at-reproduction requirement. No files were written during this audit; an early attempted /tmp redirect errored harmlessly and was abandoned.

## usage

### usage-stale-global-hooks-installed
- severity (agent est.): high
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/session-start.sh
- claim: 11 of the 12 hook scripts registered in ~/.claude/settings.json (the copies the kit's own sessions actually run, since nana-dev-kit has no project-local .claude/settings.json or hooks/) differ from their templates/ sources — session-start.sh is a pre-Phase-55 35-line version (no .session-start-ts write, no session-start.d sourcing, no gate/recovery/drift checks), and all 11 date May 28, predating the Phase-65 log_firing substrate.
- repro: `diff -q /Users/jwang/.claude/hooks/session-start.sh /Users/jwang/nana-dev-kit/templates/.claude/hooks/session-start.sh`

### usage-drift-checker-blind-to-registered-hooks
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/scripts/check-install-drift.sh
- claim: scripts/check-install-drift.sh --count reports 0 while 11 hook scripts that ARE registered and firing from ~/.claude/hooks are stale, because the comparator only covers scope:global hooks (context-size-check.sh) by design — the exclusion assumes project-scoped hooks never run from ~/.claude, but ~/.claude/settings.json registers them there.
- repro: `sh -c 'test "$(/Users/jwang/nana-dev-kit/scripts/check-install-drift.sh --count)" != "0" || diff -q /Users/jwang/.claude/hooks/enforce-loop.sh /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-loop.sh'`

### usage-session-start-ts-stale-in-kit
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/session-start.sh
- claim: ~/.claude/.session-start-ts was last written 2026-06-04 09:42 (edge-screener's project-local session-start.sh) while kit sessions ran through 2026-06-09 (.dev-wiki/.session-end mtime Jun 9 14:29) — the registered global session-start.sh never writes it, so the dev-debrief cooldown advisory's session anchor is 5 days stale in the kit and the wk-prune/memory-nudge/cognitive-readiness session-start.d modules never run in kit sessions.
- repro: `test "$(stat -f %Sm -t %F /Users/jwang/.claude/.session-start-ts)" = "$(stat -f %Sm -t %F /Users/jwang/nana-dev-kit/.dev-wiki/.session-end)"`

### usage-audit-log-model-field-always-unknown
- severity (agent est.): medium
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/audit-log.sh
- claim: audit-log.sh's stated forensic purpose (which MODEL edited which file) yields no data in real use: all 920 rows in the one real audit trail (/Users/jwang/edge-screener/.nana/audit.jsonl, 2026-05-31..06-03) have model="unknown" because the hook reads ${CLAUDE_MODEL:-unknown} and nothing in the environment sets CLAUDE_MODEL (the only repo reference to that variable is audit-log.sh itself; the model is not in the hook stdin JSON either).
- repro: `jq -r '.model' /Users/jwang/edge-screener/.nana/audit.jsonl | grep -qvx unknown`

### usage-enforce-memory-zero-lifetime-firings
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/templates/.claude/hooks/enforce-memory.sh
- claim: enforce-memory.sh has ZERO entries across both projects' enforcement logs (0/499 kit lines since 2026-05-25, 0/250 edge-screener lines) even though both old and new versions log every allow/block once active — it has never fired in real use anywhere (its opt-in marker ~/.claude/enforce-memory has mtime today, 2026-06-09 13:42, i.e. it was absent for the entire logged history), and no .claude/.memory-consulted marker exists in either project; dead-weight / subtraction-review.
- repro: `grep -q '"hook":"enforce-memory"' /Users/jwang/nana-dev-kit/.dev-wiki/enforcement.log /Users/jwang/edge-screener/.dev-wiki/enforcement.log`

### usage-memory-reinforcement-machinery-unused
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/memory_server/storage.py
- claim: The memory server's reinforcement/dedup machinery shows zero utilization after 13 days and 59 stored memories: reinforcements table has 0 rows, no memory has strength>1, and SUM(access_count)=0 (get_by_id never called; access_count is only incremented there, storage.py:339, so memory_prune's min_access_count=2 gate keys on a counter real usage never moves) — subtraction-review candidate.
- repro: `test "$(sqlite3 'file:/Users/jwang/nana-dev-kit/.memory/memory.db?mode=ro' 'SELECT (SELECT COUNT(*) FROM reinforcements)+(SELECT COUNT(*) FROM memories WHERE strength>1)')" -ne 0`

### usage-memory-mcp-unused-in-consuming-project
- severity (agent est.): low
- file: /Users/jwang/nana-dev-kit/memory_server/server.py
- claim: The one real consuming project (edge-screener) has NO .memory/memory.db at all — the vendored 2,376-LOC memory MCP server produced zero data outside the kit's own repo (and ~/.claude/.memory/ does not exist either), so its only utilization is 59 in-kit rows; subtraction-review candidate.
- repro: `test -f /Users/jwang/edge-screener/.memory/memory.db`

**Area notes:** RAW UTILIZATION MATRIX (for the orchestrator's table; filesystem evidence only):

MEMORY MCP: kit db /Users/jwang/nana-dev-kit/.memory/memory.db = 59 active-schema rows (58 category=custom, 1 fact; trust: 37 high / 22 medium), created 2026-05-27T22:53Z..2026-06-09T18:16Z (written through today — store path IS live), 3 superseded, 3 inactive. reinforcements=0 rows, strength>1=0, SUM(access_count)=0. ~/.claude/.memory/ and /Users/jwang/edge-screener/.memory/ do NOT exist. Caveat on access_count: only get_by_id increments it (storage.py:339); search_* do not, so access_count=0 does not prove searches never ran — it proves get_by_id and the prune gate's counter are dead.

ENFORCEMENT LOG kit (499 lines, 2026-05-25..2026-06-09; NOTE: old-version hooks truncate to tail -n 500, so pre-May-25 history may be lost): enforce-loop 329, dev-wiki-scope-check 165, enforce-spec 2 (both 2026-05-25, action=block), dev-debrief 1, null 2. Actions: allow 308, advisory 105, skipped 60, block 23, phase-completed 1. edge-screener (250 lines, 2026-05-31..06-04): enforce-loop 90, check-tests-were-run 83, py-review 77; allow 90, skipped 159, block 1.

AUDIT TRAIL: kit .nana/audit.jsonl ABSENT (kit never opted into project-local hooks). edge-screener: 920 lines, 2026-05-31..2026-06-03, model=unknown on 920/920.

LEDGER: .dev-wiki/assumption-ledger.md = 2 phase blocks, 10 assumption rows (Phase 80 retro: 4 rows revisit-status filled 'held'; Phase 82 live: 6 rows revisit-status blank). Component is 1 day old — counts are expected, NOT a dead-weight candidate.

SESSION MACHINERY: ~/.claude/.session-start-ts mtime 2026-06-04 09:42 (matches edge-screener's last session; edge has the NEW project-local session-start.sh, kit runs the OLD global one that never writes it). .dev-wiki/log.md cadence: PLAN/DONE/DEBRIEF entries continuous through 2026-06-09 18:22 — dev-plan/dev-debrief skills are heavily used.

HOOK-BY-HOOK REAL-USE EVIDENCE (18 shipped): FIRING: enforce-loop (kit+edge), dev-wiki-scope-check (kit, 165 — but see anomaly below), check-tests-were-run (edge 83), py-review-stop (edge 77), audit-log (edge 920), session-stop (.session-end in both, kit Jun 9), stale-queue (.stale-queue in both), session-start (runs — but the stale 35-line version in kit), context-size-check (only installed file matching template; mtime today), enforce-spec (2 blocks ever, both 2026-05-25 — near-zero but confounded: the registered old copy may not log allows). ZERO DETERMINISTIC EVIDENCE: enforce-memory (0 log rows both projects — clean zero, candidate filed). AMBIGUOUS-BY-DESIGN (no persistent artifact; absence is not evidence): detect-loop (logs only on repeated-failure advisory; 0 entries, no .loop-state), post-commit (.pending-commit is transient, consumed at session start), pre-compact/post-compact (no artifact found; .session-anchor absent everywhere), scan-secrets / block-dangerous-bash / auto-ruff-format (no logging at all; edge-screener has them installed). These ambiguous ones are listed for the matrix but NOT filed as candidates — a repro cannot distinguish 'never fired' from 'fired silently'.

UNRESOLVED ANOMALY (flagging for the eval/test-hygiene area, could not pin source read-only): the kit's enforcement.log contains 165 dev-wiki-scope-check rows in the NEW schema_version-1 format with phase tags tracking real phases 65→82 chronologically (latest today 18:27), but the ONLY registered scope-check (/Users/jwang/.claude/hooks/dev-wiki-scope-check.sh, mtime May 28, 52 lines) contains no logging code at all, project settings register no hooks, tests are mktemp-hermetic with a pinned phase-65 fixture, and no file under ~/.claude contains 'schema_version'. SOMETHING executes the template-format hook against the live repo; either the real runtime differs from ~/.claude/settings.json as read, or a non-hermetic runner appends to the live log. Also note ~/.claude/settings.json, enforce markers, and context-size-check.sh all have mtime today 13:42:47 (possible fresh provisioning of this environment) — the other 11 hooks are May 28.
