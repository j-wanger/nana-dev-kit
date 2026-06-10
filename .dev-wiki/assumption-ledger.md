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
