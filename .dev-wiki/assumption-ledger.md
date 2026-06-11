# Assumption Ledger

<!-- Schema + validator: scripts/check-assumption-ledger.sh (the `## Ledger schema` block) is THE single
     source of truth for this format. APPEND-ONLY: one `## Phase` block per phase, newest at the bottom;
     never rewrite a prior block except to fill a blank `revisit-status:` at debrief. The dev-plan
     assumption gate APPENDS a block when positions are taken; dev-debrief FILLS revisit-status at close. -->

## Phase 80 — Assumption-Surfacer Completeness Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Forced accept/reject/don't-know verdicts engage cognition rather than producing faster rubber-stamps"
- A2 | cost: high | position: reject | revisit-status: held | "The agent-CHOSEN assumption set can be trusted to be complete enough to gate on"
- A3 | cost: medium | position: accept | revisit-status: held | "The ledger's revisit-status will be filled (not write-only), given a debrief forcing-function"
- A4 | cost: medium | position: accept | revisit-status: held | "nana-dev-kit is the right substrate to build and dogfood this gate"

## Phase 82 — QA & Verification Sweep (ultracode)
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: don't-know | revisit-status: bit | "The seven repo-centric audit areas cover the silent-breakage surface that matters (maintainer named a missing axis: utilization/dead-weight, e.g. the barely-used MCP memory server)"
- A2 | cost: high | position: reject | revisit-status: held | "In-kit subagent context leak is acceptable for QA verification given an executed-command evidence standard plus orchestrator re-execution of clean rows"
- A3 | cost: medium | position: accept | revisit-status: held | "templates/ is the right direction-of-authority default and the planning-time 6-file resync overwrote no unbackported ~/.claude hot-fix"
- A4 | cost: medium | position: accept | revisit-status: held | "The pre-registered fix boundary (kit-managed + non-frozen + S/M + test-covered blast radius; coverage exception: writing the missing S/M functional test IS the fix; >10 confirmed defects stops the phase) is the right autonomy contract"
- A5 | cost: high | position: accept | revisit-status: held | "REVISES A1: eight areas — adding a deterministic usage/utilization audit whose under-use findings feed the parked Phase-79 prune-on-value item — cover the silent-breakage-and-dead-weight surface"
- A6 | cost: high | position: accept | revisit-status: held | "REVISES A2: subagents demoted to candidate-generators with orchestrator-executed deterministic commands as the SOLE verdict evidence (clean and defect-found alike) makes verification sound despite the leak"

## Phase 83 — Prune-on-Value Subtraction
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Installed deregistration is mechanically safe: a cut hook's settings entry can be removed from live ~/.claude + consuming-project settings.json without corrupting the hooks shape (sandbox-first rehearsal + survivor functional smoke), despite no deregistration mechanism existing today"
- A2 | cost: high | position: accept | revisit-status: bit | "The Phase-82 usage zeros measure absent demand, not the dormancy eras — the window is sound post-enforcement-restoration, with per-candidate couldnt-fire/didnt-fire arming as the plumbing check"
- A3 | cost: high | position: reject | revisit-status: held | "The three liveness-grep roots (repo, ~/.claude, edge-screener) are the COMPLETE installed surface — maintainer rejected: other installs may exist"
- A4 | cost: medium | position: don't-know | revisit-status: held | "The reinforcement arming test is decidable: a seeded near-duplicate on the live install's actual dedup path settles couldnt-fire vs didnt-fire despite the unknown 0/55 base rate"
- A5 | cost: medium | position: don't-know | revisit-status: open | "The kit's own 55 memory entries are real voluntary-layer use, scoping candidate 3 to scaffold-shipping only — undefendable (access counts ~0, reinforcement never fired); DOWN-SCOPED: plan stays agnostic, kit-side memory-layer value question deferred to Blockers, must-revisit"
- A6 | cost: high | position: accept | revisit-status: held | "REVISES A3: the installed surface is mechanically DISCOVERED at T1 (kit-marker scan over this machine: .nana-dev-kit-path, .claude/hooks kit scripts, .nana/ dirs, shell-profile exports) and every cut's liveness grep runs over all discovered roots; residual: other machines out of reach"
- A7 | cost: medium | position: accept | revisit-status: held | "REVISES A4: defended with code+venv evidence — live install lacks fastembed and storage.py only reinforces at cosine >0.90 (unreachable without embeddings; word-overlap path only warns), so candidate 2's zero is largely pre-classified couldnt-fire → keep/harden semantics, never a demand-evidence cut"

