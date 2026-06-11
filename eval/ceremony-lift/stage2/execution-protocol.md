# Phase 87 Execution-Protocol Addendum — Stage-2 Episode Contrast

ADDENDUM-PINNED execution mechanics for the FROZEN `## Stage-2 parameters`
(eval/ceremony-lift/pre-registration.md, byte-frozen since 9ad62f0). This file is
byte-frozen after its add-commit (spec exit criterion 2: first-add-commit ancestry +
byte-unchanged vs results.md). Apparatus fixes only per `## Amendment rule` below.
Spec: specs/phase-87-stage2-episode-contrast.md (nana:approved 2026-06-10).
Kit pinned base: 6728e2f. Substrate pinned base: edge-screener 368e056.
Claim ceiling (verbatim, every summary artifact must embed it): n=1 episode evidence may
confirm a cut-candidate into a REVERSIBLE trim-trial; it may never mint keep or cut.

## Maintainer rulings

Direction Q&A 2026-06-10 (ledger Phase 87 block):

1. **Isolation = independent clones** — faithful implementation of the frozen "twin
   worktrees from the same git state": same start state, twin working trees, structural
   isolation. `git clone --no-hardlinks file:///Users/jwang/p87-substrate/edge-screener
   <arm-dir>` then `git remote remove origin` in each clone.
2. **Ship-runner referent = standing phase-exit gate**, byte-exact:
   `uv run pytest && uv run mypy && uv run ruff check .`
   (run from the clone root; coverage >=85% enforced by the committed pyproject addopts).
   The frozen ship triple reads: collected tests >= 390 (`uv run pytest -q --co`),
   total coverage >= 94.44% (the TOTAL row of the pytest term report), phase-exit gate
   exit 0. Baseline verified 2026-06-10: 390 passed, TOTAL 94.44% (A1 gate PASS).
3. **Gate inputs = canned, orchestrator-mediated** per `## Gate-response policy`.

## Arm ordering

Arm B (minimal) FIRST, then arm A (full ceremony). Rationale (pinned pre-run): the clean
arm runs while no ceremony artifact exists anywhere on the machine, minimizing the
contamination window; the leak canary is posed to B before A produces anything. One fresh
session per arm; the orchestrator opens neither clone's diff until both arms have reached
their ship/stop point (unblinding event).

## Budget cap

- **Unit: wall-clock seconds per arm session**, enforced by the pty driver. Deviation
  disclosed: the frozen text anchors the cap to the stage-1 cost table; pty-driven
  sessions do not persist token-bearing transcripts (T1 spike DISCOVERY), so the
  enforceable anchor is the cost table's wall column, not cache-adjusted tokens.
- **Value: 14,400 s (4 h) per arm, equal across arms.** Anchor: stage-1 pooled per-phase
  ceremony+implementation wall ~= 17,700 s for FULL kit phases; edge-screener Phase 10 is
  a small phase (~50-60 line unit test), so 4 h is >= 2x the expected ceremony-arm need.
- **Check cadence:** driver deadline check on every pty-drain iteration (<= 2 s).
- **Stop rule (deterministic):** at deadline the driver sends Escape, then `/exit`, marks
  the arm **DID-NOT-FINISH (DNF)**; the DNF row enters the ship table as-is. No re-run
  with a raised cap; cap changes only via pre-unblinding amendment BEFORE either arm has
  started.
- **Gate-stall rule:** > 900 s with a gate menu displayed and no pty output change → DNF.

## Gate-response policy

Closed policy (no improvisation; every send logged verbatim with a timestamp BEFORE it is
sent, as `TRUST-RESPONSE` / `GATE-RESPONSE` / `PERM-RESPONSE` lines):

1. Any AskUserQuestion menu → `<Enter>` on the highlighted first option (the agent's
   first listed option).
2. Any required free-text input → the pinned string:
   "Proceed with your best judgment within the stated task; no additional constraints."
3. Workspace-trust dialog → first option (trust).
4. Permission prompts: sessions run `--permission-mode acceptEdits`; any residual
   permission menu → first option (allow).
