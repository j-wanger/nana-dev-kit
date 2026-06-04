# Cross-Session Residual Audit (Phase 77 — T1/T2 gate)

- subject: `/Users/jwang/edge-screener`
- channels: tree,gitmsg  (OFF corpus = code + tests + git commit MESSAGES; `git log -p` excluded)
- generated: 2026-06-04T13:17:42Z
- floor: 3 distinct residual decisions

## Per-decision provenance

| slug | kind | discriminating token | classification |
|---|---|---|---|
| backtest-return-space-engine-v1 | fact | `multiplicat` | RECOVERABLE:tree |
| benchmark-spy-tr-proxy | fact | `SPY` | RECOVERABLE:tree |
| closeout-hardening-v1 | process | `robustness_golden` | RECOVERABLE:tree |
| data-price-model-pit-adjustment | fact | `SPLIT_ONLY` | RECOVERABLE:tree |
| dsr-active-basis-v1 | fact | `dsr_basis` | RECOVERABLE:tree |
| incremental-walkforward-v1 | fact | `prefix` | RECOVERABLE:tree |
| multiple-testing-correction-v1 | fact | `effective_trials` | RECOVERABLE:tree |
| null-robustness-battery-v1 | fact | `frictionless` | RECOVERABLE:tree |
| oos-edge-measurement-harness-v1 | fact | `walkforward` | RECOVERABLE:tree |
| reproducible-closeout-cli-v1 | fact | `reproduce` | RECOVERABLE:tree |
| signal-undefined-error-contract-v1 | fact | `SignalUndefinedError` | RECOVERABLE:tree |
| stooq-deferred-yfinance-only-v1 | negative | `Stooq` | RECOVERABLE:tree |
| survivorship-pit-membership-v1 | fact | `Shumway` | RECOVERABLE:tree |
| universe-v1-current-sp500 | fact | `constituent` | RECOVERABLE:tree |

## Summary

recoverable: 14   excluded: 0   **RESIDUAL-COUNT: 0**

GATE: HALT-TERMINATE  (residual 0 → PROGRAM-VERDICT TERMINATE; no OFF/ON run)
