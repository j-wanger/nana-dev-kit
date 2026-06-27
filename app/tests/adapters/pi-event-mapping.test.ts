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

// Ph111 T1 — typed `details` → a normalized engine-neutral {diff}. Pi's
// AgentToolResult wrapper carries a per-tool typed `details`; for the edit tool
// that is EditToolDetails = { diff: string; patch: string; firstChangedLine?: number }
// (pi edit.d.ts:18-25). The adapter NORMALIZES it to a whitelisted {diff?: string}
// (A3 — no Pi EditToolDetails type crosses the boundary; the UI's mapToArtifact
// still owns the VIEW-kind decision, A4). The diff is untrusted model-adjacent
// content → redact-then-cap at the boundary, same rail as the text result.
describe('mapPiStreamEvent — typed details → normalized {diff} (Ph111 T1)', () => {
  it('extracts EditToolDetails.diff into a normalized {diff} (the typed path)', () => {
    const diff = '--- a/file.txt\n+++ b/file.txt\n@@ -1,1 +1,1 @@\n-old line\n+new line';
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e1',
      result: {
        content: [{ type: 'text', text: 'Edited file.txt' }],
        details: { diff, patch: 'unified-patch-form', firstChangedLine: 1 },
      },
      isError: false,
    }) as ToolResult;
    expect(ev.details).toEqual({ diff });
    // The text summary is unchanged (additive — details rides alongside result).
    expect(ev.result).toBe('Edited file.txt');
  });

  it('omits details when the wrapper has a non-diff details (bash exitCode) — falls back cleanly', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 'b1',
      result: { content: [{ type: 'text', text: 'ok' }], details: { exitCode: 0 } },
      isError: false,
    }) as ToolResult;
    expect(ev.details).toBeUndefined();
  });

  it('omits details for a plain string result (no wrapper)', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 'b2',
      result: 'plain string output',
      isError: false,
    }) as ToolResult;
    expect(ev.details).toBeUndefined();
  });

  it('redacts a secret inside the diff (untrusted model-adjacent content)', () => {
    const diff = '--- a/.env\n+++ b/.env\n@@ -1 +1 @@\n-OLD\n+AKIAIOSFODNN7EXAMPLE';
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e2',
      result: {
        content: [{ type: 'text', text: 'edited' }],
        details: { diff, patch: '', firstChangedLine: 1 },
      },
      isError: false,
    }) as ToolResult;
    expect(ev.details?.diff).not.toContain('AKIAIOSFODNN7EXAMPLE');
    expect(ev.details?.diff).toContain('«redacted»');
  });

  it('caps an oversized diff at the adapter boundary', () => {
    const diff = '+building module '.repeat(2000); // ~34KB, no long token run → truncated not redacted
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e3',
      result: {
        content: [{ type: 'text', text: 'edited' }],
        details: { diff, patch: '', firstChangedLine: 1 },
      },
      isError: false,
    }) as ToolResult;
    expect((ev.details?.diff ?? '').length).toBeLessThan(diff.length);
    expect(ev.details?.diff).toMatch(/truncated/i);
  });

  it('omits details when details.diff is present but empty (no-op edit)', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e4',
      result: {
        content: [{ type: 'text', text: 'no-op' }],
        details: { diff: '', patch: '', firstChangedLine: 0 },
      },
      isError: false,
    }) as ToolResult;
    expect(ev.details).toBeUndefined();
  });
});
