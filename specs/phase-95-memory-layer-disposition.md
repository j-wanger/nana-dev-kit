<!-- nana:approved 2026-06-20 -->
# Spec: Phase 95 — Memory-Layer Disposition (Reconcile-and-Close)

## Objective

Adjudicate every open memory-layer obligation in nana-dev-kit to a single recorded, evidence-cited
closed-enum verdict, so that no obligation remains silently open — whatever the verdicts turn out to be.
Keeps are valid outcomes; this is a reconciliation-and-disposition round, NOT a shrink/cut hunt.

## Context

Phase 95 is the disposition the Phase 92→94 arc was built toward. The Phase-92
[[strategic-inflection-review]] mandated "re-measure-once-then-shrink" because the Phase-89 consumer
memory demand-zero was COULDN'T-FIRE — memory was broken in consumer cwds until the Ph91 PYTHONPATH fix,
so that zero was inadmissible ([[HEU-012]]). Phase 94 ran the clean re-measure
(`eval/memory-remeasure/memory-demand-remeasure.md`, decision [[consumer-memory-remeasure]]) and it
**REVERSED the "consumer demand is zero" premise**: on the repaired global memory MCP the coerced/announced
demand is substantial and VALUE-BEARING (cross-session read-back 10/10 aml-casework, 25/28 aml-substrate) in
2 of 3 live consumers; the spontaneous floor (signal-watch, no rules/hooks) is ≈0. The old
`specs/phase-92-memory-layer-prune.md` was shaped as a CUT apparatus on the demand-zero premise; that premise
is gone, so this spec **supersedes** it.

The maintainer closed the direction gate this session (ledger Phase-95 block; `all_accept:false`): FRAME =
reconcile-dispose-then-close (A1 accept); enforce-memory disposition decided at a HARD checkpoint on a
firing-distribution audit (A2 accept); writer verdicts rest on the consumer reversal + cheapness, NOT a fresh
kit-side store audit (A3 reject of the audit requirement → keep-by-affirmation); cut-execution rails are
conditional, arming only if a destructive verdict fires (A4 accept).

The kit's history binds the discipline: 5 "registered + present + valid but silently not firing" breakages
lasted 8–33 phases (verify by firing, never presence); the Phases-19-48 memory loss warns destructive
dispositions can be irreversible; the settings merge is add/update-only (no deregistration mechanism exists —
a removed component leaves ghost registrations that fail silently until a cut builds its own deregistration).

The open obligations this round closes: assumption-ledger Phase-83 block A5 (`revisit-status: open` — kit-side
memory-layer value), Phase-88 block A4 (held — kit-side memory-MCP-layer disposition) and A6 (held —
bridge/harvest writer trims), the Phase-83 enforce-memory keep-with-revisit, and the two Phase-88 trim-trials
(ak-ride-along `d43950f` + wk-seeding `df3e623`, REVERT-COUPLED) whose observation windows closed clean at
Phase 93 (`eval/dogfood-round/evidence/window-events.md` attests ZERO trigger events Ph88–93).

## Scope

### In scope

A single verdict table (`eval/memory-disposition/verdict-table.md`) with two sections:

**Component dispositions** (closed enum `keep | cut | harden | disable-at-boundary | redesign |
deferred-inadmissible`; one verdict cell per row, each citing its own evidence pointer):
1. `memory-mcp-layer` — the vendored `memory_server/` + the global MCP registration + the kit's ~99-entry
   store. Evidence: the Phase-94 consumer reversal. Lean KEEP.
2. `bridge-writer` — dev-plan Step 15a-bis bridge store (`~/.claude/skills/dev-plan/memory-bridge.md`).
   KEEP-by-affirmation (A3): consumer reversal + cheapness; NO kit-side store audit.
3. `harvest-writer` — debrief memory-harvest (`~/.claude/skills/dev-debrief/memory-harvest.md`).
   KEEP-by-affirmation, same basis.
