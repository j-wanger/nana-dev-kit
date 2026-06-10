# DRQ-1 — settings.json vs settings.local.json duplicate-hook merge semantics

Date: 2026-06-10. Method: real headless Claude Code sessions (`claude -p`, haiku) in a mktemp
sandbox project; firing counted by file-append side effects. Positive control in every run:
a hook registered exactly once must produce exactly one row (it did).

## Probes

1. **Identical command string in BOTH files** (settings.json + settings.local.json, same
   UserPromptSubmit command): `dup.log` = **1 row**; solo control = 1 row.
2. **Two DIFFERENT command strings invoking the same script** (`bash "$CLAUDE_PROJECT_DIR/..."`
   in settings.json vs `"$CLAUDE_PROJECT_DIR/..."` in settings.local.json): `p2.log` = **2 rows**.

verdict: dedupe

(Refined: dedupe is STRING-KEYED — identical command strings collapse to one firing across the
two files; distinct strings invoking the same script BOTH fire. Double-fire is therefore
conditional on form mismatch, not unconditional.)

## Implication for the edge-screener migration (A2 STOP-and-re-present satisfied)

- Edge-screener's hand-patch uses `${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh` — STRING-IDENTICAL
  to what register-settings.py writes project-locally (verified: register-settings.py:16,65).
  Left untouched, the post-install duplicates would dedupe (no immediate double-fire).
- The cleanup is still executed, as HYGIENE with a real failure mode behind it: duplicate
  registrations across two files mean any future form change (a register-settings.py path/prefix
  change) silently flips the pair from dedupe to double-fire. Single-source registration in
  settings.local.json removes the class.
- Risk model at checkpoint 2 is therefore CALMER than planned: the surgery is not racing an
  active double-fire; revert is a file restore.
