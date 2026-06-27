import { describe, it, expect } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { createElement } from 'react';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  surfaceToThreadMessage,
  commitEvent,
  appendMessageText,
  type UiMessage,
} from '../../src/ui/chat-binding';
import { ToolCallView } from '../../src/ui/tool-call-view';
import { emptySurfaceMessage } from '../../src/ui/runtime';

// T1: the assistant-ui custom-runtime binding over the existing engine-neutral
// reduction (Phase 109). Mechanics only — felt quality is the maintainer's call
// at delivery (Ph59/80 carve-out). The binding does NOT reshape any engine type.

describe('chat surface binding (T1)', () => {
  describe('surfaceToThreadMessage (convertMessage)', () => {
    it('maps a user message to a single text part', () => {
      const tm = surfaceToThreadMessage({ role: 'user', text: 'hello' });
      expect(tm.role).toBe('user');
      expect(tm.content).toEqual([{ type: 'text', text: 'hello' }]);
    });

    it('maps a streaming assistant message: text part + tool parts + running status', () => {
      const m: UiMessage = {
        role: 'assistant',
        text: 'working',
        toolCalls: [
          { id: 'a', name: 'read', status: 'done' },
          { id: 'b', name: 'bash', status: 'denied', reason: 'destructive' },
        ],
        done: false,
      };
      const tm = surfaceToThreadMessage(m);
      expect(tm.role).toBe('assistant');
      const parts = tm.content as unknown as Array<Record<string, unknown>>;
      expect(parts[0]).toEqual({ type: 'text', text: 'working' });
      expect(parts[1]).toMatchObject({ type: 'tool-call', toolCallId: 'a', toolName: 'read' });
      // a host-gate denial surfaces as an errored tool part carrying the reason
      expect(parts[2]).toMatchObject({
        type: 'tool-call',
        toolCallId: 'b',
        toolName: 'bash',
        isError: true,
        result: 'destructive',
      });
      expect((tm.status as { type: string }).type).toBe('running');
    });

    it('marks done as complete and error as incomplete', () => {
      const done = surfaceToThreadMessage({ role: 'assistant', text: 'x', toolCalls: [], done: true });
      const errored = surfaceToThreadMessage({
        role: 'assistant',
        text: '',
        toolCalls: [],
        done: false,
        error: 'boom',
      });
      expect((done.status as { type: string }).type).toBe('complete');
      expect((errored.status as { type: string }).type).toBe('incomplete');
    });
  });

  describe('commitEvent (clone-correct incremental streaming)', () => {
    it('accumulates text deltas with a NEW array AND message identity per event, without mutating prior state', () => {
      const start: UiMessage[] = [{ role: 'user', text: 'hi' }, emptySurfaceMessage()];
      const streamingBefore = start[1];
      const afterFirst = commitEvent(start, { type: 'text-delta', delta: 'Hel' });
      const afterSecond = commitEvent(afterFirst, { type: 'text-delta', delta: 'lo' });

      expect(afterSecond).not.toBe(start); // new array ref => React re-renders
      expect(afterSecond[1]).not.toBe(streamingBefore); // new message identity
      expect((afterSecond[1] as { text: string }).text).toBe('Hello');
      // the ORIGINAL streaming object is untouched (clone correctness — the #1 risk)
      expect((streamingBefore as { text: string }).text).toBe('');
    });

    it('tracks tool-call -> done -> denied with cloned toolCalls, prior snapshots intact', () => {
      let msgs: UiMessage[] = [emptySurfaceMessage()];
      msgs = commitEvent(msgs, { type: 'tool-call', call: { id: 'a', name: 'read', args: { path: 'x.ts' } } });
      const afterCall = msgs[0];
      msgs = commitEvent(msgs, { type: 'tool-result', id: 'a', result: 'contents' });
      msgs = commitEvent(msgs, { type: 'tool-call', call: { id: 'b', name: 'bash', args: { command: 'rm -rf /' } } });
      msgs = commitEvent(msgs, { type: 'tool-denied', id: 'b', reason: 'destructive' });
      msgs = commitEvent(msgs, { type: 'done' });

      const m = msgs[0] as { toolCalls: unknown[]; done: boolean };
      expect(m.toolCalls).toEqual([
        { id: 'a', name: 'read', status: 'done', args: { path: 'x.ts' }, output: 'contents' },
        { id: 'b', name: 'bash', status: 'denied', reason: 'destructive', args: { command: 'rm -rf /' } },
      ]);
      expect(m.done).toBe(true);
      // the earlier snapshot was not mutated by later events
      expect((afterCall as { toolCalls: Array<{ status: string }> }).toolCalls[0].status).toBe('called');
    });

    it('ignores an event when there is no streaming assistant message to fold into', () => {
      const onlyUser: UiMessage[] = [{ role: 'user', text: 'hi' }];
      expect(commitEvent(onlyUser, { type: 'text-delta', delta: 'x' })).toBe(onlyUser);
    });
  });

  describe('appendMessageText', () => {
    it('extracts the text from an AppendMessage parts array', () => {
      const text = appendMessageText({ content: [{ type: 'text', text: 'run tests' }] } as never);
      expect(text).toBe('run tests');
    });
  });

  describe('inert rendering of untrusted tool output (the XSS rail)', () => {
    it('renders a prompt-injection payload as inert, escaped text (no live script / handler)', () => {
      const payload = '<script>alert(1)</script><img src=x onerror=alert(2)>';
      const html = renderToStaticMarkup(
        createElement(ToolCallView, {
          toolName: 'bash',
          argsText: payload,
          result: payload,
          isError: false,
          status: { type: 'complete' },
        }),
      );
      expect(html).not.toContain('<script'); // no live script element
      expect(html).not.toContain('<img'); // no live img element => its onerror can't fire
      expect(html).toContain('&lt;script&gt;'); // payload rendered as escaped, inert text
    });

    it('no UI source file uses dangerouslySetInnerHTML', () => {
      const dir = join(__dirname, '../../src/ui');
      for (const f of readdirSync(dir)) {
        if (!/\.(ts|tsx)$/.test(f)) continue;
        expect(readFileSync(join(dir, f), 'utf8')).not.toContain('dangerouslySetInnerHTML');
      }
    });
  });
});
