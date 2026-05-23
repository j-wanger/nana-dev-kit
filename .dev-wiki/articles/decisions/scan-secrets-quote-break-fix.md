---
title: "scan-secrets.sh POSIX-portable quote matching"
aliases: [scan-secrets-quote-break-fix, bsd-grep-quote-fix]
category: decisions
tags: [hooks, scan-secrets, bsd-grep, portability]
parents: [phase-22-session-start-refactor]
created: 2026-05-22
updated: 2026-05-22
source: debrief
confidence: high
---

## Context

scan-secrets.sh used `\x27` in a grep -E pattern to match single quotes in scanned files. GNU grep interprets `\x27` as a hex escape for `'`, but macOS BSD grep does not support hex escapes in ERE mode. This meant single-quoted secrets (e.g., `password='hunter2'`) went undetected on macOS.

## Decision

Replace `\x27` with the POSIX-portable quote-break pattern `'"'"'` (end single-quoted string, insert double-quoted single quote, resume single-quoted string). This works on both GNU grep and BSD grep.

Alternative considered: ANSI-C quoting `$'\x27'`. Rejected because it is a bash-ism and not POSIX sh compatible. The hook scripts target `/bin/bash` but the pattern should remain portable.

The eval fixture for `hook-scan-secrets-pattern` was updated atomically with the fix to prevent an eval regression window.

## Consequences

- scan-secrets.sh now detects single-quoted secrets on macOS
- Pattern is harder to read but universally portable
- Eval fixture updated to use single quotes, validating the fix directly
