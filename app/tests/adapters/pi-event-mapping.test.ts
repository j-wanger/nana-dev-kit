import { describe, it, expect } from 'vitest';
import { mapPiStreamEvent } from '../../src/engine/pi/pi-adapter';
import type { EngineEvent } from '../../src/engine/types';

// Ph110 T1 (the #1 dogfood gap). Pi ALREADY carries the real tool args + output
// on its event stream — ToolExecutionStartEvent.args and ToolExecutionEndEvent
// .result (node_modules/@earendil-works/pi-coding-agent .../types.d.ts:549-570).
// The Ph108 adapter discarded them (args:{} / result:{isError}); this pins that
// the pure mapping seam the subscribe handler delegates to forwards the REAL
// payload instead. `result` stays the raw output (consistent with the Vercel +
// noop adapters); an execution error rides the additive optional `isError`.

type ToolResult = Extract<EngineEvent, { type: 'tool-result' }>;

describe('mapPiStreamEvent — forwards real Pi tool args + output (Ph110 T1)', () => {
  it('tool_execution_start forwards the REAL args (not {})', () => {
    expect(
      mapPiStreamEvent({
        type: 'tool_execution_start',
        toolName: 'bash',
        toolCallId: 't1',
        args: { command: 'ls -la /tmp' },
      }),
    ).toEqual({
      type: 'tool-call',
      call: { id: 't1', name: 'bash', args: { command: 'ls -la /tmp' } },
    });
  });

  it('tool_execution_end forwards the REAL output + isError (not just {isError})', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 't1',
      result: 'total 0\ndrwxr-xr-x  2 user  staff  64 Jun 27 .',
      isError: false,
    }) as ToolResult;
    expect(ev.type).toBe('tool-result');
    expect(ev.id).toBe('t1');
    expect(ev.result).toContain('total 0');
    expect(ev.isError).toBe(false);
  });

  it('marks an errored tool result (isError true) without losing its output', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 't2',
      result: 'bash: nope: command not found',
      isError: true,
    }) as ToolResult;
    expect(ev.isError).toBe(true);
    expect(ev.result).toContain('command not found');
  });

  it('tool_execution_update maps to a tool-progress with the partial output (Ph110 T4)', () => {
    expect(
      mapPiStreamEvent({
        type: 'tool_execution_update',
        toolName: 'bash',
        toolCallId: 't1',
        args: { command: 'long-build' },
        partialResult: 'compiling… 80%',
      }),
    ).toEqual({ type: 'tool-progress', id: 't1', partial: 'compiling… 80%' });
  });

  it('message_update text_delta maps to a text-delta', () => {
    expect(
      mapPiStreamEvent({
        type: 'message_update',
        assistantMessageEvent: { type: 'text_delta', delta: 'hi' },
      }),
    ).toEqual({ type: 'text-delta', delta: 'hi' });
  });

  // Review boundary-1: Pi's real tool_execution_end.result / tool_execution_update
  // .partialResult are AgentToolResult WRAPPERS ({content:[{type:'text',text}],
  // details}), NOT strings — the adapter must extract the text content, else the
  // surface renders JSON noise and the 16KB cap never fires.
  it('extracts text content from a Pi AgentToolResult wrapper, not the raw {content,details} object (boundary-1)', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 't1',
      result: { content: [{ type: 'text', text: 'total 0\nfile.txt' }], details: { exitCode: 0 } },
      isError: false,
    }) as ToolResult;
    expect(ev.result).toBe('total 0\nfile.txt');
    expect(ev.isError).toBe(false);
  });

  it('maps a wrapper partialResult to a tool-progress with its text (boundary-1)', () => {
    expect(
      mapPiStreamEvent({
        type: 'tool_execution_update',
        toolName: 'bash',
        toolCallId: 't1',
        args: { command: 'x' },
        partialResult: { content: [{ type: 'text', text: 'compiling… 80%' }] },
      }),
    ).toEqual({ type: 'tool-progress', id: 't1', partial: 'compiling… 80%' });
  });

  it('caps an oversized wrapper result — the 16KB cap now fires for real Pi results (boundary-1)', () => {
    const huge = 'building module '.repeat(2000); // ~32KB, no 32-char token run → truncated, not redacted
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'read',
      toolCallId: 't3',
      result: { content: [{ type: 'text', text: huge }], details: {} },
      isError: false,
    }) as ToolResult;
    const out = ev.result as string;
    expect(out.length).toBeLessThan(huge.length);
    expect(out).toMatch(/truncated/i);
  });

  it('redacts a secret in tool output at the adapter boundary, before the line protocol (security-2)', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 't1',
      result: { content: [{ type: 'text', text: 'key=AKIAIOSFODNN7EXAMPLE leaked' }] },
      isError: false,
    }) as ToolResult;
    expect(ev.result).not.toContain('AKIAIOSFODNN7EXAMPLE');
    expect(ev.result).toContain('«redacted»');
  });

  it('ignores unmapped event types (returns null → skipped)', () => {
    expect(mapPiStreamEvent({ type: 'session_start' })).toBeNull();
    expect(
      mapPiStreamEvent({
        type: 'message_update',
        assistantMessageEvent: { type: 'reasoning_delta' },
      }),
    ).toBeNull();
  });
});
