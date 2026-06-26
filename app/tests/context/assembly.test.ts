import { describe, it, expect, afterEach } from 'vitest';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { assembleContext } from '../../src/context/assembly';

// T2 / A2: the harness must not drive a project-blind agent. assembleContext
// gathers the active workspace's project-instruction files; loud on missing.

const made: string[] = [];
function workspace(): string {
  const ws = mkdtempSync(join(tmpdir(), 'ctx-'));
  made.push(ws);
  return ws;
}
afterEach(() => {
  for (const ws of made.splice(0)) rmSync(ws, { recursive: true, force: true });
});

describe('context assembly (T2 / A2)', () => {
  it('assembles AGENTS.md + every .claude/rules/*.md into the system context', () => {
    const ws = workspace();
    writeFileSync(join(ws, 'AGENTS.md'), 'PROJECT CONVENTIONS: ruff + mypy.');
    mkdirSync(join(ws, '.claude/rules'), { recursive: true });
    writeFileSync(join(ws, '.claude/rules/active-phase.md'), 'Phase 109: surface.');
    writeFileSync(join(ws, '.claude/rules/working-knowledge.md'), 'KEY FACT 42.');

    const a = assembleContext(ws);
    expect(a.available).toBe(true);
    expect(a.systemContext).toContain('PROJECT CONVENTIONS: ruff + mypy.');
    expect(a.systemContext).toContain('Phase 109: surface.');
    expect(a.systemContext).toContain('KEY FACT 42.');
    expect(a.sources.map((s) => s.path)).toEqual(
      expect.arrayContaining([
        'AGENTS.md',
        '.claude/rules/active-phase.md',
        '.claude/rules/working-knowledge.md',
      ]),
    );
  });

  it('orders rules deterministically (sorted) regardless of fs order', () => {
    const ws = workspace();
    mkdirSync(join(ws, '.claude/rules'), { recursive: true });
    writeFileSync(join(ws, '.claude/rules/zebra.md'), 'Z');
    writeFileSync(join(ws, '.claude/rules/alpha.md'), 'A');
    const a = assembleContext(ws);
    const ruleSources = a.sources.map((s) => s.path).filter((p) => p.startsWith('.claude/rules/'));
    expect(ruleSources).toEqual(['.claude/rules/alpha.md', '.claude/rules/zebra.md']);
  });

  it('prefers AGENTS.md over CLAUDE.md (no duplicate injection)', () => {
    const ws = workspace();
    writeFileSync(join(ws, 'AGENTS.md'), 'AGENTS WINS');
    writeFileSync(join(ws, 'CLAUDE.md'), 'CLAUDE FALLBACK');
    const a = assembleContext(ws);
    expect(a.systemContext).toContain('AGENTS WINS');
    expect(a.systemContext).not.toContain('CLAUDE FALLBACK');
    expect(a.sources.map((s) => s.path)).toContain('AGENTS.md');
    expect(a.sources.map((s) => s.path)).not.toContain('CLAUDE.md');
  });

  it('falls back to CLAUDE.md when AGENTS.md is absent', () => {
    const ws = workspace();
    writeFileSync(join(ws, 'CLAUDE.md'), 'CLAUDE FALLBACK');
    const a = assembleContext(ws);
    expect(a.available).toBe(true);
    expect(a.systemContext).toContain('CLAUDE FALLBACK');
  });

  it('is LOUD on a workspace with no project context (never silently blank)', () => {
    const ws = workspace();
    const a = assembleContext(ws);
    expect(a.available).toBe(false);
    expect(a.sources).toHaveLength(0);
    expect(a.systemContext).toMatch(/no project context|project-blind/i);
    expect(a.systemContext.trim().length).toBeGreaterThan(0); // not silently empty
  });
});
