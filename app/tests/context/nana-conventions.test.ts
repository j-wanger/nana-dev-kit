import { describe, it, expect, afterEach } from 'vitest';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { assembleContext, NANA_CONVENTIONS } from '../../src/context/assembly';
import { piLoaderOptions } from '../../src/engine/pi/pi-adapter';

// Phase 119 T6 (A4 safe default) — nana's lean conventions reach the model via the
// CONTEXT seam (NOT a systemPromptOverride, deferred this phase), and AGENTS.md is
// injected EXACTLY ONCE: Pi's native context-file load is OFF (noContextFiles) so
// assembly.ts is the SOLE injector. The .claude/rules injection stays.

const made: string[] = [];
function workspace(): string {
  const ws = mkdtempSync(join(tmpdir(), 'nana-ctx-'));
  made.push(ws);
  return ws;
}
afterEach(() => {
  for (const ws of made.splice(0)) rmSync(ws, { recursive: true, force: true });
});

describe('nana conventions + AGENTS.md de-dup (Ph119 T6, A4)', () => {
  it('leads the context with nana’s lean conventions (conveyed via context, not a system prompt)', () => {
    const ws = workspace();
    writeFileSync(join(ws, 'AGENTS.md'), 'PROJECT: ruff.');
    const a = assembleContext(ws);
    expect(a.systemContext.startsWith(NANA_CONVENTIONS)).toBe(true);
    // The one thing the model most needs to know about THIS harness.
    expect(a.systemContext).toContain('host security gate');
  });

  it('injects AGENTS.md EXACTLY ONCE and keeps the .claude/rules injection', () => {
    const ws = workspace();
    writeFileSync(join(ws, 'AGENTS.md'), 'PROJECT CONVENTIONS X');
    mkdirSync(join(ws, '.claude/rules'), { recursive: true });
    writeFileSync(join(ws, '.claude/rules/active-phase.md'), 'PHASE Y');
    const a = assembleContext(ws);
    // Exactly one AGENTS.md section — Pi's native load is OFF, assembly is the sole injector.
    const count = a.systemContext.split('# Project instructions (AGENTS.md)').length - 1;
    expect(count).toBe(1);
    expect(a.sources.filter((s) => s.path === 'AGENTS.md')).toHaveLength(1);
    // The .claude/rules injection is still present.
    expect(a.systemContext).toContain('PHASE Y');
    expect(a.sources.map((s) => s.path)).toContain('.claude/rules/active-phase.md');
  });

  it('nana conventions still lead when the workspace is project-blind (no files)', () => {
    const ws = workspace();
    const a = assembleContext(ws);
    expect(a.available).toBe(false); // harness-owned conventions do NOT flip `available`
    expect(a.sources).toHaveLength(0);
    expect(a.systemContext).toContain(NANA_CONVENTIONS);
    expect(a.systemContext).toMatch(/project-blind/i); // the loud blind marker is still there
  });

  it('the Pi loader disables the NATIVE context-file load (noContextFiles) — no double injection', () => {
    const opts = piLoaderOptions('/ws', '/agent', []);
    expect(opts.noContextFiles).toBe(true); // regression guard: re-enabling native load double-injects AGENTS.md
    expect(opts.cwd).toBe('/ws');
    expect(opts.agentDir).toBe('/agent');
  });
});