## Phase 84 — Hook & Registration Hygiene
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: bit | "A success/failure signal for the two dormant hooks is recoverable — present in the current PostToolUse event or reconstructible from verifiable state (git state / tool_response.stderr); capture-first T2 with three pre-declared evidence-forced branches (remap / trigger-redesign / file-upstream+disable-at-boundary)"
- A2 | cost: high | position: don't-know | revisit-status: open | "Ghost global registrations are not load-bearing after matrix+checkpoint — REVISED with evidence (ghosts ARE the only wiring for 8 hooks in 3 roots: stock-screener, ai-game, fate; edge-analyst+edge-screener 11/11 local) — still don't-know on the no-invisible-dependency-class claim; DEFERRED: no live settings execution rides on this gate; remediate-then-deregister prepared as checkpoint default, execution only on explicit checkpoint approval or deferred to a follow-up round"
- A3 | cost: medium | position: accept | revisit-status: held | "Exporting CLAUDE_PROJECT_DIR=$WORK_DIR in the eval harness reproduces the platform guarantee at hook invocation; unset-variant test covers the hooks' :-. fallback branch as the hedge"
- A4 | cost: low | position: accept | revisit-status: held | "The four Phase-82 pinned repros still reproduce at HEAD — VERIFIED at gate time (all three sandbox repros rc=1/dormant + eval-runner grep CLAUDE_PROJECT_DIR = 0), dissolved from assumption to fact"
- A5 | cost: medium | position: accept | revisit-status: held | "The eval surface absorbs the woken hooks: ~6 affected corpus scenarios updated, legacy exit_code fallback retained, 52-scenario denominator unchanged, every flip explained in eval-diff.md; mass unexplained flips = hard stop"

## Phase 85 — Install-Gap Fix + Edge-Screener Dogfood
- date: 2026-06-10
- all_accept: false
- A1 | cost: high | position: don't-know | revisit-status: held | "Incident 5's causal path was the Phase-82 drift-guided resync and py-init/ts-init recursive copies are sound, so install.sh-global + checker fixes cover ALL real shipping paths — DEFERRED (Phase-84 A2 pattern): T1 inventory completes BEFORE checkpoint 1, nothing live touched on this assumption's authority, spec conditional clause expands scope on refutation"
- A2 | cost: high | position: accept | revisit-status: bit | "Duplicate hook entries across edge-screener settings.json + settings.local.json double-fire — accepted as working model WITH mandatory pre-checkpoint-2 empirical verification (real piped event in sandbox) and STOP-and-re-present if contradicted"
- A3 | cost: medium | position: don't-know | revisit-status: held | "Presence of session-start.sh at ~/.claude justifies shipping/currency-checking its .d/ there — DOWN-SCOPED with evidence (copy is registration-dead: zero references in ~/.claude/settings.json, all live registrations project-local, positive control passed): installer invariant + checker cells proceed independent of the copy's fate; ship-vs-dispose of dead ~/.claude project-scope copies decided explicitly at checkpoint 1 with the full inventory"
- A4 | cost: medium | position: accept | revisit-status: held | "The hook_dirs schema migration's consumer set is exactly 4 files — defended with exhaustive repo-wide grep (install.sh:72, test_registration.sh:62, test_hook_firing_coverage.sh:40, harness-audit.sh:385; no hook_dirs name collision; all 4 covered by make test)"

