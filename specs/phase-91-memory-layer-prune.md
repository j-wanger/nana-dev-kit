<!-- nana:approved 2026-06-12 -->
# Spec: Phase 91 — Memory-Layer Prune Round

## Objective

Take the deferred memory-layer dispositions — assumption-ledger Phase-83 block row A5 (kit-side memory MCP layer value, `revisit-status: open`), Phase-88 block rows A4/A6 (held reject positions deferring the layer disposition and the bridge/harvest writer trims), and the Phase-83 enforce-memory keep-with-revisit — each to a closed-enum verdict (keep / cut / harden / disable-at-boundary / deferred-inadmissible) grounded in the Phase-89 pre-registered demand evidence, gated by a standalone admissibility ruling committed BEFORE any verdict row is filled. Zero cuts is a valid outcome; an inadmissible-evidence ruling downgrades the round to an evidence-gap filing with zero dispositions, also valid.

## Context

Phase 88's direction gate rejected the Phase-85 dogfood zero as demand evidence (ledger Phase-88 block A4) and kept the bridge/harvest writers alive so a future round would get clean writer evidence (Phase-88 block A6). Phase 89 then ran a pre-registered four-stage evidence round and filed `eval/dogfood-round/evidence/memory-demand.md`: across 3 real edge-screener sessions on a liveness-probed LIVE layer, memory-tool use was ZERO three ways (no hook coercion — enforce-memory fired-allow throughout; the always-loaded rules instruction to search memory at session start was voluntarily skipped; no spontaneous use), and the layer's design case — a genuine multi-session continuity need — arose naturally and was served entirely by the `.dev-wiki` file substrate. Kit-side (informational, Ph80 leak class — the kit is not a clean demand substrate): the bridge writer is LIVE (2 stores + 1 same-session read-back), and one hook-prompted block→COMPLY event gives the Phase-83 firing-distribution revisit its first post-restoration block datapoint. Phase 83 already settled consumer-shipping (verdict table row memory-mcp-scaffold = keep: py-init/ts-init ship nothing memory-specific; the layer reaches consuming projects via the global `~/.claude` MCP registration, with the DB CWD-resolved per project). The kit's history binds both directions: 5 registered-but-broken instances warn that a zero can measure broken plumbing (couldnt-fire), and the Phases-19-48 memory loss warns that destructive dispositions can be irreversible. fastembed has been live in the maintainer venv since 2026-06-09 (cosine reinforcement verified), so post-that-date zeros measure demand, not a dead embed path.

