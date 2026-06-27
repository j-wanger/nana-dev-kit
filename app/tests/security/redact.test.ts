import { describe, it, expect } from 'vitest';
import { redactSecrets } from '../../src/security/redact';

// Ph110 review (security-1 + tests-1). Phase 110 is the first time REAL tool
// output reaches the renderer, so the redaction rail must (a) catch the cloud
// secrets that now flow — incl. AWS secret keys (40 base64 chars w/ '/') and GCP
// 'AIza…' keys the old catch-all missed — AND (b) NOT mangle the git SHAs / hash
// digests pervasive in a coding agent's output, which the old 40-char-alnum
// catch-all over-redacted. Both directions are pinned here.

const RED = '«redacted»';

describe('redactSecrets — secrets that now reach the renderer (under-redaction)', () => {
  it('redacts an AWS secret access key (40 base64 chars containing "/")', () => {
    const out = redactSecrets('aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY');
    expect(out).not.toContain('wJalrXUtnFEMI');
    expect(out).toContain(RED);
  });

  it('redacts a Google API key (AIza…, ~39 chars with "_")', () => {
    const out = redactSecrets('GOOGLE_API_KEY=AIzaSyC1qbk75Ns_Cz5sBoVoY_aGcXexample12');
    expect(out).not.toContain('AIzaSyC1qbk75Ns');
    expect(out).toContain(RED);
  });

  it('redacts a long opaque base64 token / blob', () => {
    const out = redactSecrets('Authorization: Bearer ' + 'a1B2c3D4e5F6g7H8'.repeat(3)); // 48 mixed base64
    expect(out).toContain(RED);
  });

  it('still redacts the previously-handled shapes (sk-, AKIA, GitHub, Slack)', () => {
    expect(redactSecrets('sk-ant-' + 'A'.repeat(40))).toContain(RED);
    expect(redactSecrets('AKIAIOSFODNN7EXAMPLE')).toContain(RED);
    expect(redactSecrets('ghp_' + 'a'.repeat(36))).toContain(RED);
    expect(redactSecrets('xoxb-' + '1'.repeat(20))).toContain(RED);
  });
});

describe('redactSecrets — legit coding-tool output PRESERVED (over-redaction)', () => {
  it('PRESERVES a 40-char git SHA-1', () => {
    const sha = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
    expect(redactSecrets(`commit ${sha} (HEAD -> main)`)).toBe(`commit ${sha} (HEAD -> main)`);
  });

  it('PRESERVES a sha256 digest (64 hex), incl. the sha256: prefix form', () => {
    const d = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    expect(redactSecrets(`sha256:${d}`)).toBe(`sha256:${d}`);
  });

  it('PRESERVES an md5 (32 hex)', () => {
    const m = 'd41d8cd98f00b204e9800998ecf8427e';
    expect(redactSecrets(m)).toBe(m);
  });

  it('PRESERVES ordinary prose / short identifiers', () => {
    const s = 'Running: npm run build && vitest run tests/ui — 142 passed';
    expect(redactSecrets(s)).toBe(s);
  });
});