## Phase 86 — Ceremony Lift Measurement
- date: 2026-06-10
- all_accept: true
- A1 | cost: high | position: accept | revisit-status: held | "Stage-1 evidence (admissibility-ruled demand table + cost table) suffices for an informed HUMAN disposition at the hard checkpoint — ACCEPTED AT ROUND 2 after maintainer rejected the reversible-disposition down-scope: stage 1 mints NO verdicts, the closed keep/trim/cut/ambiguous enum is the maintainer's menu, and the agent-counterfactual residual (would the implementing agent have caught it without the reviewer?) rides as an explicit caveat column absorbed by the maintainer"
- A2 | cost: high | position: accept | revisit-status: bit | "Pre-fix states are recoverable for enough historical reviewer findings (git ancestors / transcript-extracted file state) that the review step's rows do not all downgrade to ambiguous; pinned downgrade direction handles any shortfall honestly rather than minting evidence"
- A3 | cost: medium | position: accept | revisit-status: held | "Per-step ceremony cost is deterministically extractable from session transcripts — DEFENDED with spike evidence at gate time (one real 3.2M session: 565 usage-bearing messages, 299,574 output tokens summed, Skill invocations identifiable by name, per-message timestamps); heuristic session→phase and step-boundary attribution gated by a positive control on a known-composition session before any cost row counts"
- A4 | cost: high | position: accept | revisit-status: held | "In-kit retrospective tabulation of historical FACTS is outside the Ph80 leak class (which poisoned clean-context agent-BEHAVIOR measurement), provided the pre-registered corpus (fixed phase window + mechanical enumeration of ALL reviewer/spec/debrief dispatches incl. zero-catch denominators) closes the prior-driven row-selection channel"
- A5 | cost: low | position: accept | revisit-status: held | "At least one ceremony step is decidable from stage-1 evidence alone — the screen narrows the stage-2 question (debrief's consumption-only evidence class and review's Phase-85 marginal catch already point in opposite directions); if false, the cost table + keep-by-immateriality branch are still valid cheap outcomes"

## Phase 87 — Ceremony Stage-2 Episode Contrast
- date: 2026-06-10
- all_accept: true
- A1 | cost: high | position: accept | revisit-status: held | "The Phase-85 enforcement state is reproducible into the setup commit so hooks FIRE in both clones (gitignored settings.local.json + untracked .claude/enforce force-added per provisioning manifest) — guarded by a HEU-012 scratch-clone hook-fire probe (real event piped, exit 2 asserted) before any arm tokens; registered-but-broken arm-B treatment = the episode measures nothing"
- A2 | cost: high | position: accept | revisit-status: bit | "A canned-gate ceremony arm is representative enough for the spec-generation disposition (the primary customer runs /spec --internal with NO user gate); a tie/loss carries the bundle-attribution caveat rather than reading as decapitated-ceremony evidence; claim ceiling bars verdicts on gate-dependent steps"
- A3 | cost: high | position: accept | revisit-status: held | "Cutting both clones from a CHILD setup SHA (368e056 + parity setup commit) is faithful to the frozen 'twin worktrees from the same git state' — the freeze fixes same-state, not the literal SHA; deviation re-presented explicitly at the setup HARD checkpoint for the record"
- A4 | cost: medium | position: accept | revisit-status: held | "Two same-model budget-capped sessions are drivable non-interactively under the closed gate-response policy — ACCEPTED AT ROUND 2 as SPIKE-DEFENDED after initial don't-know: a scratch drivability spike (gate-bearing session driven to stop point) runs BEFORE the setup checkpoint, STOP after 2 mechanism attempts; arm DNF is a recorded result row, never a quiet re-run"
- A5 | cost: medium | position: accept | revisit-status: held | "Seeding the settings.local.json single-registration invariant into edge-screener's dev-wiki is an acceptable checkpoint-gated write (true documentation, Ph85-verified) and the ceremony arm can plausibly surface it via dev-plan's dev-wiki reading; seed rejected at checkpoint = frozen control unrunnable = STOP, no unilateral substitute"
