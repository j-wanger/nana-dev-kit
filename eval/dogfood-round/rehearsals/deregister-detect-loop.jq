# Phase 89 T4: remove every hook registration whose command references detect-loop.sh
# (cut in Phase 88, 75b48af) from a Claude Code settings file. Handles nested
# ({matcher, hooks:[{type,command}]}) and flat ({matcher, command}) forms; drops
# emptied wrappers and emptied event arrays. Applied to edge-screener's
# settings.local.json at the T4 checkpoint-gated re-sync; rehearsed on a copy first.
.hooks |= with_entries(
  .value |= map(
    (if has("hooks")
     then .hooks |= map(select(.command | contains("detect-loop.sh") | not))
     else . end)
    | select(
        if has("hooks")
        then (.hooks | length) > 0
        else ((.command // "") | contains("detect-loop.sh") | not)
        end
      )
  )
)
| .hooks |= with_entries(select((.value | length) > 0))
