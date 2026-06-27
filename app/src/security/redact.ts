// Redact key-shaped strings before any model/tool-originated text is written to
// a transcript, log, OR the UI (Phase 108, T2; hardened Phase 110 once REAL tool
// output began reaching the renderer). Fail toward over-redaction — a masked
// non-secret is harmless; a leaked key is not — BUT do NOT mangle the git SHAs /
// hash digests that pervade a coding agent's output (the visibility feature
// exists to SHOW them).

const PLACEHOLDER = '«redacted»';

// High-confidence, specific secret shapes — redacted regardless of context.
const PATTERNS: readonly RegExp[] = [
  /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, // PEM blocks
  /sk-[A-Za-z0-9_-]{16,}/g, // OpenAI / Anthropic (covers sk-ant-…)
  /AKIA[0-9A-Z]{16}/g, // AWS access key id
  /AIza[0-9A-Za-z_-]{35}/g, // Google API key (AIza + 35 → 39 chars)
  /gh[pousr]_[A-Za-z0-9]{20,}/g, // GitHub tokens
  /xox[baprs]-[A-Za-z0-9-]{10,}/g, // Slack tokens
  /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}/g, // JWTs (eyJ… . … . …)
];

// AWS secret access key: a bare 40-char value is indistinguishable from data
// without context, so also redact the value right after the keyword.
const AWS_SECRET = /((?:aws_secret_access_key|aws_secret|secret_access_key)\s*[=:]\s*["']?)([A-Za-z0-9/+]{40})/gi;

// Catch-all for opaque high-entropy / base64 secrets — INCLUDING '/','+','='
// so AWS secret keys and base64 blobs are caught (the old [A-Za-z0-9]{40,}
// missed both) — EXCEPT well-known hash digests, which are benign and common.
const OPAQUE = /[A-Za-z0-9+/]{32,}={0,2}/g;
// md5 (32) / sha1 = git SHA (40) / sha256 (64), lowercase hex — preserve these.
const HASH = /^(?:[0-9a-f]{32}|[0-9a-f]{40}|[0-9a-f]{64})$/;

export function redactSecrets(text: string): string {
  let out = text;
  for (const re of PATTERNS) out = out.replace(re, PLACEHOLDER);
  out = out.replace(AWS_SECRET, (_m, prefix) => `${prefix}${PLACEHOLDER}`);
  out = out.replace(OPAQUE, (m) => (HASH.test(m) ? m : PLACEHOLDER));
  return out;
}
