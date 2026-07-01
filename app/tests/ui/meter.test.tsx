// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { createElement } from 'react';
import { projectMeter, MeterBar, type MeterUsage } from '../../src/ui/meter';

// Phase 119 T2 — the context/cost meter. The load-bearing case: Pi reports
// percent/tokens as null in the post-compaction window (before the next LLM
// response). The meter must render that WITHOUT "NaN%" or "null" — a projection
// helper owns the null-safety so it is testable without a DOM.

describe('projectMeter — display projection incl. the percent:null window', () => {
  it('projects real usage to labels + a clamped fraction', () => {
    const v = projectMeter({ percent: 42.6, tokens: 12_345, contextWindow: 262_144, costUsd: 1.5 });
    expect(v.percentLabel).toBe('43%');
    expect(v.fraction).toBeCloseTo(0.426, 3);
    expect(v.contextLabel).toBe('12.3k / 262k');
    expect(v.costLabel).toBe('$1.50');
    expect(v.hasData).toBe(true);
  });

  it('renders the post-compaction null window as "—", never NaN%/null', () => {
    const v = projectMeter({ percent: null, tokens: null, contextWindow: 262_144, costUsd: 0 });
    expect(v.percentLabel).toBe('—');
    expect(v.fraction).toBe(0); // no bogus width
    expect(v.contextLabel).toBe('—');
    expect(v.costLabel).toBe('$0.00'); // $0 on local, accepted
    expect(v.percentLabel).not.toMatch(/nan/i);
    expect(v.contextLabel).not.toMatch(/null|nan/i);
  });

  it('clamps an out-of-range percent and formats small/large token counts', () => {
    expect(projectMeter({ percent: 150, tokens: 900, contextWindow: 1_000, costUsd: 0 }).fraction).toBe(1);
    expect(projectMeter({ percent: -5, tokens: 900, contextWindow: 1_000, costUsd: 0 }).fraction).toBe(0);
    expect(projectMeter({ percent: 1, tokens: 900, contextWindow: 8_000, costUsd: 0 }).contextLabel).toBe('900 / 8.0k');
  });
});

describe('MeterBar — renders without NaN, handles null usage', () => {
  const render = (usage: MeterUsage | null) => renderToStaticMarkup(createElement(MeterBar, { usage }));

  it('renders a muted placeholder before the first reading (usage=null)', () => {
    const html = render(null);
    expect(html).toContain('data-testid="meter"');
    expect(html).toContain('$0.00');
    expect(html).not.toMatch(/nan/i);
  });

  it('renders the percent + cost, and the null window without NaN%', () => {
    const withValue = render({ percent: 37, tokens: 5000, contextWindow: 262_144, costUsd: 0 });
    expect(withValue).toContain('37%');
    expect(withValue).not.toMatch(/nan/i);

    const nullWindow = render({ percent: null, tokens: null, contextWindow: 262_144, costUsd: 0 });
    expect(nullWindow).toContain('—');
    expect(nullWindow).not.toMatch(/nan|null/i);
  });
});
