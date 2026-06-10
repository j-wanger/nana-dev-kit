<!-- nana:approved 2026-06-09 -->
# Spec: Phase 84 — Hook & Registration Hygiene

## Objective

Restore the two dormant lifecycle hooks (post-commit.sh, detect-loop.sh) to verified firing, close the marker-resolution and eval-sandbox environment leaks, and bring the live global hook registrations in `~/.claude/settings.json` into agreement with modules.json scope tags — with rollback safety and no silently disarmed consuming project.

## Context

The Phase 82 QA sweep confirmed-by-reproduction 4 hook defects but deferred them under the pre-registered fix boundary (evidence: `eval/qa-sweep/repro-runs.log` lines 47–61, `eval/qa-sweep/verification-matrix.md`):

1. **post-commit.sh top-level exit-code dormancy** (medium) — piping a real PostToolUse git-commit event does not produce `.dev-wiki/.pending-commit`.
2. **detect-loop.sh top-level exit-code dormancy** (low) — 3 consecutive failing-command events produce no warning output.
3. **HOME-only marker resolution** (low) — both hooks honor only `$HOME/.claude/enforce`, ignoring the project-local `.claude/enforce` marker other enforcement hooks honor.
4. **eval-harness sandbox escape** (medium) — `scripts/eval-runner.sh` never neutralizes `CLAUDE_PROJECT_DIR`, so hooks invoked inside mktemp sandboxes can resolve `${CLAUDE_PROJECT_DIR}` to the live project and escape the sandbox.

Separately, Phase 79 rescoped 17 hooks from global to project-local, but settings registration is add/update-only — no deregistration mechanism exists — so 11 ghost global registrations persist in `~/.claude/settings.json` (enforce-spec, enforce-memory, enforce-loop, detect-loop, post-commit, dev-wiki-scope-check, stale-queue, session-stop, session-start, pre-compact, post-compact; verified present 2026-06-09; modules.json scopes only context-size-check.sh as global). Their runtime copies were refreshed in Phase 82, so they run current code — but they remain registered contrary to the registry, and deregistering changes live wiring in every project on the machine. Filed Phase 82 as "re-trigger: next hook-touching phase" and "maintainer call".

The kit's history motivates the evidence standard: 4 components were registered+present+valid but silently not firing for 8–33 phases. The standard is verify firing, not presence — pipe a real event in a hermetic mktemp -d sandbox, assert allow AND block paths, never test against live state (HEU-012). A live hazard compounds this here: the verification instrument (the eval harness) is itself one of the defect subjects.

## Scope

### In scope

- `templates/.claude/hooks/post-commit.sh` and `templates/.claude/hooks/detect-loop.sh` (defects 1–3), propagated to installed copies via the normal template→install flow.
- `scripts/eval-runner.sh` environment hermeticity (defect 4): `CLAUDE_PROJECT_DIR` neutralization and confirmation that `HOME` is actually exported into hook environments (sibling leak).
- New/extended functional tests under `tests/` with real-event fixtures.
- `eval/corpus/` scenario-expectation updates ONLY where waking the two hooks flips a documented expectation (each flip explained).
- Ghost-registration reconciliation: consuming-root discovery (kit-marker scan: enumerate filesystem roots carrying kit-installed markers — kit-named hook scripts under `<root>/.claude/hooks/` — per the Phase-83 discovery artifacts in `eval/prune-on-value/`), per-project × per-hook enforcement coverage matrix INCLUDING a copy-currency column (installed hook md5 vs template md5, so stale dormant copies surface at the same checkpoint), maintainer-gated sandbox-rehearsed jq deregistration of the 11 ghosts from `~/.claude/settings.json`, fresh-session post-surgery verification.
- Documentation rows that become stale from the above (README hook tables, `_ARCHITECTURE.md` counts), MANIFEST regeneration.
- `modules.json` only if its registration data is wrong; `make template` regenerates — never hand-edit generated artifacts.
- Exit-criteria aggregator under `eval/hook-hygiene/`.

### Out of scope

- The other Phase-82/83 deferred filings (misc items, wiki knowledge gap, A5 memory-layer disposition, enforce-memory demand revisit).
- Any new hooks, skills, or features; any prune-on-value verdicts.
- Frozen apparatus: `eval/qa-sweep/**`, `eval/amplifier/**`, `eval/assumption-screen/**` and `.dev-wiki/assumption-ledger.md` are READ-ONLY (supersede, never rewrite; defects found there are filed, not fixed).
- User-owned `~/.claude/rules/` files.
- Rewriting historical records (Phase-82/83 zeros, dev-wiki journals) — superseding notes only.
- Consuming-project feature work; remediation there is limited to maintainer-approved project-local install of missing enforcement wiring.

