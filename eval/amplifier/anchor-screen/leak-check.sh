#!/usr/bin/env bash
# leak-check.sh — assert every frozen OFF prompt is free of answer-method vocabulary.
#
# Guards against a contaminated baseline: if an OFF prompt smuggles the very method/cue a harness
# rule would inject (e.g. tells the model to "check for structuring"), the base model looks good for
# the wrong reason → a false DEGENERATE. Deterministic, NO LLM. Exits 0 iff all prompts are clean.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOCAB="$DIR/leak-vocab.txt"
[ -f "$VOCAB" ] || { echo "leak-check: leak-vocab.txt absent" >&2; exit 1; }

rc=0 nprompts=0
for p in "$DIR"/prompts/*.txt; do
  [ -e "$p" ] || { echo "leak-check: no prompts found" >&2; exit 1; }
  nprompts=$((nprompts+1))
  while IFS= read -r term; do
    case "${term:-}" in ''|\#*) continue;; esac
    if grep -iqF -- "$term" "$p"; then
      echo "LEAK: $(basename "$p") contains forbidden answer-cue '$term'" >&2; rc=1
    fi
  done < "$VOCAB"
done
[ "$rc" -eq 0 ] && echo "leak-check: OK ($nprompts prompts clean of $(grep -cvE '^[[:space:]]*(#|$)' "$VOCAB") forbidden terms)"
exit "$rc"