4. `enforce-memory` — the PreToolUse hook (`templates/.claude/hooks/enforce-memory.sh`; ARMED at
   `~/.claude/enforce-memory` on this machine). The ONE live fork: `keep | redesign | retire(=cut |
   disable-at-boundary)`, decided at a HARD maintainer checkpoint on the firing-distribution audit.

**Trim-trial dispositions** (closed enum `confirm | restore`; the windows closed, so a disposition is due):
5. `ak-ride-along` (`d43950f`) — CONFIRM lean (window clean).
6. `wk-seeding` (`df3e623`, REVERT-COUPLED with ak-ride-along) — CONFIRM lean; restore would take both.

**Verdict-table row schema (PINNED — the exit-criteria greps anchor on it; do NOT invent a different column
order).** Each disposition row is exactly: `| <id> | <verdict> | <evidence-pointer> |` — the verdict cell is
**column 2** (the first cell after the id), one of the closed enum for its section. The id is the first cell
after the leading pipe. No other columns precede the verdict. Per-row structured fields that the runner
checks live as **standalone marker lines BELOW the table** (one per line, exact form), NOT as extra table
columns: `SURVIVOR-SMOKE: PASS` or `SURVIVOR-SMOKE: N/A (no destructive verdict)`; for a non-`keep`
enforce-memory verdict, `supersedes: enforce-memory@Phase-88 (<evidence delta>)`; for a destructive
enforce-memory verdict (`cut`/`disable-at-boundary`), `enforce-memory-zero-class: couldnt-fire` or
`enforce-memory-zero-class: didnt-fire`; for any executed deregistration, `unreachable-installs: <finding>`.

Plus the supporting artifacts:
- `eval/memory-disposition/enforce-memory-audit.md` — the deterministic post-restoration firing-distribution
  audit (allow/block ratio; block→real-memory_search-follow-through vs ritual-marker-touch), counted via JSON
  `tool_use` never grep, with a positive control.
- `eval/memory-disposition/redesign-spike.md` — the redesign FEASIBILITY SPIKE result (can a PreToolUse hook
  deterministically assert a prior in-session `memory_search`?), gating whether `redesign` is on the
  checkpoint menu.
- `eval/memory-disposition/run-exit-criteria.sh` — the exit-criteria runner WITH a `--selftest` (controls-first
  on the runner itself, mirroring the trim-round `check-verdict-table.sh` pattern): it seeds a malformed table
  in a scratch copy — an out-of-enum verdict cell, a writer row with a non-`keep` cell, a missing component
  row, and a destructive enforce-memory row missing its `enforce-memory-zero-class:` line — and asserts the
  runner REJECTS each. Clean-on-seed = instrument-dead.
- Conditional-on-a-destructive-verdict only: the enforce-memory removal/redesign change + its
  deregistration/survivor-smoke artifacts.
- Ledger + bookkeeping: the ONE authorized Phase-83 A5 status flip; the **newly authored Phase-95
  direction-gate ledger block** (the 4 A1–A4 positions from this session — a required deliverable, since the
  `--gate 95` exit check needs it to exist); the Phase-88 A4/A6/A5 closings via Blockers + the verdict table;
  the Phase-95 window-events attestation; the supersede note on the phase-92 spec; the standard dev-wiki
  updates.

### Out of scope

- A fresh kit-side store-retrieval audit for the writers (A3 reject — keep-by-affirmation).
- Restoring or reverting the trim-trials absent a recorded trigger event (the lean is CONFIRM; no
  reverts of `d43950f` / `df3e623` / `75b48af` / `b8bd416`).
- Editing user-owned `~/.claude/rules/` files (nana-soul.md memory instructions) — the kit cannot; any
  verdict that dangles them becomes a NAMED maintainer action item, not a silent orphan.
- Claude Code's native auto-memory (`~/.claude/projects/*/memory/`) — a different system; excluded from
  every removal set and file-touch list.