5. Any input outside this policy = protocol deviation: logged, flagged at the
   disposition checkpoint.
6. **Zero-gate-firing in an arm is a VALID run** (pre-declared).
7. An arm stalled on a gate the policy cannot answer (no highlightable option) → DNF.

Driver mechanics pinned from the T1 spike (spike/spike-record.md): expect-pty; pty must
be DRAINED continuously during waits (backpressure freezes the session); single-token TUI
patterns only; gate detected by rendered option-row shape `2\.[^\n]{0,24}<label>`.

## Cross-arm isolation

- Mechanism: independent full clones per ruling 1; clone roots pinned:
  `/Users/jwang/p87-arms/arm-b/edge-screener` and `/Users/jwang/p87-arms/arm-a/edge-screener`
  (stable non-tmp paths → predictable transcript dirs).
- Orchestrator-executed probe (pre-arm, recorded in instrument-record.md):
  (a) each clone's `git log --all --oneline | wc -l` equals the setup repo's count;
  (b) `git remote -v` empty in both clones; (c) `find <clone> -type l` empty;
  (d) no `.memory/` present in either clone; (e) the two clones are byte-identical at
  session start (`diff -r` excluding `.git`); (f) `~/.claude/projects/` contains NO
  pre-existing directory for either clone's cwd slug.

## Positive control

- **Seed:** a dev-wiki decision article in the setup commit documenting edge-screener's
  hook-registration convention: hook identity = script basename, registered EXACTLY ONCE
  across settings.json ∪ settings.local.json (duplicate command strings are deduped by
  the platform, but DIFFERENT command strings invoking the same script double-fire).
  The article is written as plain project documentation — no mention of DRQ-1, the kit
  repo, or any kit-internal file.
- **Delivery:** one sub-task sentence appended BYTE-IDENTICALLY to both arms' task
  statements (see `## Task statements`): register a named, not-yet-registered project
  hook script "following the project's documented registration conventions". The
  concrete hook script is chosen at T4 setup (it must be present in the clone and absent
  from both settings files), recorded in instrument-record.md BEFORE either arm runs.
- **Surfacing detector (deterministic, orchestrator-executed post-arm):** over the arm's
  final settings files: jq-extract all hook command strings from
  `.claude/settings.json` ∪ `.claude/settings.local.json`, map to script basenames;
  SURFACED iff the named script's basename appears EXACTLY ONCE across the union AND the
  registration is syntactically valid (nested schema). NOT-SURFACED iff absent (sub-task
  skipped) or appearing more than once / in both files (convention not consulted).
  No prose judgment anywhere.
- NEITHER arm SURFACED → run-status **INSTRUMENT-DEAD** (the episode cannot read
  TERMINATE/null). Rehearsal fixtures: T3 `controls/` synthetic settings pairs
  (exactly-once → SURFACED; duplicated → NOT-SURFACED), rehearsed again at T4 in scratch.

## Leak canary

Posed to **arm B only, AFTER its ship/stop point** (post-stop probe of the same session
context, before `/exit`), verbatim:
"What was the DRQ-1 verdict and which file records it?"
Reply captured from the pty log. **Deterministic matcher:** CONTAMINATED iff BOTH
(A) `grep -iE 'string.?keyed'` matches the reply AND (B) `grep -iE
'drq1-verification|install-gap'` matches the reply; otherwise CLEAN. CONTAMINATED →
run-status **VOID** (re-present to the maintainer; never reinterpret).

## Context surfaces

Manifest captured by the orchestrator at each arm's session start; every entry classified
against this pre-registered list; **any unclassified surface → run-status VOID** (pinned
default).

- **parity-shared (allowed):** global `~/.claude/rules/*.md`, global hooks/skills/agents
  under `~/.claude/` (identical for both arms by construction); all files inside the
  clone at session start (byte-identical across clones per the isolation probe);
  the global memory MCP config.
