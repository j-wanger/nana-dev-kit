# Pre-registration — Skill-Crystallization Headroom Screen (Phase 78)

Committed BEFORE any OFF run. Anti-retrofit: `git merge-base --is-ancestor "$(cat .prereg-commit)" HEAD`
must hold (this file's commit precedes every `runs/` output and `classification.md`). Design hardened by
an agent-internal adversarial review (2026-06-04) — findings C1–C4 / M1–M5 are addressed here.

## Claim under test
Crystallizing a phase's TOOLING into a reusable skill adds value over bare re-derivation only to the
extent the tooling embeds NON-RECOVERABLE correctness — correctness a bare frontier model fails to
reproduce even when given the RECOVERABLE CORPUS (`R_A`) a non-crystallized consuming project actually
has (the artifact's interface + docstring-goal + call sites + task), but NOT the implementation or its
tests. Honest prior: SPLIT — general tooling DEGENERATE, subtle domain (survivorship) correctness
HAS-HEADROOM.

## Protocol (frozen)
- **OFF** = a clean subagent given EXACTLY the pinned `R_A` corpus (below), no repo/tool access to the
  implementation or tests (verifier independence — review C2: `R_A` is the recoverable corpus, never a
  lossy brief). Fixed instruction appended: "Output only the code; no prose, no markdown fences."
- **n = 5** OFF samples per candidate/control; **CONSENSUS_THRESHOLD = 4** (cloned from
  `anchor-screen/check.sh`, review M1). Score each sample with `check.sh --run <candidate> <output>`;
  aggregate with `check.sh --aggregate` (NO LLM).
- **Scoring** runs ONLY the pre-registered spec-implied assertions (the per-candidate harness). A failure
  reports the first-failing assertion-id; HAS-HEADROOM requires the SAME assertion to fail ≥4/5
  (consensus-by-assertion, not OR-of-failures).
- **Leak guard** (review C4/M5): every `R_A` is leak-clean against `leak-vocab.txt` (global) + its
  `corpus/<candidate>.offleak` (answer tokens ∪ hidden-test fixture literals). `bash leak-check.sh` passes.

## Verdict ladder (frozen)
- Per candidate: **DEGENERATE** (≥4/5 PASS — re-derivable from `R_A`), **HAS-HEADROOM** (≥4/5 FAIL on the
  same spec-implied assertion — non-recoverable correctness), **UNSTABLE** (neither consensus). A
  failure on an UNSTATED-EDGE assertion is recorded **SPEC-INCOMPLETE** and NEVER counts as headroom.
- **UNSTABLE disposition** (review M2): an UNSTABLE candidate counts as NOT measurable for the
  ≥2-measurable gate and never contributes a DEGENERATE→TERMINATE vote.
- **Controls gate the program verdict** (review M3): if the NEGATIVE control is not ≥4/5 PASS, OR the
  POSITIVE-UNKNOWABLE control is not ≥4/5 FAIL, OR the RECOVERABLE-FULLY-SPECIFIED control is not ≥4/5
  PASS ⇒ `^PROGRAM-VERDICT: INSTRUMENT-DEAD` (do not report a real-candidate verdict).
- Program: all measurable real candidates DEGENERATE ⇒ **TERMINATE** (don't build the module). ≥1 real
  candidate HAS-HEADROOM ⇒ **HAS-HEADROOM** (building justified, scoped to the candidate class that
  showed it; + the router reframe — skill vs regression-test/lint vessel). <2 real candidates measurable
  ⇒ **INCONCLUSIVE**.
- **Cost-delta** (turns/tokens) is recorded-only; NO verdict logic reads it (review M4).

## Real candidate 1 — edge-screener `MembershipEligibility.eligible_on` (DOMAIN; prior HAS-HEADROOM)
- `R_A`: `corpus/edge-eligibility-corpus.txt`. Harness: `harnesses/edge-eligibility.sh` (guarded driver
  `fixtures/edge-eligibility/driver.py`; frozen dependency `fixtures/edge-eligibility/membership.py`).
- **Quoted `T_A` correctness test** (C1 — located in `edge-screener/tests/unit/test_membership_eligibility.py`,
  this is the assertion the candidate's non-obvious correctness lives in):
  ```python
  def test_removed_name_is_eligible_inclusive_through_its_removal_date() -> None:
      elig = _eligibility()
      # BBB leaves day 200: held THROUGH day 200 (so the crater books while held)...
      assert "BBB" in elig.eligible_on(BASE + timedelta(days=199))
      assert "BBB" in elig.eligible_on(BASE + timedelta(days=200))  # inclusive — the crux
      # ...and dropped strictly after.
      assert "BBB" not in elig.eligible_on(BASE + timedelta(days=201))
  ```
- **Spec-implied assertions** (counted; each with its entailing `R_A` sentence — review C3):
  - `inclusive-through-d` — entailed by: *"when a name is DELISTED / leaves the index, the strategy must
    still BOOK THAT NAME'S DELISTING RETURN ... for it to be booked, the name must still be HELD (and
    therefore scored/eligible) at the point the crater lands"* combined with the dependency fact *"A
    REMOVE with effective_date == d takes effect ON day d (so a name removed at d is NOT in
    members_on(d))"*. Booking the crater therefore requires keeping the name eligible through d even
    though `members_on(d)` has dropped it. (The corpus states the GOAL, never the add-back implementation.)
  - `superset-same-day` — corollary of `inclusive-through-d` (eligible exceeds members only by same-day removals).
  - `quiet-date`, `not-yet-added`, `re-added` — entailed by *"decides which S&P 500 names are scorable ...
    at a given point in time"* + the `members_on` semantics (basic point-in-time correctness).
- **Unstated-edge** (NOT counted; SPEC-INCOMPLETE if seen): `before-baseline-returns-baseline` — the
  pre-baseline calendar handling (`max(as_of, start_date)`). `R_A` does not mention pre-baseline dates,
  so a miss here is corpus-incompleteness, not non-recoverable correctness. (Not in the driver's scored set.)

## Real candidate 2 — nana-dev-kit `check-install-drift.sh` core (GENERAL; prior DEGENERATE)
- `R_A`: `corpus/nana-drift-corpus.txt`. Harness: `harnesses/nana-drift.sh`.
- **Contract reduction (disclosed)**: the candidate is the CORE comparator correctness of
  `scripts/check-install-drift.sh` — a recursive source-vs-installed compare that reports drift —
  contract-reduced for isolated testability. The project-specific parts (the `modules.json`
  comparison-set scoping, the bounded exclusion allow-list, the fail-open guards) are **unstated-edge**
  and out of `R_A` by construction.
- **Quoted `T_A` correctness test** (C1 — located in `tests/test_install.sh`, the detects-drift assertion):
  ```bash
  test_start "drift: detects an injected drift in a skill companion"
  DROOT=$(mktemp -d); make_synced_root "$DROOT"
  echo "DRIFTED" >> "$DROOT/skills/dev-debrief/delivery-flow.md"
  DEC=0; DOUT=$(bash "$DRIFT_SCRIPT" "$DROOT" 2>&1) || DEC=$?
  if [ "$DEC" -ne 0 ] && echo "$DOUT" | grep -q 'delivery-flow.md'; then test_pass
  else test_fail "expected drift on delivery-flow.md (ec=$DEC out=$DOUT)"; fi
  ```
- **Spec-implied assertions** (counted; entailing `R_A` sentences):
  - `detects-drift` — entailed by *"it reports every kit-managed file whose installed copy differs from
    (or is missing relative to) the source ... drifted → report the offending file(s) and fail"*.
  - `silent-when-synced` — entailed by *"Synced → say nothing and succeed"*.
- **Unstated-edge** (NOT counted; SPEC-INCOMPLETE if seen): the exclusion allow-list, the `--count`
  fail-open contract, and absent-installed-root fail-open — `R_A` explicitly scopes these OUT.

## Controls (review M3 — four guards)
- **ctrl-negative** (`corpus/ctrl-negative-corpus.txt`, `harnesses/ctrl-negative.sh`): integer `add`. OFF
  MUST be ≥4/5 PASS (else OFF is lobotomized → INSTRUMENT-DEAD).
- **ctrl-positive** (`corpus/ctrl-positive-corpus.txt`, `harnesses/ctrl-positive.sh`): a project-pinned
  unknowable token (`rev-7f3a`, in `ctrl-positive.offleak`, absent from `R_A`). OFF MUST be ≥4/5 FAIL
  (else `R_A` is leaking the answer → INSTRUMENT-DEAD). Proves the instrument can SEE non-recoverable content.
- **ctrl-recoverable** (`corpus/ctrl-recoverable-corpus.txt`, `harnesses/ctrl-recoverable.sh`): a
  fully-specified `clamp`. OFF MUST be ≥4/5 PASS (else the corpora are systematically too thin and every
  HAS-HEADROOM is suspect → INSTRUMENT-DEAD). The symmetric partner to ctrl-positive.
- **.offleak** (per candidate): the fourth, per-`R_A` guard — `leak-check.sh` must pass on every corpus.

## Frozen-file pins (verify_pins reads these; `check.sh --verify-pins` must pass)
corpus: corpus/edge-eligibility-corpus.txt
shasum: 5f55bc1ebf5558a70576cbab30bfcb35cd9e9800cdfd0066c0aad1f054c2f64b
corpus: corpus/nana-drift-corpus.txt
shasum: 4c2fe700205d154594b67d05a3295dadafebb8616021a11acaef17d4e1771047
corpus: corpus/ctrl-negative-corpus.txt
shasum: ea00197160c369d5497310d0d07bc418f60f5b060519f2e519cbe4c23e61339a
corpus: corpus/ctrl-positive-corpus.txt
shasum: 87957a80f501c5e1af49958f4d59f92ee4a74632d921a770ff7fa1697c8f7eb9
corpus: corpus/ctrl-recoverable-corpus.txt
shasum: c0b4dbae245a9aed961094a9d1b309d4140a00a48c093d343d0aa7386f73b837
harness: harnesses/edge-eligibility.sh
shasum: f9d6a0d7efc4841a72c3b1abc7d0585e8ac6956e270d4a7d92b5870610270a0f
harness: harnesses/nana-drift.sh
shasum: cb40895923237be4cd9da6dc0aad0335369ef44ba590003cc94e2adcc4d9c931
harness: harnesses/ctrl-negative.sh
shasum: 238b24c67c13e0a4e64bac14ea2cf5f2e59a56f2a15f0292306e8a3dbc3fa842
harness: harnesses/ctrl-positive.sh
shasum: 4e87059d3bd5d6d86eae02098957b8e5bf87d454dad5db75f1e48e48f502b647
harness: harnesses/ctrl-recoverable.sh
shasum: 03fd9d707678a3f5f363fa697f62247e6b054877ea7111eef9e4ea962031ddb5
harness: fixtures/edge-eligibility/membership.py
shasum: 26cdd65b7f66e122806bab60c0c3eff4a59c47c152a6c0d159d453087bcf7383
harness: fixtures/edge-eligibility/driver.py
shasum: d13e4676693a4758bf7369c946a783ae9bd1058c00bffb00658c98a5f2a44992
