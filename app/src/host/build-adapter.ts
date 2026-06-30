import { VercelAdapter } from '../engine/vercel/vercel-adapter';
import { PiAdapter, resolveMaxTokens } from '../engine/pi/pi-adapter';
import type { EngineAdapter } from '../engine/adapter';

// Engine selection for the sidecar (extracted from main.ts so it is importable by
// unit tests WITHOUT running main()'s stdin/ready side effects). Defaults to a
// LOCAL OpenAI-compatible backend (no key/billing/ToS — the Ph108 provider pivot).

export function buildAdapter(workspaceRoot: string): EngineAdapter {
  const baseUrl = process.env.NANA_LOCAL_BASE_URL ?? 'http://localhost:8080/v1';
  const modelId = process.env.NANA_MODEL_ID ?? 'local-model';
  // Phase 114: default to Pi — the spec's PRIMARY engine and the one with the rich
  // tool suite (read/grep/find/ls/surgical-edit, paginated + capped). Vercel
  // (bash+write only) was never a chosen default; it stays as the NANA_ENGINE=vercel
  // fallback. The Pi live drive is proven (T1); the gate holds on the Pi path.
  const engine = process.env.NANA_ENGINE ?? 'pi';
  if (engine === 'pi') {
    return new PiAdapter({
      workspaceRoot,
      // Phase 114: thread maxTokens past Pi's local default of 2048 (else real
      // responses truncate); NANA_MAX_TOKENS-overridable.
      local: { providerId: 'local', baseUrl, modelId, contextWindow: 262144, maxTokens: resolveMaxTokens() },
    });
  }
  return new VercelAdapter({ workspaceRoot, baseUrl, modelId });
}