Ledger row targeting (A-ids are reused per phase block — bare-id greps mis-target): the rows this round closes are the Phase-83 block's A5 (the only `revisit-status: open` memory row) and the Phase-88 block's A4 and A6 (`revisit-status: held` reject rows whose rationale defers to this round — closed via the Blockers filings and this round's verdict table, NOT by editing their ledger rows). The Phase-88 block's A5 row is the ak-ride-along trim-trial — Phase-93 authority, NOT a target of this round.

## Scope

### In scope

A closed verdict-row set, one row per (component × evidence pointer):

1. `memory-mcp-layer` — the vendored `memory_server/` + the global MCP registration + the kit's own ~89-entry store (ledger: Phase-83 A5, Phase-88 A4). The vendoring contract shapes the row's removal-set column (keep / disable-at-boundary / cut with regenerated patch series); the verdict CELL token is always one of the closed enum.
2. `bridge-writer` — dev-plan Step 15a-bis bridge stores (ledger: Phase-88 A6).
3. `harvest-writer` — debrief memory-harvest (ledger: Phase-88 A6).
4. `enforce-memory-demand` — the Phase-83 keep-with-revisit demand question, decided on the post-restoration firing distribution (allow/block ratio, block follow-through).

Plus three artifacts: (a) the standalone admissibility ruling on the Phase-89 evidence (committed before any verdict row); (b) the memory-reference surface enumeration (repo AND installed trees, every hit classified `mcp-layer | auto-memory | unrelated`); (c) for every cut/disable verdict, the removal set, store backup, and installed-surface deregistration over kit-marker-discovered roots.

Plus exactly one authorized prior-block ledger edit (see Constraints): flipping the Phase-83 block A5 row's `revisit-status: open` → `closed (Phase 91, <verdict-table pointer>)`. The Phase-90 direction gate appends its own block as normal.

### Out of scope

- The two Phase-88 trim-trials (ak-ride-along d43950f, wk-seeding df3e623) and their restore-or-confirm disposition — Phase-93 debrief authority; no reverts of d43950f / df3e623 / 75b48af / b8bd416. The ledger Phase-88 A5 row (ak-ride-along) is not touched.
- Working-knowledge entry pruning and the filed hook-hardening candidates (py-review docs-only-diff, enforce-memory resume-artifact marker semantics, check-tests-were-run residue) — separate rounds; the resume-artifact finding may be CITED as evidence in the enforce-memory-demand row but its fix is not executed here.
- Editing user-owned `~/.claude/rules/` files (nana-soul.md, file-lifecycle.md instruct memory_search/memory_store) — the kit cannot edit them; any verdict leaving them dangling carries an explicit maintainer action item instead.
- Claude Code's native auto-memory (`~/.claude/projects/*/memory/`) — a different system; explicitly excluded from every removal set and file-touch list.
- memory_server upstream feature work; re-running evidence sessions (this round adjudicates the filed evidence, it does not gather more).
- Frozen apparatus: `eval/dogfood-round/**` EXCEPT `evidence/window-events.md` (the standing cross-phase accumulator — Phase-90 sessions append to it per the pre-registration protocol), `eval/amplifier/**`, `eval/assumption-screen/**`, `eval/qa-sweep/**` — read-only. The assumption ledger body is append-only EXCEPT the one authorized A5 status flip above.

## Approach

Admissibility-first, then Phase-83 prune discipline. The admissibility ruling is a standalone artifact whose add-commit must be a strict ancestor of the verdict table's add-commit (different commits — a same-commit add defeats the ancestry check); it rules on the Phase-89 evidence against the pinned A4-reject rationale and must cite the liveness probe's positive control, not file presence. Only then is the verdict table filled: per row, classify the zero (couldnt-fire vs didnt-fire, sandbox-armed in `mktemp -d`), define the removal set FIRST, run liveness grep where alive = references from outside the removal set across repo + all kit-marker-discovered installed roots. The evidence split is honored per row: consuming-project demand evidence (the three-way zero, the continuity case) bears on the layer's consumer-facing reach; kit-side writer liveness (2 stores + read-back) bears on the writers — no blanket verdict across components with opposite evidence. HARD maintainer checkpoint with the complete table before any execution. Approved verdicts execute serially, each preceded by a verified store backup, with sandbox-rehearsed deregistration, survivor functional smoke, and revert-on-failure. The templates/modules.json byte-freeze from Phase 89 has LAPSED for this phase; the no-revert pins above still bind.

Verdict-execution semantics (closed enum; cell tokens exactly as spelled):
- **cut** — remove the full removal set this phase, one commit per candidate, subject `Phase 91 cut: <candidate>`. A memory_server cut additionally regenerates the vendoring patch series in the same commit (the patch is removal-set discipline, not a separate verdict token).
- **disable-at-boundary** — remove registration/exposure without deleting code; SAME commit-subject and deregistration discipline as a cut (counted identically by the exit criteria).
- **harden** — verdict + filed follow-up with re-trigger; implementation out of this phase unless it fits the per-candidate commit discipline AND the maintainer approves it at the checkpoint.
- **keep** — re-affirmation citing the evidence line that earned it; no change.
- **deferred-inadmissible** — reachable only when the admissibility ruling is not `admissible` for that row's evidence strand; pairs with an evidence-gap filing naming what the next round must produce.

Table finality: verdict cells reflect FINAL checkpoint-approved verdicts. If the maintainer rejects a proposed verdict at the checkpoint, the row is rewritten BEFORE execution — the committed table never disagrees with what was executed.

### Domain Research Questions

1. What does Claude Code do today when a registered MCP server's module is deleted or its registration removed — visible startup error, silent absence, or per-call failure — and what does each mode mean for sessions in consuming projects the kit cannot reach?
2. What is the full post-restoration enforce-memory firing distribution (allow/block ratio, block follow-through) across all recorded sessions — and what claim, if any, does a single block→COMPLY datapoint support?
3. Does the file substrate (`.dev-wiki` + auto-memory MEMORY.md) cover every routing the user's file-lifecycle.md assigns to `memory_store` ("persistent fact → memory_store"), or is there a residual class only the MCP layer serves?

## Constraints (CRITICAL)

- The admissibility ruling is committed BEFORE any verdict row exists (strict ancestry: different add-commits, ruling's an ancestor of the table's) and rules independently of the desired verdicts — prevents writing the ruling backwards from the table (retrofit class; the A4 reject is the binding precedent it must answer).
- Store backup before ANY destructive disposition: `memory_export` (or `sqlite3 .backup` after a WAL checkpoint — the live DB has open -wal/-shm journals; a naive mid-session file copy captures a torn snapshot), with exported entry count asserted equal to `memory_stats` in the same session; the cut commit references the archive path; the verdict table carries a `BACKUP-VERIFIED: <path> <count>` line — prevents a second Phases-19-48-class irrecoverable loss.
- Disposition ordering pins the self-lockout hazard: `~/.claude/enforce-memory` is ARMED on this machine NOW; any layer cut/disable lands before-or-atomically-with the hook's own disposition, and the pairing is sandbox-verified by piping a real PreToolUse event with the server absent, asserting BOTH allow and block paths — prevents a surviving blocking hook demanding actions that are no longer possible (the Phase-82 enforce-spec self-lockout class).
- Couldnt-fire vs didnt-fire classification is mandatory per destructive row before execution; couldnt-fire = defect filing, never a demand-evidence cut ([[HEU-012]]).
- Every cut ships deregistration over ALL kit-marker-discovered installed roots (Phase-84 coverage-matrix method), and the verdict row carries an explicit `unreachable-installs:` line stating how a stale unreachable consumer degrades (verified by simulating a consumer with the server absent — noisy or harmless, never assumed) — prevents silent ghost registrations (the settings merge is add/update-only; no deregistration mechanism exists until a cut builds its own).
- The surface enumeration counts as evidence only after a positive control (a known-present surface must appear) and only with ≥2 independent naming conventions (`memory_`, `memory.db`, `memory_server`, server name `"memory"`, `enforce-memory`) over BOTH repo and installed trees; the artifact contains exactly ONE classification table, every row classified `mcp-layer | auto-memory | unrelated` — prevents count-fitting to "20", the Ph84 zsh word-split false-matrix class, and auto-memory conflation in either direction (false-keep from auto-memory writes, collateral damage from a careless cut script).
- Ledger edit carve-out: the ONE permitted prior-block edit is flipping the Phase-83 block A5 row's `revisit-status: open` → `closed (Phase 91, <pointer>)`; `scripts/check-assumption-ledger.sh` must pass after the edit; no other prior-block byte changes (the Phase-88 A4/A6 held rows are closed via Blockers filings + the verdict table, not ledger edits) — prevents both the silent-open-forever state and a general license to rewrite history.
- Per-candidate expected deltas (eval denominator, hook count, settings entries) are pre-registered in the verdict row before execution; regenerated-artifact diff ⊆ planned removal set; no hand-edits to generated artifacts — prevents wholesale regeneration absorbing over-deletion.
- Post-cut functional smoke on SURVIVING hooks (pipe a real event, assert firing), never presence checks — the 5-times-bitten registered-but-broken class.
- Evidence split discipline: consuming-project evidence may not justify cutting a kit-side-live writer, and kit-side liveness may not justify keeping consumer-facing reach — each row cites its own evidence pointer (file + line/section).
- Window-events attestation rows appended for EVERY Phase-90 working session under a `## Phase 91` section of `eval/dogfood-round/evidence/window-events.md` (pre-registration protocol) — the Phases-90-93 standing obligation is itself an exit criterion here.
- Exit-criteria commands below are normative for `eval/memory-prune/run-exit-criteria.sh` but the runner platform-normalizes them (`tr -d ' '` after `wc`, BSD/GNU portability) — the Phase-88/89 runner pattern; semantics may not weaken.
- Prior decisions bind: [[memory-architecture-classification]] (as superseded — MCP = voluntary layer), [[vendor-memory-server]] (near-zero divergence contract), [[single-source-scope-tagged-hook-registration]], the Phase-83 verdict table (memory-mcp-scaffold keep, memory-reinforcement harden), [[prune-on-value-subtraction]].
- Zero cuts is a valid outcome; verdicts are evidence-forced, not quota-driven.

## Success Vision

Every open memory-layer ledger obligation (Phase-83 A5 open row, Phase-88 A4/A6 deferral rationale, the Phase-83 enforce-memory revisit) reaches either a filled disposition or an explicit ruled-inadmissible evidence-gap filing — none remain silently open. A reader of the verdict table can trace each verdict to an admissibility-ruled evidence pointer and see what the zero meant, what was removed or kept, and why opposite-evidence components got different verdicts. If cuts executed: the store is archived with verified counts, no surviving component is collaterally damaged, installed copies and repo agree (drift 0), and the dangling user-owned-rules state is a named maintainer action item, not a silent orphan. The assumption ledger's memory rows finally close their revisit loop.

## Exit Criteria (machine-checkable)

All via `eval/memory-prune/run-exit-criteria.sh` (ALL-PASS required). Candidate row names bare at line start: memory-mcp-layer, bridge-writer, harvest-writer, enforce-memory-demand. `DROW` below abbreviates the destructive-row pattern `^\| (memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory-demand) .*\| (cut|disable-at-boundary) \|` (candidate-anchored — legend/prose cells never count).

- [ ] `test -f eval/memory-prune/admissibility-ruling.md && grep -qE '^RULING: (admissible|partially-admissible|inadmissible)' eval/memory-prune/admissibility-ruling.md` — standalone ruling with a closed-vocabulary verdict line
- [ ] `R=$(git log --diff-filter=A --format=%H -- eval/memory-prune/admissibility-ruling.md | tail -1); T=$(git log --diff-filter=A --format=%H -- eval/memory-prune/verdict-table.md | tail -1); test -n "$R" && test -n "$T" && test "$R" != "$T" && git merge-base --is-ancestor "$R" "$T"` — ruling committed strictly before the verdict table (anti-retrofit ancestry; same-commit add fails)
- [ ] `grep -oE '^\| (memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory-demand) ' eval/memory-prune/verdict-table.md | sort -u | wc -l | tr -d ' ' | grep -qx 4` — exactly the 4 candidate rows
- [ ] `! grep -E '^\| (memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory-demand) ' eval/memory-prune/verdict-table.md | grep -vE '\| (keep|cut|harden|disable-at-boundary|deferred-inadmissible) \|'` — every candidate row carries a closed-enum verdict cell
- [ ] `! grep -E 'DROW' eval/memory-prune/verdict-table.md | grep -vE 'couldnt-fire|didnt-fire'` — every destructive row carries its zero-classification (runner expands DROW)
- [ ] `test -f eval/memory-prune/surface-enumeration.md && grep -q 'POSITIVE-CONTROL: PASS' eval/memory-prune/surface-enumeration.md && ! grep -E '^\| S' eval/memory-prune/surface-enumeration.md | grep -vE '\| (mcp-layer|auto-memory|unrelated) \|'` — enumeration with passed positive control; surface rows (id prefix `S`) all 3-way classified
- [ ] `test "$(grep -cE 'DROW' eval/memory-prune/verdict-table.md | tr -d ' ')" -eq 0 || grep -q 'BACKUP-VERIFIED: ' eval/memory-prune/verdict-table.md` — store backup verified before any executed destructive verdict (vacuous at zero cuts)
- [ ] `test "$(git log --oneline --grep='^Phase 91 cut:' | wc -l | tr -d ' ')" = "$(grep -cE 'DROW' eval/memory-prune/verdict-table.md | tr -d ' ')"` — one commit per executed destructive verdict (both sides 0 at zero cuts)
- [ ] `make test && make eval && bash scripts/check-install-drift.sh && bash tests/test_settings_template.sh` — suite green, eval denominator 50 or diff explained in the verdict table, drift 0, generated settings match modules.json
- [ ] `grep -q '^## Phase 91' eval/dogfood-round/evidence/window-events.md && bash scripts/check-assumption-ledger.sh && ! awk '/^## Phase 83 /,/^## Phase 84 /' .dev-wiki/assumption-ledger.md | grep -qE '^- A5 .*revisit-status: open'` — window-events obligation met, ledger validator green, and the Phase-83 A5 row no longer open

## Checkpoints

- After the admissibility ruling and BEFORE filling verdict rows: report the ruling to the maintainer. If `inadmissible`: STOP dispositions — the round becomes an evidence-gap filing with a re-arm plan (what evidence the next round must produce), all rows `deferred-inadmissible`.
- After the verdict table is complete and BEFORE any execution: HARD maintainer checkpoint — full table (row, evidence citation, zero-class, proposed verdict, removal set, expected deltas, unreachable-installs line) PLUS the named user-action item for the user-owned rules files if any verdict dangles them. Unconditional; no execution on direction-gate authority.
- If any row classifies couldnt-fire: file as defect, present with no cut offered.
- If the store backup count mismatches `memory_stats`: STOP before that cut.
- If a post-cut survivor smoke fails: revert that cut's commit before the next candidate.
- If a removal set requires editing frozen apparatus or user-owned files: defer that candidate with filing.

## Assumptions

- The Phase-89 evidence round's admissibility pins answer the A4-reject rationale (that is what they were pre-registered for). If false (the ruling finds a pin gap): rule `partially-admissible` or `inadmissible` per strand, never stretch — deferred-inadmissible rows are the honest outcome.
- The maintainer is available for the two checkpoints. If false: the round stops at the table; nothing executes.
- The post-2026-06-09 zeros were measured on a live embed path (fastembed installed, cosine verified). If false for any evidence window: reclassify that strand couldnt-fire and file the defect.
- `scripts/check-assumption-ledger.sh` accepts the authorized A5 status flip. If false (validator schema forbids non-blank rewrites): extend the validator's schema block in the same commit as the flip (it is kit-managed, not frozen apparatus) — never bypass or hand-wave the validator.
- Kit-marker root discovery enumerates every reachable installed root. If a known root is unreachable: file it on the `unreachable-installs:` line with its verified degradation mode; do not block the phase.
- The kit's ~89-entry store and live bridge writer represent the kit-side usage reality (not stale spam). If false (audit shows bridge-spam dominance): that is itself evidence FOR the writer rows' disposition — record it, widen no scope without a new maintainer decision at the checkpoint.
