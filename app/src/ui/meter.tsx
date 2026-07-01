// Phase 119 T2 — the context/cost meter. Every Pi power-user's #1 felt-quality
// lesson is "watch your context window (= answer quality) and your spend (= money)."
// The engine emits an additive `context-usage` event at each turn end; this bottom
// bar renders it. Two pieces: a PURE projection helper (node-testable, the single
// meter-projection seam) and a thin presentational component.

/** The engine-neutral usage the meter renders (mirrors the `context-usage` event). */
export interface MeterUsage {
  percent: number | null;
  tokens: number | null;
  contextWindow: number;
  costUsd: number;
}

/** Display-ready meter strings. Kept separate from the component so the null-safety
 *  (no `NaN%`, no `null/…`) is unit-tested without a DOM. */
export interface MeterView {
  /** "42%" or "—" when percent is null (the post-compaction window). */
  percentLabel: string;
  /** Fraction for a progress bar width in [0,1]; 0 when percent is unknown. */
  fraction: number;
  /** "12.3k / 262k" tokens, or "—" when tokens is null. */
  contextLabel: string;
  /** Always "$0.00"-shaped (2dp); $0.00 on the local model, accepted. */
  costLabel: string;
  /** True once we have any real usage/cost to show (else the meter can stay muted). */
  hasData: boolean;
}

/** Compact a token count for the bar: 262144 → "262k", 12345 → "12.3k", 900 → "900". */
function fmtTokens(n: number): string {
  if (!Number.isFinite(n) || n < 0) return '—';
  if (n < 1000) return String(Math.round(n));
  const k = n / 1000;
  return `${k < 100 ? k.toFixed(1) : Math.round(k)}k`;
}

/**
 * Project raw usage to display strings. The load-bearing case: `percent`/`tokens`
 * are null right after a compaction (before the next LLM response) — render "—",
 * never "NaN%" or "null". `contextWindow` 0 (no session yet) also renders "—".
 */
export function projectMeter(u: MeterUsage): MeterView {
  const pctKnown = typeof u.percent === 'number' && Number.isFinite(u.percent);
  const percentLabel = pctKnown ? `${Math.round(u.percent as number)}%` : '—';
  const fraction = pctKnown ? Math.max(0, Math.min(1, (u.percent as number) / 100)) : 0;

  const tokKnown = typeof u.tokens === 'number' && Number.isFinite(u.tokens);
  const winKnown = Number.isFinite(u.contextWindow) && u.contextWindow > 0;
  const contextLabel =
    tokKnown && winKnown ? `${fmtTokens(u.tokens as number)} / ${fmtTokens(u.contextWindow)}` : '—';

  const cost = Number.isFinite(u.costUsd) ? u.costUsd : 0;
  const costLabel = `$${cost.toFixed(2)}`;

  return {
    percentLabel,
    fraction,
    contextLabel,
    costLabel,
    hasData: pctKnown || tokKnown || cost > 0,
  };
}

/**
 * The bottom-bar meter. `usage` null (before the first turn end) renders a muted
 * placeholder. Presentational + inert — no engine access, no callbacks.
 */
export function MeterBar({ usage }: { usage: MeterUsage | null }): JSX.Element {
  const view = usage ? projectMeter(usage) : null;
  return (
    <div className="meter" data-testid="meter" role="status" aria-label="context and cost">
      <div className="meter__context" title="Context window used">
        <div className="meter__bar" aria-hidden="true">
          <div className="meter__fill" style={{ width: `${(view?.fraction ?? 0) * 100}%` }} />
        </div>
        <span className="meter__pct" data-testid="meter-pct">
          {view ? view.percentLabel : '—'}
        </span>
        <span className="meter__tokens">{view ? view.contextLabel : '—'}</span>
      </div>
      <span className="meter__cost" data-testid="meter-cost" title="Session cost">
        {view ? view.costLabel : '$0.00'}
      </span>
    </div>
  );
}
