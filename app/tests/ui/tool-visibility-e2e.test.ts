// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { reduceEngineEvents } from '../../src/ui/runtime';
import { toArtifacts } from '../../src/ui/artifact-feed';
import { surfaceToThreadMessage } from '../../src/ui/chat-binding';
import { mapPiStreamEvent } from '../../src/engine/pi/pi-adapter';
import type { EngineEvent } from '../../src/engine/types';

// Ph110 T8: the headline made machine-checkable end-to-end (mechanics only). One
// tool-call round-trip surfaces real args + streamed-then-final output + a typed
// artifact, stitching T1 (adapter mapping shape) → T2 (reduction) → T3 (binding)
// → T4 (streaming) → T5 (artifact routing). No live engine — the contract is the
// engine-neutral event stream every adapter emits.

const stream: EngineEvent[] = [
  { type: 'text-delta', delta: 'Running the build.' },
  { type: 'tool-call', call: { id: 'a', name: 'bash', args: { command: 'npm run build' } } },
  { type: 'tool-progress', id: 'a', partial: 'compiling…' },
  { type: 'tool-result', id: 'a', result: 'dist built in 1.0s', isError: false },
  { type: 'tool-call', call: { id: 'b', name: 'edit', args: { path: 'x.ts' } } },
  { type: 'tool-result', id: 'b', result: '--- a/x.ts\n+++ b/x.ts\n-old\n+new', isError: false },
  { type: 'done' },
];

describe('tool-call visibility end-to-end (Ph110 T8)', () => {
  it('surfaces real args + streamed-then-final output in the reduced message', () => {
    const msg = reduceEngineEvents(stream);
    const bash = msg.toolCalls.find((t) => t.id === 'a');
    expect(bash?.args).toEqual({ command: 'npm run build' });
    expect(bash?.output).toBe('dist built in 1.0s'); // the final result supersedes the partial
    expect(bash?.status).toBe('done');
  });

  it('the inline binding shows the real command + output (not name-only)', () => {
    const msg = reduceEngineEvents(stream);
    const tm = surfaceToThreadMessage(msg);
    const parts = tm.content as unknown as Array<{ type: string; argsText?: string; result?: unknown }>;
    const bash = parts.find((p) => p.type === 'tool-call' && p.argsText === 'npm run build');
    expect(bash).toBeDefined();
    expect(bash?.result).toBe('dist built in 1.0s');
  });

  it('the artifact feed routes the completed calls to typed views (bash→terminal, diff→diff)', () => {
    const arts = toArtifacts(reduceEngineEvents(stream).toolCalls);
    expect(arts.map((a) => `${a.name}:${a.kind}`)).toEqual(['bash:terminal', 'edit:diff']);
  });

  // The strong regression guard for review boundary-1: feed the REAL Pi event
  // shape (AgentToolResult wrapper objects, NOT strings) through the FULL
  // pipeline — adapter mapping → reduction → artifact routing — and assert the
  // user sees clean text, not a {"content":[…]} wrapper. Had this existed, the
  // 142 string-fixture tests would not have masked the live-engine breakage.
  it('full Pi path: AgentToolResult wrappers → adapter → reduction → clean text + typed artifact', () => {
    const piEvents = [
      { type: 'tool_execution_start', toolName: 'bash', toolCallId: 'a', args: { command: 'ls' } },
      {
        type: 'tool_execution_end',
        toolName: 'bash',
        toolCallId: 'a',
        result: { content: [{ type: 'text', text: 'a.txt\nb.txt' }], details: { exitCode: 0 } },
        isError: false,
      },
    ];
    const engineEvents = piEvents
      .map((e) => mapPiStreamEvent(e))
      .filter((e): e is EngineEvent => e !== null);
    const msg = reduceEngineEvents(engineEvents);
    const bash = msg.toolCalls.find((t) => t.id === 'a');
    expect(bash?.output).toBe('a.txt\nb.txt'); // real text, NOT a {content:[…]} object
    expect(toArtifacts(msg.toolCalls)).toEqual([
      { kind: 'terminal', id: 'a', name: 'bash', text: 'a.txt\nb.txt' },
    ]);
  });
});
