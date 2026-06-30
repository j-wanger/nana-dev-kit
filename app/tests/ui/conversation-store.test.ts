// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  redactForPersist,
  saveConversation,
  loadConversation,
  clearConversation,
  MAX_MESSAGES,
} from '../../src/ui/conversation-store';
import type { UiMessage } from '../../src/ui/chat-binding';

// Phase 115, T1 — the structured redactor at the persistence boundary. The
// in-memory store holds RAW tool args (the adapter redacts output/diff, NOT
// args), so serializing it verbatim would write secrets to disk. redactForPersist
// must redact every string leaf, STRIP the write `content` body, and finalize a
// mid-stream turn so a restored thread never shows a perpetual "running" bubble.

// sk- prefix (>=16 chars) and AKIA… are shapes redactSecrets catches.
const SK = 'sk-ABCDEFGHIJKLMNOP1234567890';
const AWS = 'AKIAIOSFODNN7EXAMPLE';
type Assistant = Extract<UiMessage, { role: 'assistant' }>;

describe('redactForPersist (T1 — redaction at the persistence boundary)', () => {
  it('redacts a secret in user text, keeping surrounding prose', () => {
    const out = redactForPersist({ role: 'user', text: `my key is ${SK}` }) as { role: 'user'; text: string };
    expect(out.role).toBe('user');
    expect(out.text).not.toContain(SK);
    expect(out.text).toContain('my key is');
  });

  it('redacts secrets in assistant text AND the turn error', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: `here: ${SK}`,
      toolCalls: [],
      done: true,
      error: `boom ${AWS}`,
    }) as Assistant;
    expect(out.text).not.toContain(SK);
    expect(out.error).toBeDefined();
    expect(out.error).not.toContain(AWS);
  });

  it('STRIPS the write tool `content` body to a byte marker, keeping the path', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: true,
      toolCalls: [
        {
          id: 'w1',
          name: 'write',
          status: 'done',
          // a plaintext password redactSecrets would MISS — only the strip removes it
          args: { path: 'secrets.env', content: `PASSWORD=hunter2\nKEY=${SK}` },
        },
      ],
    }) as Assistant;
    const tc = out.toolCalls[0];
    expect(tc.args?.path).toBe('secrets.env');
    const content = String(tc.args?.content ?? '');
    expect(content).not.toContain('hunter2');
    expect(content).not.toContain(SK);
    expect(content).toMatch(/bytes/);
  });

  it('redacts a NESTED secret in tool output (output is unknown / an object)', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: true,
      toolCalls: [
        { id: 't1', name: 'read', status: 'done', output: { content: [{ type: 'text', text: `tok ${SK}` }] } },
      ],
    }) as Assistant;
    expect(JSON.stringify(out.toolCalls[0].output)).not.toContain(SK);
  });

  it('redacts a secret in a non-write arg (bash command) without stripping it', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: true,
      toolCalls: [{ id: 'b1', name: 'bash', status: 'done', args: { command: `curl -H "auth: ${SK}"` } }],
    }) as Assistant;
    const cmd = String(out.toolCalls[0].args?.command);
    expect(cmd).not.toContain(SK);
    expect(cmd).toContain('curl');
  });

  it('redacts details.diff', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: true,
      toolCalls: [{ id: 'e1', name: 'edit', status: 'done', details: { diff: `+ token = ${SK}` } }],
    }) as Assistant;
    expect(out.toolCalls[0].details?.diff).not.toContain(SK);
  });

  it('finalizes a mid-stream (done:false) turn so restore shows no perpetual "running"', () => {
    const out = redactForPersist({ role: 'assistant', text: 'partial', toolCalls: [], done: false }) as Assistant;
    expect(out.done).toBe(true);
  });

  it('finalizes a non-terminal tool status (called -> done) so a restored tool does not spin', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: false,
      toolCalls: [{ id: 'c1', name: 'bash', status: 'called', args: { command: 'sleep' } }],
    }) as Assistant;
    expect(out.toolCalls[0].status).toBe('done');
    expect(out.done).toBe(true);
  });

  it('preserves tool identity fields (id, name, status, isError)', () => {
    const out = redactForPersist({
      role: 'assistant',
      text: '',
      done: true,
      toolCalls: [{ id: 'x1', name: 'read', status: 'denied', reason: 'blocked by gate', isError: true }],
    }) as Assistant;
    const tc = out.toolCalls[0];
    expect(tc.id).toBe('x1');
    expect(tc.name).toBe('read');
    expect(tc.status).toBe('denied');
    expect(tc.isError).toBe(true);
  });

  it('does not mutate the input message', () => {
    const input: UiMessage = {
      role: 'assistant',
      text: `x ${SK}`,
      done: false,
      toolCalls: [{ id: 'm1', name: 'write', status: 'done', args: { path: 'p', content: 'body' } }],
    };
    redactForPersist(input);
    expect((input as Assistant).text).toContain(SK); // original untouched
    expect((input as Assistant).done).toBe(false);
    expect((input as Assistant).toolCalls[0].args?.content).toBe('body');
  });
});

// T2 — localStorage I/O keyed by workspace, bound/prune, fail-soft. These run
// under jsdom (file-level @vitest-environment above) where localStorage exists.

function turn(i: number): UiMessage[] {
  return [
    { role: 'user', text: `q${i}` },
    { role: 'assistant', text: `a${i}`, toolCalls: [], done: true },
  ];
}

