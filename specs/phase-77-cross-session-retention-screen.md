<!-- nana:approved 2026-06-04 -->
# Spec: Phase 77 — Cross-Session Retention Headroom Screen (audit-gated ablation)

## Objective
Measure whether the persistent on-disk dev-wiki substrate lets a fresh agent session recover decisions/process-discipline that a substrate-free session loses across a real session boundary — using the real `/Users/jwang/edge-screener` project as a fixed historical subject. Deliver a deterministic instrument plus a pre-registered `PROGRAM-VERDICT` on the amplifier program's terminal (cross-session) regime.

## Context
The amplifier headroom-search has measured null in every regime so far: single-decision recall (Phase 70 — bare opus does the AML reasoning unprompted, all candidates DEGENERATE 5/5) and single-session/single-compaction retention (Phase 71 — the native compaction summary is decision-comprehensive, TERMINATE-by-summary-robustness). Both nulls were a property of the *boundary*, not a dead instrument (controls validated each). The one untested regime is **cross-session**: when a session ends, the native in-context summary dies, but the on-disk substrate (decision articles, `_CURRENT_STATE.md`, `active-phase.md`, `working-knowledge.md`, roadmap) persists. Phase 73 deliberately stood up an *external* real project (edge-screener) as the substrate to escape the Ph70/71 self-measurement confound, and deferred this measurement until that substrate accrued real multi-session history. That decidable-when gate is now green: edge-screener has 9 completed phases, 14 decision articles, 11 journals across 3 distinct dates (2026-05-31, 06-01, 06-02), 28 commits. This is the last regime; a degenerate result here closes the headroom-search line (the substrate would then be kept on operational grounds, not measured-headroom grounds). The honest prior is degenerate: facts are recoverable from code + tests + decision-rich commit bodies, so the substrate-unique surface is expected to be small.

## Scope
### In scope
- A new repo-only apparatus in `eval/amplifier/xsession-screen/` (sibling to `anchor-screen/`, `retention-screen/`), frozen on completion.
- T1 **residual audit** over edge-screener's real history: the deterministic set of dev-wiki decisions whose discriminating token is *absent* from the OFF-available inputs (source tree + test suite + `git log` commit bodies) and still resolves at HEAD.
- T2 **controlled OFF/ON ablation** on exactly the residual items (only if residual is non-empty and clears the n-floor), with bare-OFF, padded-OFF, and a planted positive control.
- T3 a `screen-record.md` carrying a grep-able `^PROGRAM-VERDICT:` plus a no-harness-value disclaimer and the git-log-as-substrate-channel interpretive caveat.
- Reuse of the frozen `retention-screen/` scoring primitives (`check.sh` run_check/aggregate consensus-by-clause, `leak-check.sh` + `leak-vocab.txt`, `assert-off-on-isolation.sh`) byte-verbatim wherever the cross-session boundary permits.

### Out of scope
- Any mutation of the edge-screener repo (it is a read-only subject) or of its dev-wiki.
- Wiring the apparatus into `install.sh` / `Makefile` / `make test` / `make eval` (frozen, repo-only — like the two prior screens).
- LLM-as-judge scoring of any kind.
- Re-measuring the within-session or single-decision regimes (closed in Ph70/71).
- Building a cross-session *recovery mechanism* (this phase measures; it does not construct a handoff feature).

## Approach
Audit-gated, cheapest-first. Run the cheap deterministic residual audit before committing to any expensive OFF/ON run; the audit's outcome gates whether T2 is built at all.

