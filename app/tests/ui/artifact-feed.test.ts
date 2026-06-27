import { describe, it, expect } from 'vitest';
import { toArtifact, toArtifacts } from '../../src/ui/artifact-feed';
import type { SurfaceToolCall } from '../../src/ui/runtime';

// Ph110 T5: tool → typed artifact routing (UI layer, keyed on tool name).

const done = (name: string, output: unknown, id = 'a'): SurfaceToolCall => ({
  id,
  name,
  status: 'done',
  output,
});

describe('artifact routing (Ph110 T5)', () => {
  it('routes an edit/write whose output is a unified diff to a diff artifact', () => {
    const diff = '--- a/x.ts\n+++ b/x.ts\n@@ -1 +1 @@\n-old\n+new';
    expect(toArtifact(done('edit', diff))).toMatchObject({ kind: 'diff', name: 'edit', diff });
    expect(toArtifact(done('write', diff))).toMatchObject({ kind: 'diff' });
  });

  it('routes bash output to a terminal artifact', () => {
    expect(toArtifact(done('bash', 'total 0\nfile.txt'))).toMatchObject({
      kind: 'terminal',
      name: 'bash',
      text: 'total 0\nfile.txt',
    });
  });

  it('falls back to a terminal artifact for an unknown tool or non-diff edit output (A3 generic-text fallback)', () => {
    expect(toArtifact(done('read', 'file contents'))).toMatchObject({ kind: 'terminal' });
    // an edit whose output is a success message, not a diff → terminal, not a fake diff
    expect(toArtifact(done('edit', 'edited 1 file'))).toMatchObject({ kind: 'terminal' });
  });

  it('does NOT mis-route edit/write prose with a leading "- bullet" line to a diff (review artifacts-2)', () => {
    expect(toArtifact(done('edit', 'Applied changes:\n- added foo\n- removed bar'))).toMatchObject({
      kind: 'terminal',
    });
  });

  it('still routes a real unified diff (---/+++/@@ headers) to a diff', () => {
    expect(toArtifact(done('write', '--- a/x\n+++ b/x\n@@ -1 +1 @@\n-a\n+b'))).toMatchObject({ kind: 'diff' });
  });

  it('caps oversized artifact text so the side panel render is bounded (review reduction-3)', () => {
    const huge = 'log line here '.repeat(2000);
    const out = toArtifact(done('bash', huge));
    expect(out?.kind).toBe('terminal');
    expect((out as { text: string }).text.length).toBeLessThan(huge.length);
  });

  it('redacts a key-shaped string in the artifact text', () => {
    const key = `sk-ant-${'B'.repeat(40)}`;
    const art = toArtifact(done('bash', `echo ${key}`));
    expect(JSON.stringify(art)).not.toContain(key);
    expect(JSON.stringify(art)).toContain('«redacted»');
  });

  it('returns null for an in-flight or output-less call (nothing to show yet)', () => {
    expect(toArtifact({ id: 'a', name: 'bash', status: 'called' })).toBeNull();
    expect(toArtifact({ id: 'a', name: 'bash', status: 'done' })).toBeNull();
  });

  it('a denied call produces no artifact (it never ran)', () => {
    expect(
      toArtifact({ id: 'a', name: 'bash', status: 'denied', reason: 'destructive', args: { command: 'rm -rf /' } }),
    ).toBeNull();
  });

  it('toArtifacts derives the live list from a message, dropping non-completed calls', () => {
    const list = toArtifacts([
      done('bash', 'ok', 'a'),
      { id: 'b', name: 'read', status: 'called' },
      done('edit', '--- a\n+++ b\n+x', 'c'),
    ]);
    expect(list.map((a) => a.kind)).toEqual(['terminal', 'diff']);
  });
});

// Ph111 T3 — typed details.diff WINS over the looksLikeDiff heuristic. Pi's real
// EditToolDetails.diff is a line-number-prefixed +/-/space format with NO
// ---/+++/@@ header (live-confirmed in the T1 spike), so the heuristic MISSES it
// — the typed channel is strictly better. The diff is untrusted → redact + cap.
describe('artifact routing — typed details win over the heuristic (Ph111 T3)', () => {
  const withDetails = (name: string, output: unknown, diff: string, id = 'a'): SurfaceToolCall => ({
    id,
    name,
    status: 'done',
    output,
    details: { diff },
  });

  it('routes an edit with typed details.diff to a STRUCTURED diff regardless of output-text shape', () => {
    const diff = '-1 hello world\n+1 goodbye world\n 2 second line'; // Pi's real format
    // output text is a plain success message (NOT diff-shaped) — typed path wins.
    expect(toArtifact(withDetails('edit', 'Edited greeting.txt', diff))).toMatchObject({
      kind: 'diff',
      name: 'edit',
      diff,
    });
  });

  it('the typed path wins on Pi\'s header-less diff that the heuristic would MISS', () => {
    const diff = '-3 foo\n+3 bar';
    // Without details the heuristic misses it (no ---/+++/@@) → terminal …
    expect(toArtifact(done('edit', diff))).toMatchObject({ kind: 'terminal' });
    // … with typed details it is a real diff.
    expect(toArtifact(withDetails('edit', diff, diff))).toMatchObject({ kind: 'diff', diff });
  });

  it('details absent + output IS a unified diff → heuristic still routes diff (Ph110 path preserved)', () => {
    expect(toArtifact(done('edit', '--- a\n+++ b\n@@ -1 +1 @@\n-x\n+y'))).toMatchObject({ kind: 'diff' });
  });

  it('neither typed details nor diff-shaped output → terminal', () => {
    expect(toArtifact(done('bash', 'total 0\nfile.txt'))).toMatchObject({ kind: 'terminal' });
  });

  it('redacts a secret inside the typed diff', () => {
    const secret = 'AKIAIOSFODNN7EXAMPLE';
    const art = toArtifact(withDetails('edit', 'edited', `-1 OLD\n+1 ${secret}`));
    expect(JSON.stringify(art)).not.toContain(secret);
    expect(JSON.stringify(art)).toContain('«redacted»');
  });

  it('caps an oversized typed diff so the panel render is bounded', () => {
    const big = '+building module here\n'.repeat(2000); // ~44KB
    const art = toArtifact(withDetails('edit', 'edited', big));
    expect(art?.kind).toBe('diff');
    expect((art as { diff: string }).diff.length).toBeLessThan(big.length);
  });

  it('an empty details.diff falls back to the heuristic/terminal path (robustness)', () => {
    expect(
      toArtifact({ id: 'a', name: 'edit', status: 'done', output: 'edited 1 file', details: { diff: '' } }),
    ).toMatchObject({ kind: 'terminal' });
  });
});
