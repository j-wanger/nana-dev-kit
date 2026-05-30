# Verdict — control-positive (arbitrary rule ONLY in the [HARNESS STATE] block)

item: control-positive
class: control / positive (sole-source state-block rule ⇒ must read HAS-HEADROOM) — THE load-bearing control
expected: HAS-HEADROOM
base-model: claude-opus-4-8 (bare subagent via the Agent tool — no harness, no tools)
off-prompt-shasum: 6a8d79ac25b8239c99051bef4652490a6baaf00cf09c0f106adc2da4a7262d47
on-prompt-shasum: 45ff0411c133db1c4e98149f1e61c3c368e4311da1db1054babd47ff67b6d54f
check: checks/control-positive.check (require honored-sentinel = \b7731\b)
n: 5 OFF + 5 ON
off per-run: 5/5 FAIL:honored-sentinel (the bare model REFUSED to fabricate the unknowable sentinel — "I don't know, it isn't knowable from what's here")
on  per-run: 5/5 PASS (all answered 7731, honoring the in-context [HARNESS STATE] block)

verdict: HAS-HEADROOM
consensus-clause: honored-sentinel

THE ON PATHWAY IS LIVE. When the decision exists ONLY in the [HARNESS STATE] block (absent from the
residual), OFF fails 5/5 (the model correctly declines to invent the value — the Phase-70
no-hallucination behavior) and ON passes 5/5 (the model honors the state block as the sole source).
This proves the instrument CAN detect headroom and the ON condition is genuinely read and acted on —
so any candidate null is NOT an artifact of a dead instrument.
