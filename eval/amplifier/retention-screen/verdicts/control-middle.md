# Verdict — control-middle (borderline: HTTP 204 vs 200 for a successful DELETE)

item: control-middle
class: control / middle (borderline ⇒ must NOT false-positive HAS-HEADROOM in either batch)
expected: STABLE (neither independent n=5 batch reads HAS-HEADROOM)
base-model: claude-opus-4-8 (bare subagent via the Agent tool — no harness, no tools)
off-prompt-shasum: c268cb2490ac8f281280a5913e1f020ac800c99e31be125e3c7e82c4b1799775
check: checks/control-middle.check (require honored-204 = \b204\b)
n: 5 OFF per batch × 2 independent batches (b1, b2)
b1: DEGENERATE   b2: DEGENERATE

stability: STABLE

The borderline control does NOT false-positive. Both batches read DEGENERATE (every run references 204 —
some committing to it as the REST convention, some flagging that the specific code was lost to compaction
yet still citing 204). Neither batch reads HAS-HEADROOM, so the screen does not spuriously claim headroom
on a non-headroom decision — the costliest (false-continue) error is guarded. `check.sh --stability DEGENERATE DEGENERATE` ⇒ stability: STABLE.
