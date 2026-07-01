// Enforced spend ceiling (Phase 108, T8). Cost is computed from each provider's
// real price table; at the ceiling the harness HARD-PAUSES for confirmation —
// an enforced block, not a displayed number. Local/free models have a $0 price
// table entry, so they never trip it.

export class SpendCeilingExceededError extends Error {
  constructor(spentUsd: number, ceilingUsd: number) {
    super(`spend ceiling reached: $${spentUsd.toFixed(4)} >= $${ceilingUsd.toFixed(4)} — confirmation required`);
    this.name = 'SpendCeilingExceededError';
  }
}

/** Price per MILLION tokens, keyed by "provider/model". */
export interface ModelPrice {
  input: number;
  output: number;
}
export type PriceTable = Record<string, ModelPrice>;

export interface SpendStatus {
  paused: boolean;
  spentUsd: number;
  ceilingUsd: number;
}

export class SpendCeiling {
  private spent = 0;

  constructor(
    private readonly ceilingUsd: number,
    private readonly prices: PriceTable,
  ) {}

  /** Record token usage for a call; accumulates real dollar cost. */
  record(providerModel: string, inputTokens: number, outputTokens: number): void {
    const price = this.prices[providerModel] ?? { input: 0, output: 0 };
    this.spent += (inputTokens / 1e6) * price.input + (outputTokens / 1e6) * price.output;
  }

  /**
   * Phase 119 T2 — reconcile against an AUTHORITATIVE cumulative cost the engine
   * already computed (Pi's `getSessionStats().cost`), rather than re-deriving it
   * from a second price table. Monotonic (never lowers `spent`), so a late/lower
   * reading can't un-pause a ceiling that was already tripped. This is how the
   * host wires the meter feed into the ceiling — local is $0, so it never trips.
   */
  noteCumulativeCost(spentUsd: number): void {
    if (Number.isFinite(spentUsd) && spentUsd > this.spent) this.spent = spentUsd;
  }

  get spentUsd(): number {
    return this.spent;
  }

  exceeded(): boolean {
    return this.spent >= this.ceilingUsd;
  }

  status(): SpendStatus {
    return { paused: this.exceeded(), spentUsd: this.spent, ceilingUsd: this.ceilingUsd };
  }

  /**
   * The hard pause. The harness calls this before each model/tool call; if the
   * ceiling is reached it THROWS, blocking further spend until the maintainer
   * confirms (which raises the ceiling). This is what makes the ceiling enforced
   * rather than advisory.
   */
  guardSpend(): void {
    if (this.exceeded()) throw new SpendCeilingExceededError(this.spent, this.ceilingUsd);
  }
}
