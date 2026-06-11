# Phase 87 Instrument Record

SETUP-SHA: 4ed8071
CHECKPOINT-ACK-SEED: maintainer approved seed write (T4 checkpoint, 2026-06-10) — article .dev-wiki/articles/decisions/hook-single-registration-invariant.md on p87-setup
CHECKPOINT-ACK-CLONES: maintainer approved setup branch + twin clones incl. setup-SHA deviation re-ack (T4 checkpoint, 2026-06-10)
CANARY-PRECHECK: PASS
RESTORATION-TEST: PASS
ISOLATION-PROBE: PASS
HOOK-FIRE-PROBE: PASS
DETECTOR-REHEARSAL: PASS
EXTRACTOR-SMOKE: PASS
CONTROL-HOOK: context-size-check.sh SessionStart

## Probe evidence (orchestrator-executed, 2026-06-10)

- RESTORATION-TEST: scratch clone + live-tracked.patch + live-untracked.tgz reproduces
  the live porcelain byte-exactly (diff of sorted porcelain empty); live checkout was
  never branch-switched (substrate built in a separate clone per amendment 001).
- CANARY-PRECHECK: staged-set grep for drq1|install-gap|nana-dev-kit — only the two
  amendment-001-ruled session-start hits; exclusions (backup tgz, edge-verdict-focus.md)
  held; kit-path marker hold pinned in amendments/001-kit-path-marker-held.md.
- ISOLATION-PROBE: refs arm-b=29 arm-a=29 == substrate=29; remotes empty in both;
  0 symlinks; 0 memory DBs; clones byte-identical excluding .git; no pre-existing
  ~/.claude/projects/ dirs for either arm slug.
- HOOK-FIRE-PROBE (HEU-012): real PreToolUse Write event piped into the scratch clone's
  .claude/hooks/enforce-spec.sh → exit 2, "[nana:enforce-spec] No approved spec for
  active phase." — enforcement is ARMED in the provisioned state, not
  registered-but-broken.
- DETECTOR-REHEARSAL: T3 fixture pair (exactly-once → SURFACED rc=0; duplicate →
  NOT-SURFACED rc=1) + real clone settings (context-size-check.sh count=0 →
  NOT-SURFACED rc=1, correct pre-arm).
- EXTRACTOR-SMOKE: extract-costs.py parsed the largest existing edge-screener transcript
  (per-step rows incl. wall/interrupts) — parser PASS; whether ARM transcripts persist
  is decided at T5/T6 (pty sessions persisted title-only in the T1 spike; A3 fallback
  pre-declared).
