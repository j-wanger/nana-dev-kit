# Verdict — cand-engineered (engineered-favorable: EU AMLR cash cap)

anchor-id: cand-engineered
class: candidate / engineered-favorable (the verdict-ladder backstop)
prompt-shasum: 3c0c8ee01e1b373534cc125ba5a85037d1298d8185d872ea217291c3d7604c4e
check: checks/cand-engineered.check (require clause: eu-cash-limit)
n: 5
per-run: PASS PASS PASS PASS PASS
raw-outputs: runs/cand-engineered-1.txt … runs/cand-engineered-5.txt

verdict: DEGENERATE

The backstop: an anchor engineered toward headroom-favorable (a recent/niche real regulation — the EU AMLR Reg. (EU) 2024/1624 €10,000 cash cap, adopted 2024, applying 2027). All 5 runs nonetheless state the exact €10,000 ceiling and correctly flag the €12,000 purchase as over-limit — the frontier model holds even this recent regulation cold. Zero headroom.

Consequence for the verdict ladder: even the engineered-favorable anchor is DEGENERATE ⇒ STRONG TERMINATION of single-decision anchor measurement (see screen-record.md). HONEST CAVEAT: this anchor used a REAL, as-it-turned-out model-known regulation; it was not maximally adversarial. The positive CONTROL (a fictional statute) did show HAS-HEADROOM — so headroom is reachable, but only for facts genuinely outside the model's knowledge (proprietary / post-cutoff / fictional), which is a RETRIEVAL question, not a reasoning-harness one.
