// Redact key-shaped strings before any model/tool-originated text is written to
// a transcript or log (Phase 108, T2). Fail toward over-redaction: a masked
// non-secret in a log is harmless; a leaked key is not.

const PLACEHOLDER = '«redacted»';

const PATTERNS: readonly RegExp[] = [
  /sk-[A-Za-z0-9_-]{16,}/g, // OpenAI / Anthropic style (covers sk-ant-…)
  /AKIA[0-9A-Z]{16}/g, // AWS access key id
  /gh[pousr]_[A-Za-z0-9]{20,}/g, // GitHub tokens
  /xox[baprs]-[A-Za-z0-9-]{10,}/g, // Slack tokens
  /\b[A-Za-z0-9]{40,}\b/g, // long opaque tokens (catch-all, last)
];

export function redactSecrets(text: string): string {
  let out = text;
  for (const re of PATTERNS) out = out.replace(re, PLACEHOLDER);
  return out;
}