- **voiding:** a pre-existing `~/.claude/projects/<clone-cwd-slug>/` directory at arm
  start; a `.memory/` DB present in one clone; any file present in one clone and absent
  in the other at session start; any path reference resolving into the kit repo
  (/Users/jwang/nana-dev-kit) from inside the clone.

## Blinded defect review

Fires only if BOTH arms pass the frozen ship triple. Orchestrator strips arm identity:
diffs labeled X/Y by a random assignment sealed in `arm-records/blind-assignment.txt`
(written before review, not read until verdicts are recorded). One fresh clean-context
subagent per diff (no arm identity, no experiment framing) generates candidate defects;
EVERY claimed defect must be confirmed by an orchestrator-executed deterministic
reproduction (failing test or command) in the corresponding clone; unconfirmed claims are
discarded. Confirmed-defect counts decide tie-break 1; tie → `git diff --shortstat`
changed lines vs the setup SHA decides tie-break 2.

## Amendment rule

Apparatus fixes only via NEW timestamped files `eval/ceremony-lift/stage2/amendments/
NNN-<slug>.md`, committed BEFORE unblinding (unblinding = the orchestrator's first read
of either arm's diff or results). This file itself is never edited after its add-commit.
**Any amendment after unblinding → experiment VOID.**

## Tie handling

Both arms pass → blinded defect review (above); defect tie → changed-lines; full tie →
**`undecidable — no trim-trial confirmation`** (pre-declared; no coin flip; no judgment
substitution). One arm fails/DNF while the other passes → the passing arm is
ship-eligible (own checkpoint); disposition still bounded by the claim ceiling and the
closed vocabulary: confirm-trim-trial | not-confirmed | undecidable | instrument-dead |
void.

## Claim-ceiling patterns

Procedure (deterministic): for each summary artifact, first assert the verbatim ceiling
sentence is present; then remove exact ceiling-sentence lines (`grep -vF`) and apply the
violation patterns — any match = FAIL:

- `grep -iE 'verdict[: ]+ *(keep|cut)\b'`
- `grep -iE 'mint(s|ed)? +(a +)?(keep|cut)\b'`
- `grep -iE '(ceremony|minimal|spec[- ]generation) *(arm)? *(wins|won|beats?|beat|loses?|lost)\b'`

Validated against the seeded-negative control artifact (T3 `controls/`) before any real
artifact is checked.

## Target branch IDs

Read off the 2026-06-10 baseline coverage run (390 passed, TOTAL 94.44%) and
`.dev-wiki/phase-10-candidate-analysis.md`:

- `src/edge_screener/survivorship/reader.py:97-98` — recovered-name (M) genuine
  continuation (`return base`, no synthetic crater).
- `src/edge_screener/survivorship/reader.py:105-112` — recycled-ticker all-False
  keep-mask sub-path (post-removal-only data; emitted series = `[crater64]` bar only).
- `src/edge_screener/metrics/survivorship.py:99-104` — `spans_removal` classification
  (`recovered.append` path never taken at baseline).

Verbatim baseline term-missing rows (the deterministic before-state, 2026-06-10 run):

```
src/edge_screener/metrics/survivorship.py          87      1     10      1    98%   38
src/edge_screener/survivorship/reader.py           45      3     10      3    89%   41, 54, 89
```

Granularity caveat (pinned BEFORE arms): the behavioral ranges above are the analysis
document's framing; the term-missing ground truth shows the baseline uncovered artifacts
for these files as lines 38 / 41, 54, 89 plus 1+3 partial branches (the recovered-path
lines 97-98 already execute under an existing unit test — the uncovered part is branch
arms, which this terse report format does not itemize). **Deterministic detector:**
per-file (Miss + BrPart) for BOTH files must STRICTLY DECREASE vs the verbatim rows
above (or the file reach 100%); the arm's verbatim rows are recorded alongside.
Reported per arm as a column; affects nothing deterministically (maintainer weighs it at
the disposition checkpoint). The baseline collected-test-ID set
(`uv run pytest -q --co`) must be a SUBSET of each arm's collected set — ship-BLOCKING
for that arm (substrate protection), not contest-scoring.

## Provisioning manifest

Setup branch `p87-setup` from 368e056 in edge-screener (HARD checkpoint, two separate
acks: seed write; branch+clone creation). Exhaustive in BOTH directions:

- **Include (tracked-modified):** `.claude/hooks/**` (18 modified files),
  `.claude/settings.json`.
- **Include (force-add, gitignored/untracked):** `.claude/settings.local.json`
  (the Phase-85 single-registration install), `.claude/enforce`,
  `.claude/.memory-consulted` (created), `.dev-wiki/phase-10-candidate-analysis.md`.
- **Include (new):** the positive-control seed article under
  `.dev-wiki/articles/decisions/` + its index line.
- **Exclude (must NOT enter the commit):** `backup-phase85*.tgz`,
  `reports/edge-verdict-focus.md`, `.memory/**`, anything referencing the kit repo.
- **Canary pre-check:** before clones are cut, `git show --stat` of the setup commit is
  reviewed at the checkpoint and the staged file set is grepped for
  `drq1|install-gap|nana-dev-kit` — any hit stops setup (contaminated provision).
- Live-tree protection: edge-screener's dirty working state is snapshotted
  (`git stash create` + tarball of untracked surfaces) and restoration is TESTED before
  any branch operation; the live checkout is returned to its pre-setup state.

## Task statements

Byte-identical MAIN task + sub-task for both arms; arms differ ONLY in the pinned
workflow wrapper. Stored as `arm-records/task-statement.txt` (shared part) and asserted
byte-identical by check-instrument.sh.

**Shared task statement (verbatim):**
"Phase 10: add a standalone unit test in tests/unit/ that closes the two uncovered
survivorship branches — the recovered-name (M) genuine-continuation path and the
recycled-ticker post-removal-only path (see .dev-wiki/phase-10-candidate-analysis.md).
Engine code, standing reports, and existing tests stay untouched. Done means: the new
test passes, the full gate `uv run pytest && uv run mypy && uv run ruff check .` is
green, total coverage does not regress below 94.44%, and no existing test is modified or
deleted. Also: register the project hook script <HOOK-SCRIPT> for <HOOK-EVENT> in the
project settings, following the project's documented registration conventions."
(<HOOK-SCRIPT>/<HOOK-EVENT> substituted identically for both arms at T4, recorded in
instrument-record.md before either arm runs.)

**Arm A wrapper (verbatim):** "Work this as a standard project phase using the full
dev-wiki workflow: run /dev-plan for this phase and follow it through implementation and
/dev-debrief, including its gates and reviews."

**Arm B wrapper (verbatim):** "Before writing any code, surface your load-bearing
assumptions (cost-sorted, worst-if-wrong first) via the AskUserQuestion tool and take
positions; then implement the task directly. Project enforcement hooks are active."

## Transcript mapping and cost capture

- Cwd→transcript-dir slug mapping: `/`, `_`, `.` → `-`; `/private` prefix added for
  /var paths (verified T1). Pinned arm dirs:
  `~/.claude/projects/-Users-jwang-p87-arms-arm-b-edge-screener/` and
  `~/.claude/projects/-Users-jwang-p87-arms-arm-a-edge-screener/`.
- T1 spike DISCOVERY: pty-interactive sessions persisted only title-line transcripts.
  T4 re-tests persistence from the stable clone paths. IF full transcripts persist, the
  stage-1 extractor (`eval/ceremony-lift/extract-costs.py`, path-parameterized) runs per
  arm and the token columns fill (raw + cache-adjusted). ELSE the pre-declared A3
  fallback applies: token columns marked **NOT-EXTRACTABLE**; per-arm cost reports
  wall-clock (driver log timestamps) + interruption count (logged
  TRUST/GATE/PERM-RESPONSE lines). Never hand-estimated.
- Secondary signal: the TUI `/cost` output is captured per arm before `/exit`
  (screen-scrape, logged verbatim) and reported in a caveat column — never substituted
  into the token columns.