- memory_server upstream feature work; re-running consumer evidence sessions (Phase 94 gathered it; this
  round adjudicates, it does not re-measure).
- Frozen apparatus READ-ONLY: `eval/amplifier/**`, `eval/assumption-screen/**`, `eval/qa-sweep/**`,
  `eval/memory-remeasure/**`, and `eval/dogfood-round/**` EXCEPT `evidence/window-events.md`.
- The assumption-ledger body is append-only EXCEPT the ONE authorized Phase-83 A5 status flip.

## Approach

Reconcile-and-dispose, evidence-cited, with the cut apparatus right-sized to the reversed evidence (the
subtraction test applied to the spec itself: a keep-leaning disposition phase is not dressed as a cut
apparatus). The verdict table + per-row evidence citations + closed-enum discipline are ALWAYS present (they
are the audit trail). The heavy cut-execution rails arm ONLY if a destructive verdict fires.

Most rows are evidence-cited re-affirmations: `memory-mcp-layer` keeps on the Phase-94 consumer reversal; the
two writers keep-by-affirmation; the two trim-trials confirm on the clean windows. The one genuine
investigation is `enforce-memory`:

1. **Firing-distribution audit first** — reconstruct the post-restoration allow/block ratio and, for blocks,
   whether a REAL in-session `memory_search` followed (value) vs a bare marker-touch (ritual). Primary source
   is the hook's OWN firing log if present (`enforce-memory.sh` appends JSONL to `.dev-wiki/enforcement.log`,
   `schema_version:1` — verify it exists and its schema before relying on it); correlate block events to a
   following `memory_search`, counted via JSON `type==assistant` → `tool_use` (never grep — the deferred-tool
   catalog over-counts ~5×, Phase-94 finding). Interpret the distribution against the hook's OWN gating: it
   exits 0 (allow) when `.dev-wiki` is absent or `CI=true` and allowlists `*.md` / `.dev-wiki|.claude|specs`
   paths, so enforcement only bites dev-wiki-present consumers on source writes (the floor is not "no demand",
   it is "not reached"). The audit counts only after a positive control confirms it sees a known event.
   Classify any firing zero couldnt-fire vs didnt-fire ([[HEU-012]]).
2. **Redesign feasibility spike** — a cheap go/no-go: can a PreToolUse hook, within fail-open latency
   constraints, deterministically read the current session transcript JSONL (as the Phase-94 tally does) and
   assert a prior `memory_search` tool_use fired this session? Spike-PASS puts `redesign` on the menu;
   spike-FAIL removes it (menu becomes keep-or-retire).
3. **HARD maintainer checkpoint** — present the full firing audit + spike result; the maintainer picks
   `keep | redesign | retire`. No execution on direction-gate authority.

Verdict-execution semantics (cell tokens exactly as spelled):
- **keep** — re-affirmation citing the evidence line that earned it; no change.
- **redesign** — a TEST-FIRST hook change asserting a real `memory_search` event (paired allow/block smoke;
  RED before GREEN); preserve or version-bump the `.dev-wiki/enforcement.log` `schema_version` (downstream log
  readers break otherwise); keep `modules.json` (project scope) and `templates/.claude/settings.json` in sync
  (the `test_settings_template.sh` drift test catches a one-source edit); update the eval corpus only if
  firing behavior changes, every flip explained; this is the only path that edits hook CODE.
- **retire** (= `cut` or `disable-at-boundary`) — remove the hook's registration over ALL
  kit-marker-discovered installed roots (Phase-84 coverage-matrix method, basename-normalized jq) + handle
  the armed `~/.claude/enforce-memory` marker; survivor functional smoke on a kept hook (pipe a real event,
  assert exit); revert-on-failure. NO store backup (retiring a hook does not touch the memory store). NO
  self-lockout ordering (removing a BLOCKING hook un-blocks; the lockout hazard was cutting the LAYER while a
  blocking hook survives — the layer KEEPS here).
