import { describe, it, expect } from 'vitest';
import { mapPiStreamEvent } from '../../src/engine/pi/pi-adapter';
import { reduceEngineEvents } from '../../src/ui/runtime';
import { toArtifacts } from '../../src/ui/artifact-feed';
import type { EngineEvent } from '../../src/engine/types';

// Ph111 T5 — deterministic end-to-end: a REAL Pi edit event shape flows
// source→surface (adapter map → reduction → artifact router) and yields a
// STRUCTURED diff artifact, with NO live model. Mirrors the AgentToolResult
// wrapper shape (EditToolDetails on .details) the T1 live spike confirmed.

describe('Ph111 T5 — typed-diff pipeline end-to-end (deterministic)', () => {
  it('a Pi edit (real wrapper shape) renders a structured diff artifact source→surface', () => {
    const diff = '-1 hello world\n+1 goodbye world\n 2 second line'; // Pi's real format
    const start = mapPiStreamEvent({
      type: 'tool_execution_start',
      toolName: 'edit',
      toolCallId: 'e1',
      args: { path: 'greeting.txt' },
    })!;
    const end = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e1',
      result: {
        content: [{ type: 'text', text: 'Edited greeting.txt' }],
        details: { diff, patch: 'unified', firstChangedLine: 1 },
      },
      isError: false,
    })!;
    const msg = reduceEngineEvents([start, end, { type: 'done' } as EngineEvent]);
    expect(toArtifacts(msg.toolCalls)).toEqual([{ kind: 'diff', id: 'e1', name: 'edit', diff }]);
  });

  it('a Pi bash (no typed details) renders a terminal artifact, not a fake diff', () => {
    const start = mapPiStreamEvent({
      type: 'tool_execution_start',
      toolName: 'bash',
      toolCallId: 'b1',
      args: { command: 'ls' },
    })!;
    const end = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'bash',
      toolCallId: 'b1',
      result: { content: [{ type: 'text', text: 'a.txt\nb.txt' }], details: { exitCode: 0 } },
      isError: false,
    })!;
    const msg = reduceEngineEvents([start, end, { type: 'done' } as EngineEvent]);
    expect(toArtifacts(msg.toolCalls)).toEqual([
      { kind: 'terminal', id: 'b1', name: 'bash', text: 'a.txt\nb.txt' },
    ]);
  });

  it('a secret in the edit diff is redacted by the time it reaches the artifact', () => {
    const start = mapPiStreamEvent({
      type: 'tool_execution_start',
      toolName: 'edit',
      toolCallId: 'e2',
      args: { path: '.env' },
    })!;
    const end = mapPiStreamEvent({
      type: 'tool_execution_end',
      toolName: 'edit',
      toolCallId: 'e2',
      result: {
        content: [{ type: 'text', text: 'edited .env' }],
        details: { diff: '-1 OLD\n+1 AKIAIOSFODNN7EXAMPLE', patch: '', firstChangedLine: 1 },
      },
      isError: false,
    })!;
    const msg = reduceEngineEvents([start, end, { type: 'done' } as EngineEvent]);
    const json = JSON.stringify(toArtifacts(msg.toolCalls));
    expect(json).not.toContain('AKIAIOSFODNN7EXAMPLE');
    expect(json).toContain('«redacted»');
  });
});