- **T1 — Residual audit (the gate).** For every decision in edge-screener's dev-wiki (decision articles + `_CURRENT_STATE.md` Recent-Decisions + `active-phase.md` + roadmap), extract a pre-registered *discriminating token* (the value that distinguishes the chosen path from the alternative — a threshold, a named clause, a sentinel, a negative decision's rejected option). For each, run a deterministic provenance check: the token must be **absent** from everything the OFF condition can see (`git grep` over the source tree, `grep -r` over tests, `git log -p`/commit bodies) AND must still **resolve at HEAD** (no since-deleted-artifact items) AND must be **pinned to its terminal value** (a later phase's reversal supersedes the original — recovering the dead value is a miss). The residual is the surviving set. Empty residual ⇒ `PROGRAM-VERDICT: TERMINATE` (UNMEASURABLE-cross-session); STOP, do not build T2.
- **T2 — Controlled OFF/ON ablation (only if residual non-empty and ≥ n-floor).** For each residual item, at its real session boundary, construct conditions over a *physically stripped* throwaway copy of the subject:
  - **bare-OFF:** source + tests + `.git` (incl. commit bodies), with all substrate paths deleted; a manifest assertion fails the run if any substrate file is present.
  - **padded-OFF:** bare-OFF + an equal-token volume of substrate-*shaped* but decision-empty filler (e.g. the project README padded to ON's token count) — the Phase-59 length/volume control.
  - **ON:** bare-OFF + the real dev-wiki substrate.
  - **positive control:** a planted, genuinely-unrecoverable decision carried only by the substrate; ON MUST recover it.
  Same next-task prompt across conditions. Score each item by the frozen consensus-by-clause checker over the discriminating token (exact match, NO prose similarity), n=5 per condition. Pre-registration committed BEFORE any run (anti-retrofit `git merge-base --is-ancestor` guard, mirroring Ph70/71). The **eligible-item floor is pinned at n≥3 distinct residual decisions** and committed in `pre-registration.md` BEFORE the residual count is known (its commit must be an ancestor of the residual-audit output) — below 3, a HAS-HEADROOM reading is an n=1/2 lucky-draw (the Phase-58/70/71 scar, where a single favorable draw read as a banked effect) and the verdict is forced INCONCLUSIVE.

  The new `residual-audit.sh --selftest` must prove its predicate both ways on a planted control pair (matching the `check.sh` selftest discipline): a planted token that IS present in the OFF inputs must be excluded from the residual, and a planted token that is genuinely absent must survive into it. A no-op `exit 0` selftest does not satisfy this.
- **T3 — Record + disposition.** Differential verdict ladder over {bare-OFF, padded-OFF, ON, positive-control}; cash the `PROGRAM-VERDICT`.

### Domain Research Questions
1. In edge-screener's history, which decisions are *negative* (a path rejected — e.g. "Stooq deferred, yfinance-only") or *process/sequencing* (ruler-before-edge-search; correct-survivorship-before-claiming-edge)? These are the candidates least likely to be code-materialized and most likely to survive the absence-grep.
2. Are the decision-rich commit bodies themselves a *harness product* (the debrief discipline wrote them)? If so, a null residual does not mean the harness adds nothing — it means the harness's value precipitated into git rather than into a separately-needed dev-wiki recall. How is that interpretive caveat recorded so the verdict is not over-read?
3. The eligible-item floor is pinned at n≥3 (committed before the residual count is known). Does the residual's decision-type mix (negative vs process vs factual) warrant a *higher* floor before a HAS-HEADROOM reading is trustworthy? Record the rationale in pre-registration.md; the floor may only move UP, never down to fit an observed residual.

## Constraints (CRITICAL)
- **No LLM in the scoring path** — deterministic consensus-by-clause only. Prevents the false-HAS-HEADROOM risk; an LLM judge would reintroduce the noise floor the campaign's evidence already cut. Guard: scoring is `grep -F`/regex over a pre-registered discriminating token; the checker has a `--selftest` that flips on a control pair.
- **OFF input set is physically stripped, not honor-system** — prevents the silent false-null where the agent reads `.dev-wiki/` that still exists on disk. Guard: build OFF from a `git archive`/copy with substrate paths deleted; a manifest diff asserts the OFF tree contains source+tests+`.git` and ZERO substrate files before the run, else fail closed.
- **Per-item provenance absence-grep** — prevents leakage inflating recovery value (a fact recoverable from code/tests/git scored as substrate value). Guard: each scored item carries a committed absence check (zero hits for its discriminating token across OFF's inputs); items that fail are excluded from scoring, not silently counted.
- **Length/volume control (padded-OFF)** — prevents the Phase-59 confound where ON wins on token volume, not substrate content. Guard: ON scores HAS-VALUE only if it beats BOTH bare-OFF and padded-OFF on the same items.
- **Positive control gates the null** — prevents a confound-induced false null from wrongly terminating the program's last regime. Guard: a planted substrate-only decision ON MUST recover; if it fails, verdict is `INSTRUMENT-DEAD` (blocks TERMINATE), not NULL.
- **Pin to terminal/HEAD-consistent value** — prevents rewarding the substrate for surfacing obsolete/reversed state. Guard: each item's scored value is the one consistent with HEAD; recovery of a superseded value is a miss.
- **HEAD-resolvability filter** — prevents items keyed on since-renamed/deleted artifacts being unverifiable. Guard: the discriminating token must still resolve at HEAD or the item is excluded at audit time.
- **Process-discipline items are behavioral artifacts, not assertions** — prevents the vacuous always-recover where any cooperative agent "says" it will follow process. Guard: each process item reduces to a deterministic artifact a bare agent cannot produce without the substrate (cites the correct next uncompleted task-id, honors a specific deferred-decision exclusion, names the active-phase number) + its own absence-grep.
- **Subject is read-only and isolated** — prevents mutating the fixed historical record or firing kit/edge-screener automation mid-measurement. Guard: every condition runs in a throwaway copy with hooks disabled (isolated `HOME`/`~/.claude` or stubbed); assert the original repo `git status` clean and substrate file hashes byte-identical before and after the full run; fail closed on drift.
- **n-floor forces INCONCLUSIVE** — prevents the n=1 false-positive scar (a single favorable draw reading as a banked effect, as in Phases 58/70/71). Guard: the eligible-item floor is pinned at **n≥3 distinct residual decisions**, committed in `pre-registration.md` BEFORE the residual count is known (floor-commit must be an ancestor of the residual-audit output, closing the retrofit hole the merge-base guard otherwise leaves open); below 3 the verdict is INCONCLUSIVE regardless of the OFF/ON delta.
- **Pre-registration before runs, ancestor-guarded** — prevents retrofitting the verdict. Guard: pre-registration.md committed separately; `git merge-base --is-ancestor <prereg> <verdict>` must pass.
- **Apparatus repo-only, frozen** — prevents surface churn. Guard: not referenced by `install.sh`/`Makefile`; `make test`/`make eval`/registration/firing-coverage counts unchanged.

## Success Vision
A deterministic, leak-checked instrument that returns an *honest* verdict either way. A null is informative only if the positive control proves the instrument is live and the residual audit shows *why* (the substrate-unique surface is empty because code+tests+commit-bodies already carry the decisions) — and the record explicitly distinguishes "substrate carries nothing unrecoverable" from "substrate is worthless," noting that the OFF baseline's git-log richness is itself partly a downstream product of the harness's own commit-discipline. A HAS-HEADROOM result names exactly which residual items the substrate alone recovered, having survived bare-OFF, padded-OFF, and the absence-grep. Excellence is the verdict being un-foolable in either direction, not the direction it points.

## Exit Criteria (machine-checkable)
- [ ] `test -x eval/amplifier/xsession-screen/residual-audit.sh && bash eval/amplifier/xsession-screen/residual-audit.sh --selftest` (audit predicate + absence-grep selftest pass)
- [ ] `test -f eval/amplifier/xsession-screen/residual.md` (residual enumerated or recorded empty)
- [ ] `grep -Eq '^PROGRAM-VERDICT: (TERMINATE|NULL|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)' eval/amplifier/xsession-screen/screen-record.md` (closed verdict vocabulary — a placeholder like `TODO` fails)
- [ ] If residual non-empty: `git merge-base --is-ancestor "$(cat eval/amplifier/xsession-screen/.prereg-commit)" HEAD` (pre-registration incl. the pinned n-floor precedes verdicts) AND `test -x eval/amplifier/xsession-screen/check.sh && bash eval/amplifier/xsession-screen/check.sh --selftest`
- [ ] If T2 ran: positive control recovered by ON (recorded pass) — else verdict reads `INSTRUMENT-DEAD`, not NULL
- [ ] `bash eval/amplifier/xsession-screen/assert-subject-untouched.sh` (edge-screener git status clean + substrate hashes byte-identical pre/post)
- [ ] `make test` green and `make eval` green (apparatus repo-only → no registration/settings/README/firing-coverage churn)
- [ ] Decision article + journal written

## Checkpoints
- After T1 residual audit: if residual is EMPTY (or below n-floor) ⇒ STOP, write `PROGRAM-VERDICT: TERMINATE`/`INCONCLUSIVE`, do NOT build T2. Report.
- After pre-registration commit, BEFORE any OFF/ON candidate run: confirm the ancestor guard and the controls plan are committed.
- If the positive control fails under ON: STOP, verdict `INSTRUMENT-DEAD` — do not report a null. Report.
- If the subject-integrity assertion detects drift: STOP, the run is contaminated — discard and report.

## Assumptions
- edge-screener's history is stable and read-only for the measurement window. If false (it is being actively worked in parallel): snapshot a pinned commit and measure against that snapshot only.
- The frozen `retention-screen/` scoring primitives transfer to a real cross-session boundary. If false (the boundary needs a materially different checker): clone-and-adapt with the diff explicitly recorded, keeping consensus-by-clause and NO-LLM intact.
- At least one residual item plus a constructible positive control exist. If false (zero residual): the verdict is `TERMINATE` (UNMEASURABLE-cross-session), which is itself the deliverable — not a failure.
- The OFF condition is entitled to full `git log` commit bodies (every real bare session has git). If this makes the residual near-empty, that is the expected honest finding, pre-registered as distinct from substrate-valuelessness.
