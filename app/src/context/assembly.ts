import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

// Minimum context-assembly (Phase 109, T2 / ledger A2). The harness must not
// drive a PROJECT-BLIND agent: it assembles the active workspace's
// project-instruction files into the engine's per-turn system context — the
// porting-matrix "context loader -> rebuilt as app code", at a minimum-viable
// level (AGENTS.md/CLAUDE.md + .claude/rules/*.md; NOT dev-wiki/memory-search,
// which is a later, richer pass). LOUD on missing — never silently context-blank
// (mirrors the memory-unavailable discipline).

const RULES_DIR = '.claude/rules';
// AGENTS.md is the cross-tool standard; CLAUDE.md is the synced mirror. Prefer
// one to avoid injecting the same content twice.
const PROJECT_FILES = ['AGENTS.md', 'CLAUDE.md'] as const;

/**
 * Phase 119 T6 (A4 SAFE default) — nana's own LEAN conventions, conveyed to the
 * model through the CONTEXT seam (NOT a systemPromptOverride, which stays deferred
 * this phase). Kept deliberately short: Pi ships a ~1k-token system prompt (vs
 * ~10k for some harnesses) and that leanness is a differentiator — don't bloat it.
 * It states the one thing the model most needs to know about THIS harness: the
 * un-bypassable gate, so it works WITH the gate rather than fighting it.
 */
export const NANA_CONVENTIONS = [
  '# nana dev-harness',
  '',
  'You are running inside the nana dev-harness. A host security gate inspects EVERY tool',
  'call before it runs: destructive or out-of-workspace actions are held for the human’s',
  'explicit approval, and you cannot bypass or disable it. Work WITH it — prefer in-workspace,',
  'reversible edits; read a file before you change it; keep changes surgical. The workspace',
  'root is your free-write zone. When an action genuinely needs to be risky, take it and let',
  'the human approve — don’t contort to avoid the gate.',
].join('\n');

export interface ContextSource {
  /** Path relative to the workspace root. */
  path: string;
  bytes: number;
}

export interface ContextAssembly {
  /** The assembled per-turn system context (or a loud not-found marker). */
  systemContext: string;
  /** Which files contributed, in assembly order. */
  sources: ContextSource[];
  /** false => NO project context was found; the harness is running project-blind. */
  available: boolean;
}

/**
 * Assemble the active workspace's project-instruction context. Pure read; no
 * mutation. Deterministic ordering (project file first, then rules sorted by
 * name). Returns `available: false` with a loud marker when nothing is found.
 */
export function assembleContext(workspaceRoot: string): ContextAssembly {
  const sources: ContextSource[] = [];
  const sections: string[] = [];

  // Project-instruction file: AGENTS.md preferred, CLAUDE.md fallback (first wins).
  for (const name of PROJECT_FILES) {
    const p = join(workspaceRoot, name);
    if (existsSync(p)) {
      const content = readFileSync(p, 'utf8');
      sections.push(`# Project instructions (${name})\n\n${content}`);
      sources.push({ path: name, bytes: Buffer.byteLength(content) });
      break;
    }
  }

  // Always-loaded project rules (.claude/rules/*.md), sorted for determinism.
  const rulesDir = join(workspaceRoot, RULES_DIR);
  if (existsSync(rulesDir)) {
    for (const f of readdirSync(rulesDir).filter((n) => n.endsWith('.md')).sort()) {
      const content = readFileSync(join(rulesDir, f), 'utf8');
      sections.push(`# Rule: ${RULES_DIR}/${f}\n\n${content}`);
      sources.push({ path: `${RULES_DIR}/${f}`, bytes: Buffer.byteLength(content) });
    }
  }

  // Ph119 T6: nana's lean conventions ALWAYS lead the context (harness-owned, not
  // a discovered workspace file — so it is NOT a `source` and does not flip
  // `available`). It is the SOLE path nana's conventions reach the model (A4 safe
  // default; no systemPromptOverride). Pi's native context-file load is OFF
  // (noContextFiles), so AGENTS.md — injected below — reaches the model exactly once.
  const workspaceFound = sources.length > 0;
  const body = workspaceFound
    ? sections.join('\n\n---\n\n')
    : `⚠ No project context found at ${workspaceRoot} ` +
      `(no AGENTS.md / CLAUDE.md and no ${RULES_DIR}/*.md). ` +
      `The harness is running PROJECT-BLIND.`;

  return {
    systemContext: `${NANA_CONVENTIONS}\n\n---\n\n${body}`,
    sources,
    available: workspaceFound,
  };
}