- **confirm** (trim-trials) — record the disposition; close the Blockers re-trigger entries + the ledger
  Phase-88 A5 row; NO revert, NO code change.

### Domain Research Questions

1. Can a PreToolUse hook deterministically read the current session's transcript JSONL to assert a prior
   `memory_search` tool_use fired in-session, within hook fail-open/latency constraints — and what does the
   hook receive that locates the active transcript? (The enforce-memory redesign feasibility question.)
2. What is the full post-restoration enforce-memory firing distribution (allow/block ratio, block→real
   follow-through vs ritual marker-touch) across recorded sessions, counted via JSON `tool_use` never grep —
   and what claim does that distribution support for keep vs redesign vs retire?
3. If enforce-memory is retired, how does a stale armed marker degrade in a consuming project the kit cannot
   reach — fail-open (exit 0, harmless) or noisy/blocking — and does the ghost-registration class apply?

## Constraints (CRITICAL)

- Every verdict cell is one of the closed enum and cites its own evidence pointer (file + line/section) —
  prevents unfalsifiable "keep because we like it" rows. Guard: the runner rejects any candidate row whose
  cell is outside the enum.
- Evidence-split asymmetry is honored and stated: consuming-project evidence may KEEP a kit-side writer (the
  conservative, no-collateral direction) but may NOT CUT one — prevents the A3 keep-by-affirmation from being
  misread as licensing a consumer-evidence cut. Guard: the writer rows carry a `keep` cell only; any future
  cut needs its own kit-side evidence (out of this round's scope).
- Any destructive enforce-memory verdict (retire/cut/disable, or a redesign that changes firing) classifies
  its firing zero couldnt-fire vs didnt-fire BEFORE execution ([[HEU-012]]) — prevents cutting on a
  couldn't-fire. Guard: the verdict row carries the zero-class token; the runner asserts its presence on
  destructive rows.
- The enforce-memory verdict reconciles with its STANDING Phase-88 keep (`eval/trim-round/verdict-table.md`):
  a verdict that differs (redesign/retire) carries an explicit `supersedes: enforce-memory@Phase-88` citation
  with the evidence delta justifying the reversal — prevents silently re-deriving a fresh verdict that
  contradicts a recorded decision. Guard: the runner requires the supersession token when the
  enforce-memory cell is not `keep`.
- No verdict cites a memory-subsystem ZERO (reinforcement count, access_count) as demand evidence:
  reinforcement only fires at cosine >0.90 which needs the fastembed embeddings the live venv lacked until
  2026-06-09, and access_count is not reliably incremented on search hits — both are couldnt-fire/untracked,
  not demand-zero ([[HEU-012]]; the exact mismeasure this whole arc corrects). Guard: keep/harden rows cite
  positive demand (Phase-94 read-back) or cheapness, never a subsystem zero.
- An enforce-memory `keep` cites FOLLOW-THROUGH evidence (a real `memory_search` correlated to a block),
  never raw allow-counts — the marker is agent-touched, so allow-counts measure self-attestation, not
  consultation. Guard: the keep row's evidence pointer references the audit's follow-through split, not the
  allow total.
- The memory-mcp-layer keep cites MCP-tool demand specifically (`mcp__memory__*` calls / rows in
  `.memory/memory.db`), NOT Claude Code native auto-memory (`~/.claude/projects/*/memory/`) — prevents
  keeping the MCP layer on value that actually came from the native store. Guard: the evidence pointer is the
  Phase-94 tally, which counts `mcp__memory__*` tool_use specifically.
- Survivor/functional smoke is verify-by-FIRING (pipe a real event, assert exit code / stderr), never a
  presence check — the registered-but-broken class bitten 5×. Guard: exit-criteria command pipes a real
  PreToolUse event and asserts the exit code.
- The firing-distribution audit and any memory_search count parse JSON `tool_use` (`type==assistant` →
  content[]), NEVER grep — the deferred-tool catalog contaminates a naive grep ~5× (Phase-94). Guard: a
  positive-control line in the audit (a known call must be counted) before the distribution counts as
  evidence.
- The redesign spike is a strict GATE: `redesign` may appear in the enforce-memory verdict only if the spike
  recorded `SPIKE: PASS` — prevents committing to a redesign that a hook cannot deterministically implement.
  Guard: the runner cross-checks the spike verdict against the enforce-memory cell.
- No rewriting history: prior dev-wiki records and the Phase-89 demand evidence are SUPERSEDED with notes,
  never edited; the phase-92 spec gets a supersede note, it is not deleted. Guard: git diff shows additions,
  not record rewrites.
- Ledger edit carve-out: the ONLY permitted prior-block edit is flipping the Phase-83 block A5 row's
  `revisit-status: open` → `held` (a single-token change; `held` reflects the deferral resolving cleanly via
  the Phase-95 layer keep — `held`/`bit` are the only schema-valid targets, there is NO `closed` token). The
  resolution rationale + verdict-table pointer live in the Phase-95 ledger block and the verdict table, NOT
  appended to the A5 row's text (text rewrites are not authorized). `scripts/check-assumption-ledger.sh`
  must pass after the edit; the Phase-88 A4/A6/A5 rows are resolved via Blockers filings + the verdict table,
  NOT by editing their ledger rows — prevents both the silent-open-forever state and a license to rewrite the
  ledger. Guard: the runner asserts the A5 row is no longer `open` and the validator is green.
- ANY destructive verdict (enforce-memory retire, or a memory-mcp-layer cut/disable) ships deregistration
  over ALL kit-marker-discovered installed roots (Phase-84 method) and the verdict row carries an
  `unreachable-installs:` line stating the verified degradation mode of any root out of reach — prevents
  silent ghost registrations (the add/update-only settings merge leaves a dead MCP entry / dead hook reg in
  consumers the kit cannot reach). A memory-mcp-layer cut additionally removes the `mcpServers.memory` block
  from reachable settings AND accounts for the skill-layer callers (memory-bridge, memory-harvest,
  memory-consolidate, the supersede tooling) that would otherwise call a removed backend. Guard: simulate a
  consumer with the component absent and record harmless-vs-noisy; assert the registration is gone
  post-action AND a fresh `--project-local` install does not re-add it.
- User-owned `~/.claude/rules/` and Claude Code native auto-memory are never edited and never in a removal
  set; a verdict that dangles a user-owned reference emits a NAMED maintainer action item — prevents
  collateral damage and silent orphans. Guard: removal-set review excludes those paths by construction.
- Zero destructive verdicts (all keep + confirm) is a fully valid outcome; verdicts are evidence-forced, not
  quota-driven — prevents manufacturing a cut to justify the phase.
- `make test` ALL-PASS, `check-install-drift.sh` drift 0, `make eval` denominator 50 unless an
  enforce-memory redesign/retire changes it (then the delta is explained in the verdict table) — prevents an
  unexplained eval/test regression riding along.

## Success Vision

Every open memory ledger obligation (Phase-83 A5, Phase-88 A4/A6, the enforce-memory revisit, the two
trim-trial windows) reaches a recorded, evidence-cited disposition — none remain silently open. A reader of
the verdict table can trace each verdict to an admissibility-respecting evidence pointer and see what the
evidence meant and why opposite-evidence components (consumer-facing layer vs kit-side writers vs the
gameable hook) got the verdicts they did. If enforce-memory is redesigned, it asserts a real in-session
`memory_search` event (det-over-narration) with a test-first paired smoke; if retired, installed copies and
repo agree (drift 0) and any unreachable consumer's degradation is named, not assumed. The assumption
ledger's memory rows finally close their revisit loop, and the phase-92 spec is cleanly superseded.

## Exit Criteria (machine-checkable)

All via `eval/memory-disposition/run-exit-criteria.sh` (ALL-PASS required). Row schema is PINNED (see Scope):
`| <id> | <verdict> | <evidence> |` — verdict is column 2; the greps anchor on it, never anywhere-in-line
(the Tier-1 review confirmed an anywhere-match false-flags wide tables). Component ids:
`memory-mcp-layer`, `bridge-writer`, `harvest-writer`, `enforce-memory`. Trim ids: `ak-ride-along`,
`wk-seeding`.

- [ ] `bash eval/memory-disposition/run-exit-criteria.sh --selftest` — controls-first: the runner rejects a seeded malformed table (out-of-enum cell, non-`keep` writer row, missing component row, destructive enforce-memory row missing its zero-class line). Clean-on-seed = instrument-dead.
- [ ] `grep -oE '^\| (memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory) \|' eval/memory-disposition/verdict-table.md | sort -u | wc -l | tr -d ' ' | grep -qx 4` — exactly the 4 component rows present
- [ ] `! grep -E '^\| (memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory) \|' eval/memory-disposition/verdict-table.md | grep -vqE '^\| [a-z-]+ \| (keep|cut|harden|disable-at-boundary|redesign|deferred-inadmissible) \|'` — every component row carries a closed-enum verdict in COLUMN 2
- [ ] `! grep -E '^\| (bridge-writer|harvest-writer) \|' eval/memory-disposition/verdict-table.md | grep -vqE '^\| [a-z-]+ \| keep \|'` — both writer rows are `keep` in column 2 (evidence-split asymmetry: no consumer-evidence cut)
- [ ] `test "$(grep -oE '^\| (ak-ride-along|wk-seeding) \|' eval/memory-disposition/verdict-table.md | sort -u | wc -l | tr -d ' ')" = 2 && ! grep -E '^\| (ak-ride-along|wk-seeding) \|' eval/memory-disposition/verdict-table.md | grep -vqE '^\| [a-z-]+ \| (confirm|restore) \|'` — both trim-trials present, each with a confirm|restore disposition in column 2
- [ ] `test -f eval/memory-disposition/enforce-memory-audit.md && grep -q 'POSITIVE-CONTROL: PASS' eval/memory-disposition/enforce-memory-audit.md` — firing-distribution audit exists with a passed positive control
- [ ] `test -f eval/memory-disposition/redesign-spike.md && grep -qE '^SPIKE: (PASS|FAIL)' eval/memory-disposition/redesign-spike.md` — redesign feasibility spike recorded a closed verdict
- [ ] `! grep -qE '^\| enforce-memory \| redesign \|' eval/memory-disposition/verdict-table.md || grep -qx 'SPIKE: PASS' eval/memory-disposition/redesign-spike.md` — `redesign` is only allowed when the spike PASSED
- [ ] `! grep -qE '^\| enforce-memory \| (cut|disable-at-boundary) \|' eval/memory-disposition/verdict-table.md || grep -qE '^enforce-memory-zero-class: (couldnt-fire|didnt-fire)$' eval/memory-disposition/verdict-table.md` — a destructive enforce-memory verdict carries its zero-classification marker line (vacuous on keep/redesign)
- [ ] `grep -qE '^\| enforce-memory \| keep \|' eval/memory-disposition/verdict-table.md || grep -qE '^supersedes: enforce-memory@Phase-88' eval/memory-disposition/verdict-table.md` — a non-`keep` enforce-memory verdict carries the supersession citation of the standing Phase-88 keep
- [ ] `grep -qx 'SURVIVOR-SMOKE: N/A (no destructive verdict)' eval/memory-disposition/verdict-table.md || grep -qx 'SURVIVOR-SMOKE: PASS' eval/memory-disposition/verdict-table.md` — survivor functional smoke fired (or explicitly N/A when nothing destructive executed)
- [ ] `! grep -E '^- A5 .*kit-side memory-layer' .dev-wiki/assumption-ledger.md | grep -q 'revisit-status: open'` — the Phase-83 A5 row (the one citing "kit-side memory-layer") is no longer `open` (content-anchored, robust against header-range drift)
- [ ] `bash scripts/check-assumption-ledger.sh && bash scripts/check-assumption-ledger.sh --gate .dev-wiki/assumption-ledger.md 95` — ledger validator green and the newly authored Phase-95 direction block is well-formed
- [ ] `grep -q '^## Phase 95' eval/dogfood-round/evidence/window-events.md` — the Phase-95 window-events attestation (trim-trial confirm) is recorded
- [ ] `head -20 specs/phase-92-memory-layer-prune.md | grep -qi 'supersed'` — the phase-92 spec carries a supersede note
- [ ] `make test && make eval && bash scripts/check-install-drift.sh` — suite green, eval denominator 50 (or the verdict table explains an enforce-memory-driven delta), drift 0

## Checkpoints

- After the enforce-memory firing-distribution audit AND the redesign spike, BEFORE filling the
  enforce-memory verdict cell: HARD maintainer checkpoint — present the allow/block ratio, the
  follow-through-vs-ritual split, the zero-classification, and the spike result; the maintainer picks
  `keep | redesign | retire`. Unconditional; no execution on direction-gate authority.
- If the enforce-memory verdict is `retire`: present the removal set + the `unreachable-installs:`
  degradation finding before any live settings edit.
- If a redesign survivor/paired smoke fails: revert the hook change before proceeding.
- The keep/confirm rows (memory-mcp-layer, both writers, both trim-trials) need no checkpoint — they are
  evidence-cited re-affirmations with no destructive action.

## Assumptions

- The Phase-94 re-measure (value-bearing coerced demand in 2/3 consumers) is the admissible basis for the
  `memory-mcp-layer` keep. If false (a defect is found in the Phase-94 tally on review): re-open the layer
  row as `deferred-inadmissible` and file the evidence gap — do not keep on a broken measure.
- The trim-trial windows closed CLEAN (window-events attests ZERO trigger events Ph88–93). If a
  trigger-matching event is found on review: the disposition becomes `restore` — `git revert` the
  REVERT-COUPLED pair (`d43950f` + `df3e623`) ATOMICALLY (one resurrects a writer whose reader/companion the
  other tombstoned) and re-run `tests/test_companions.sh` (bidirectional companion check) — never confirm,
  never a one-sided revert. Re-check window-events before recording confirm.
- A PreToolUse hook CAN locate and read the active session transcript JSONL deterministically (the spike
  tests this). If false (`SPIKE: FAIL`): `redesign` leaves the menu; the checkpoint chooses keep-or-retire.
- enforce-memory is the only armed enforcement whose disposition could self-lockout. If a retire reveals
  another armed dependency (a second hook demanding the marker): STOP and re-scope the ordering before
  removal.
- `scripts/check-assumption-ledger.sh` accepts the authorized Phase-83 A5 `revisit-status: open → held` flip
  (a NON-BLANK status change the `--append-only` rule may forbid, since policy authorizes only blank→value
  fills). FIRST verify what `--append-only` actually enforces (block-presence only, or field-level
  immutability) by running it against the proposed edit; if it forbids the legitimate `open → held`
  resolution: extend the validator's `--append-only`/schema block in the SAME commit as the flip (it is
  kit-managed, not frozen apparatus) — never bypass or hand-wave the validator. The A5-not-`open` exit check
  requires the in-place flip (a new-block reference would leave A5 `open` and fail it), so the flip must land.
- The maintainer is available for the enforce-memory checkpoint. If false: the round stops with
  enforce-memory `deferred-inadmissible` and the other five rows recorded; nothing destructive executes.
