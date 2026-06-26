import { existsSync, readFileSync } from 'node:fs';
import type { NormalizedToolCall } from '../../engine/types';

// Compute the axis-1 "preview before it lands" for a held tool call. The gate
// sees only a NormalizedToolCall (name + args), so the diff is computed HERE
// (the gate has no diff). For write/edit: current bytes vs proposed content.
// For bash: the command (no content diff possible). The string is rendered
// (colorized) by the UI; this only produces it.

/** Produce a preview string for a pending tool call. */
export function computeDiff(call: NormalizedToolCall): string {
  const { name, args } = call;

  if (name === 'bash') {
    const command = typeof args.command === 'string' ? args.command : JSON.stringify(args);
    return `$ ${command}`;
  }

  if (name === 'write' || name === 'edit') {
    const path = typeof args.path === 'string' ? args.path : '(unknown path)';
    const proposed =
      typeof args.content === 'string' ? args.content : JSON.stringify(args.content ?? '', null, 2);
    let current = '';
    try {
      current = existsSync(path) ? readFileSync(path, 'utf8') : '';
    } catch {
      current = '';
    }
    return renderLineDiff(path, current, proposed);
  }

  // Any other tool: show its args verbatim (still a "preview" the human approves).
  return JSON.stringify(args, null, 2);
}

/**
 * A minimal line-aligned diff (not a full LCS) — enough to preview an edit
 * before it lands. Unchanged lines are prefixed ' ', removed '-', added '+'.
 */
export function renderLineDiff(path: string, oldText: string, newText: string): string {
  const oldLines = oldText.length ? oldText.split('\n') : [];
  const newLines = newText.length ? newText.split('\n') : [];
  const out: string[] = [`--- ${path} (current)`, `+++ ${path} (proposed)`];
  const max = Math.max(oldLines.length, newLines.length);
  for (let i = 0; i < max; i++) {
    const o = oldLines[i];
    const n = newLines[i];
    if (o === n) {
      if (o !== undefined) out.push(` ${o}`);
    } else {
      if (o !== undefined) out.push(`-${o}`);
      if (n !== undefined) out.push(`+${n}`);
    }
  }
  return out.join('\n');
}
