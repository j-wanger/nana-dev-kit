import { describe, it, expect } from 'vitest';
import { probeLocalEndpoint } from '../../src/engine/pi/pi-adapter';

// Phase 119 T4 — the launch-time local-endpoint capability probe. On the default
// local $0 backend, "nothing is happening" is almost always the endpoint being
// down; the probe surfaces that at launch so the header can warn. Never throws —
// a connection failure is a clean { ok: false }.

const okFetch = (models: string[]): typeof fetch =>
  (async () =>
    new Response(JSON.stringify({ data: models.map((id) => ({ id })) }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    })) as unknown as typeof fetch;

describe('probeLocalEndpoint', () => {
  it('reports ok + the model ids when the endpoint answers GET /models', async () => {
    const r = await probeLocalEndpoint('http://localhost:8080/v1', {
      fetchImpl: okFetch(['qwen-3.6', 'llama-4']),
    });
    expect(r.ok).toBe(true);
    expect(r.models).toEqual(['qwen-3.6', 'llama-4']);
    expect(r.detail).toBeUndefined();
  });

  it('normalizes a trailing slash on the base url', async () => {
    let calledUrl = '';
    const spy: typeof fetch = (async (url: string) => {
      calledUrl = url;
      return new Response(JSON.stringify({ data: [] }), { status: 200 });
    }) as unknown as typeof fetch;
    await probeLocalEndpoint('http://localhost:8080/v1/', { fetchImpl: spy });
    expect(calledUrl).toBe('http://localhost:8080/v1/models');
  });

  it('reports NOT ok with a detail when the endpoint is unreachable (never throws)', async () => {
    const downFetch: typeof fetch = (async () => {
      throw new Error('ECONNREFUSED');
    }) as unknown as typeof fetch;
    const r = await probeLocalEndpoint('http://localhost:8080/v1', { fetchImpl: downFetch });
    expect(r.ok).toBe(false);
    expect(r.models).toEqual([]);
    expect(r.detail).toMatch(/unreachable/i);
  });

  it('reports NOT ok on a non-200 response', async () => {
    const badFetch: typeof fetch = (async () =>
      new Response('nope', { status: 503 })) as unknown as typeof fetch;
    const r = await probeLocalEndpoint('http://localhost:8080/v1', { fetchImpl: badFetch });
    expect(r.ok).toBe(false);
    expect(r.detail).toMatch(/HTTP 503/);
  });
});
