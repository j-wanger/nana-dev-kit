# Active Phase Context

Phase: NONE — Phase 74 COMPLETE (Harden the Consuming-Project Scaffold Path; reviewer SHIP, delivery accepted). Awaiting `/dev-plan` for the next direction.
Last completed: Phase 74 — fixed at the kit source the 4 scaffold defects the first consuming-project dogfood (edge-screener, Phase 73) surfaced.

Result: py-review Stop hook `prompt`→gated command hook (`py-review-stop.sh` — the planning-loop fix Jake hit; modules.json/settings.json command-typed, 3-path firing test, firing-coverage floor 20→21); py-init + ts-init Step 4 recursive hook copy (also fixed a dangling `cp *.md` T1 created by removing the last .md hook; the Phase-73 "curator gap" was a stale-INSTALLED-copy artifact — the source already copied curators); pyproject template ruff `.claude`/`data` exclude + mypy `files` (lints/types clean out of the box); AGENTS.md template domain-neutralized. #5 (dev-init/dev-plan CWD-coupling) DEFERRED. make test all-passed, make eval 52/52, eval/ git-diff-clean. Decision [[harden-consuming-project-scaffold]]; journal [[2026-05-30-phase-74-harden-consuming-scaffold]].

Process lesson (logged): a review subagent dispatched WITHOUT isolation:worktree reverted the uncommitted settings.json to HEAD (caught by make test, resynced via make template) — isolate review/explore agents that run make/git against uncommitted work.

Next direction (pick one via /dev-plan):
- The screener build itself — in its OWN repo (`/Users/jwang/edge-screener`, Phase 1 Data Foundation active there); fresh session there → `/dev-plan`.
- Deferred cross-session measurement — when the screener has accrued real multi-session history.
- Phase 74 soft-observation candidates — an installed-copy-drift guard (templates/ vs ~/.claude) and a fresh-scaffold smoke test (these defects were only caught by manual dogfooding).

See [[harden-consuming-project-scaffold]] + [[2026-05-30-phase-74-harden-consuming-scaffold]] + [[cross-session-substrate-stock-screener]].