## Approach

Three serialized stages, instrument-first:

**Stage A — hermetic instrument.** Fix defect 4 before anything else: the eval harness must not let hooks see the live `CLAUDE_PROJECT_DIR` or the maintainer's armed `$HOME`. Add a live-state tripwire to the verification protocol (live repo's `.dev-wiki/.pending-commit`, `.claude/.loop-state`, `.dev-wiki/enforcement.log` asserted unchanged across test/eval runs). Only a hermetic instrument may verify Stages B–C.

**Stage B — hook fixes.** Diagnose and fix defects 1–3 in the template hooks. Fixtures must include at least one byte-for-byte captured real Claude Code event per defect (provenance noted) — hand-written fixtures encoding the fixer's belief about the event shape can agree with a wrong hook. Define marker resolution order explicitly (cd to project dir → project-local marker → `$HOME` fallback) and cover the var-set/unset × marker-local/global matrix. Success criteria assert produced artifact content (marker file, warning text), not just exit codes. Run the full eval before/after and explain every scenario flip.

**Stage C — registration reconciliation.** Discover all consuming roots (kit-marker scan, Phase-83 method), build the per-project × per-hook coverage matrix, present it with the proposed jq surgery at a maintainer checkpoint BEFORE any deregistration. Surgery is sandbox-rehearsed, backed up with a tested restore, and verified in a fresh session.

One commit per stage minimum; defect fixes may be per-defect commits.

### Domain Research Questions

1. What is the exact runtime event shape (top-level fields) of a current Claude Code PostToolUse event — where do `tool_response`/exit information actually live, and does the platform's `.tool_input` normalization history (Phase 40, Phase 82) predict the dormancy here?
2. What environment does Claude Code guarantee at hook invocation (`CLAUDE_PROJECT_DIR`, `HOME`, CWD), and how does it resolve `~`-relative vs absolute hook commands?
3. What does Claude Code's `/doctor` consider malformed in settings hook arrays (empty matcher groups, empty event arrays) — what must the post-surgery file shape look like?

## Constraints (CRITICAL)