describe('conversation-store I/O (T2 — persist keyed by workspace, fail-soft)', () => {
  beforeEach(() => localStorage.clear());

  it('round-trips a conversation (load == the redacted, persisted form)', () => {
    const msgs = [...turn(1), ...turn(2)];
    saveConversation('/ws/a', msgs);
    const expected = JSON.parse(JSON.stringify(msgs.map(redactForPersist)));
    expect(loadConversation('/ws/a')).toEqual(expected);
  });

  it('writes NO known secret to disk (the at-rest assertion)', () => {
    const msgs: UiMessage[] = [
      { role: 'user', text: `paste ${SK}` },
      {
        role: 'assistant',
        text: `echo ${AWS}`,
        done: true,
        error: `failed with ${SK}`,
        toolCalls: [
          { id: 'b1', name: 'bash', status: 'done', args: { command: `curl -H "auth: ${SK}"` }, output: `body ${AWS}` },
          { id: 'w1', name: 'write', status: 'done', args: { path: 'p.env', content: `SECRET=${SK}` } },
        ],
      },
    ];
    saveConversation('/ws/a', msgs);
    // Inspect the RAW stored string across every key — nothing leaks.
    const raw = Object.keys(localStorage)
      .map((k) => localStorage.getItem(k) ?? '')
      .join('\n');
    expect(raw).not.toContain(SK);
    expect(raw).not.toContain(AWS);
    expect(raw.length).toBeGreaterThan(0); // it DID persist (not an empty no-op)
  });

  it('keys per-workspace — workspace A and B do not cross-leak', () => {
    saveConversation('/ws/a', turn(1));
    saveConversation('/ws/b', turn(99));
    expect(loadConversation('/ws/a')).toEqual(JSON.parse(JSON.stringify(turn(1).map(redactForPersist))));
    expect(loadConversation('/ws/b')).toEqual(JSON.parse(JSON.stringify(turn(99).map(redactForPersist))));
    expect(JSON.stringify(loadConversation('/ws/a'))).not.toContain('a99');
  });

  it('bounds the thread to MAX_MESSAGES, keeping the NEWEST', () => {
    const many: UiMessage[] = [];
    for (let i = 0; i < MAX_MESSAGES + 10; i++) many.push({ role: 'user', text: `m${i}` });
    saveConversation('/ws/a', many);
    const loaded = loadConversation('/ws/a');
    expect(loaded.length).toBe(MAX_MESSAGES);
    // newest preserved, oldest dropped
    expect((loaded[loaded.length - 1] as { text: string }).text).toBe(`m${MAX_MESSAGES + 9}`);
    expect(JSON.stringify(loaded)).not.toContain('"m0"');
  });

  it('never throws on a QuotaExceededError (prune-retry then skip)', () => {
    const spy = vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota', 'QuotaExceededError');
    });
    expect(() => saveConversation('/ws/a', [...turn(1), ...turn(2)])).not.toThrow();
    spy.mockRestore();
  });

  it('returns [] for a missing key', () => {
    expect(loadConversation('/ws/none')).toEqual([]);
  });

  it('returns [] for corrupt JSON (fail-soft)', () => {
    localStorage.setItem('nana.conv.v1:/ws/a', 'not json{');
    expect(loadConversation('/ws/a')).toEqual([]);
  });

  it('returns [] for valid JSON of the wrong shape (shape guard)', () => {
    localStorage.setItem('nana.conv.v1:/ws/a', JSON.stringify([{ role: 'bogus' }, { nope: 1 }]));
    expect(loadConversation('/ws/a')).toEqual([]);
    localStorage.setItem('nana.conv.v1:/ws/b', JSON.stringify({ not: 'an array' }));
    expect(loadConversation('/ws/b')).toEqual([]);
    // an assistant message missing its toolCalls array is rejected (would crash chat-binding)
    localStorage.setItem('nana.conv.v1:/ws/c', JSON.stringify([{ role: 'assistant', text: 'x' }]));
    expect(loadConversation('/ws/c')).toEqual([]);
  });

  it('clear removes the persisted entry for a key', () => {
    saveConversation('/ws/a', turn(1));
    clearConversation('/ws/a');
    expect(loadConversation('/ws/a')).toEqual([]);
  });

  it('never prunes a non-empty thread to [] when one message exceeds the byte cap', () => {
    // ~360KB of short words+spaces: survives redaction (no 32+ char run), exceeds MAX_BYTES.
    const big = 'lorem ipsum dolor '.repeat(20000);
    saveConversation('/ws/a', turn(1));
    expect(loadConversation('/ws/a').length).toBe(2);
    saveConversation('/ws/a', [...turn(1), { role: 'assistant', text: big, toolCalls: [], done: true }]);
    // backstop keeps the newest message rather than overwriting history with "[]"
    expect(loadConversation('/ws/a').length).toBeGreaterThanOrEqual(1);
  });

  it('skips the write (preserves the prior thread) when setItem keeps throwing (quota)', () => {
    saveConversation('/ws/a', turn(1)); // prior good 2-message thread (real setItem)
    const spy = vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota', 'QuotaExceededError');
    });
    saveConversation('/ws/a', [...turn(1), ...turn(2)]); // every setItem throws -> skip, do not clobber
    spy.mockRestore();
    expect(loadConversation('/ws/a').length).toBe(2); // prior thread intact (not [] / not overwritten)
  });

  it('rejects a thread whose toolCalls contains a non-object element (tamper guard)', () => {
    localStorage.setItem('nana.conv.v1:/ws/a', JSON.stringify([{ role: 'assistant', text: 'x', toolCalls: [null] }]));
    expect(loadConversation('/ws/a')).toEqual([]);
  });
});