- **Instrument-first ordering**: no hook-fix verification runs through the eval harness until defect 4 is fixed and the live-state tripwire is green — prevents the instrument mutating the subject (hooks cd-ing into the live repo and writing `.pending-commit`/loop-state/enforcement records during verification).
- **Real-event fixture provenance**: ≥1 fixture per hook defect is a captured real event with provenance noted; assertions check artifact content — prevents fixture circularity (hook and hand-written fixture agreeing while both are wrong against the runtime).
- **Coverage matrix before deregistration**: every discovered consuming root is checked for project-local registration of each of the 11 hooks; every uncovered cell is remediated or explicitly maintainer-accepted BEFORE any removal — prevents the 4th cascade-failure instance (globally deregistered + locally absent = silently disarmed, fail-open, zero signal).
- **Maintainer checkpoint is unconditional**: the coverage matrix + proposed surgery diff go to the maintainer BEFORE any live settings edit; deregistration is his decision, not an inferred default — prevents an irreversible-in-practice change to machine-wide live wiring on agent judgment.
- **Surgery safety**: timestamped backup + tested one-command restore; exact jq filter rehearsed in mktemp -d asserting (a) only the 11 target entries differ, (b) no empty matcher/event arrays remain, (c) context-size-check.sh survives intact; post-surgery firing verification in a fresh session — prevents clobbering the shared, hand-edited live settings file and false same-session verification.
- **Hermetic sandboxes only**: every firing test overrides `HOME` and `CLAUDE_PROJECT_DIR`; allow AND block paths asserted (the maintainer's armed `~/.claude/enforce` must not leak into allow-path tests) — prevents registered-but-dormant passing presence tests (HEU-012).
- **Explained eval diff**: full 52-scenario run before and after; any flip documented with cause — prevents silent re-baselining when previously-leaky scenarios or newly-woken hooks change outcomes.
- **Historical supersession**: Phase-82/83 firing zeros for these hooks were measured on the broken instrument; recontextualize via superseding notes, never rewrite — preserves the audit trail.
- **Non-dev-wiki suppression verified**: waking post-commit must not emit markers/noise in projects without `.dev-wiki/` — fixture test for the lifecycle guard — prevents machine-wide commit-time noise.
- **Parser edge fixtures**: detect-loop/post-commit matchers tested against commands with embedded quotes, commands merely mentioning "git commit", the 2-vs-3 failure boundary, and reset-on-success — prevents false loop warnings and false marker writes from naive signature parsing.
- **Single-source registration**: modules.json is the only hook-registration source; generated artifacts (`templates/.claude/settings.json`, MANIFEST) only change via `make template`/regen, and the regenerated diff must confine itself to intended files.

## Success Vision

Both lifecycle hooks demonstrably fire — allow and block paths — under hermetic tests anchored on real captured events, and the defects' original Phase-82 repro commands now pass unmodified. The eval harness is provably hermetic: nothing it runs can touch live state, and that property is itself asserted by a test that would have caught the original leak. The machine's live registration surface matches the registry exactly (or carries explicit, documented maintainer-accepted exceptions), with every consuming project's enforcement coverage accounted for in a matrix — no project silently disarmed. The record is honest: prior firing-rate zeros measured on the broken instrument carry superseding notes, and every eval-expectation change is explained, not slipped in. A future maintainer can re-run one aggregator script and watch every claim verify.

## Exit Criteria (machine-checkable)

All runnable via `bash eval/hook-hygiene/run-exit-criteria.sh` (aggregator, one criterion per numbered check):

- [ ] `make test` green (22+ scripts, including the new functional tests)
- [ ] `make eval` green; `eval/hook-hygiene/eval-diff.md` exists and explains every scenario flip (empty flip-list is valid)
- [ ] The pinned Phase-82 post-commit repro command (repro-runs.log line 48) exits 0 against `templates/.claude/hooks/post-commit.sh`
- [ ] The pinned detect-loop repro (line 52) exits 0
- [ ] The pinned HOME-only-marker repro (line 56) exits 0
- [ ] `grep -q CLAUDE_PROJECT_DIR scripts/eval-runner.sh` AND the hermetic-leak test in `tests/` passes AND its seeded-leak self-check passes (revert the eval-runner fix in a mktemp -d copy, assert the leak test goes RED — controls-first; a leak test that cannot catch the original leak is instrument-dead)
- [ ] `jq` extraction of KIT-OWNED hook commands from `~/.claude/settings.json` (commands referencing kit-shipped hook script names from modules.json) equals the modules.json scope:global set (context-size-check.sh only), OR a documented exception list exists at `eval/hook-hygiene/registration-exceptions.md` with maintainer acceptance noted; non-kit personal hooks are ignored by the extraction, never touched
- [ ] `eval/hook-hygiene/coverage-matrix.md` exists with a row per discovered consuming root × 11 hooks, a copy-currency column (installed md5 vs template md5), and no unaccounted cell
- [ ] Timestamped settings backup exists and `eval/hook-hygiene/rehearsal.log` contains a restore-exercised line from the sandbox rehearsal
- [ ] `bash scripts/check-install-drift.sh --count` → 0

## Checkpoints

- After Stage A (harness hermetic + tripwire green): report instrument status before starting hook fixes; proceed without waiting.
- After Stage B (hook fixes verified, eval diff produced): report fixes + any scenario flips; proceed without waiting unless a flip is unexplained.
- BEFORE any deregistration (Stage C): HARD CHECKPOINT — present the coverage matrix, uncovered-cell remediation options, and the exact rehearsed surgery diff to the maintainer; wait for explicit approval. No live settings edit before this gate closes.
- If the live-state tripwire ever trips during verification: STOP, restore from git, re-diagnose the leak before continuing.
- If any of the 4 repro commands already passes at HEAD: STOP that defect track and verify whether it was fixed elsewhere (close as already-fixed with evidence) rather than "fixing" working code.
- If a consuming project has uncovered enforcement cells the maintainer declines to remediate or accept: route to Blockers, exclude those hooks from surgery.

## Assumptions

- The 4 Phase-82 repro commands still reproduce at HEAD (Phase 83 touched adjacent surfaces). If false for any: that defect was fixed in the interim — verify the fixing commit, close as already-fixed, do not re-fix.
- The 11 ghost registrations are still present in live `~/.claude/settings.json` (verified 2026-06-09). If the file changed since: re-enumerate before building the surgery; never operate on a stale target list.
- Consuming roots are discoverable via the Phase-83 kit-marker scan method. If the scan provably misses roots: matrix covers discovered roots only; the residual risk is stated to the maintainer at the checkpoint for explicit acceptance.
- A real PostToolUse event capture is obtainable (live session transcript or one-shot instrumented hook). If not: fall back to the platform-documented event shape with provenance noted, plus a one-shot live verification after install.
- Defects 1–3 are in-script (event-shape/exit-code handling), not platform bugs. If diagnosis shows platform-side cause: file upstream, present disable-at-boundary as the checkpoint option instead of a fix.
- `make eval` is runnable end-to-end on this machine today. If the harness is too broken to run pre-fix baseline: record baseline as unobtainable, use Phase-82's matrix as the prior, and note the caveat in eval-diff.md.
